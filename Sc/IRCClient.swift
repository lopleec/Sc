import Foundation
import Network

final class IRCClient: @unchecked Sendable {
    struct Configuration {
        var server: ServerConfiguration
        var nickname: String
        var session: SessionDescriptor
        var shouldConfigureChannelModes: Bool
    }

    enum Event {
        case state(ConnectionState)
        case joined
        case message(sender: String, text: String)
        case channelKeyAccepted(String)
        case system(String)
        case failure(String)
        case disconnected(String)
    }

    private struct IRCLine {
        var prefix: String?
        var command: String
        var parameters: [String]
    }

    private let configuration: Configuration
    private let onEvent: (Event) -> Void
    private let queue = DispatchQueue(label: "Sc.IRCClient")
    private var connection: NWConnection?
    private var buffer = ""
    private var hasSentJoin = false
    private var hasJoined = false
    private var isShuttingDown = false
    private var hasConfiguredChannelModes = false

    init(configuration: Configuration, onEvent: @escaping (Event) -> Void) {
        self.configuration = configuration
        self.onEvent = onEvent
    }

    func connect() {
        queue.async { [weak self] in
            self?.connectOnQueue()
        }
    }

    func disconnect(reason: String) {
        queue.async { [weak self] in
            self?.disconnectOnQueue(reason: reason)
        }
    }

    func sendMessage(_ text: String) {
        queue.async { [weak self] in
            guard let self, self.hasJoined else { return }
            self.sendRaw("PRIVMSG \(self.configuration.session.channel) :\(text)")
        }
    }

    private func connectOnQueue() {
        isShuttingDown = false
        buffer = ""
        hasSentJoin = false
        hasJoined = false
        hasConfiguredChannelModes = false

        let port = NWEndpoint.Port(integerLiteral: UInt16(configuration.server.port))
        let parameters = NWParameters.tcp
        if configuration.server.useTLS {
            parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolTLS.Options(), at: 0)
        }

        let connection = NWConnection(host: .init(configuration.server.host), port: port, using: parameters)
        self.connection = connection

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .setup:
                self.onEvent(.state(.connecting(L10n.string("irc.preparing"))))
            case .waiting:
                self.onEvent(.state(.connecting(L10n.string("irc.waiting"))))
            case .ready:
                self.onEvent(.state(.connecting(L10n.format("irc.registering", self.configuration.server.summary))))
                self.sendRaw("NICK \(self.configuration.nickname)")
                self.sendRaw("USER \(self.configuration.nickname) 0 * :Sc \(self.configuration.nickname)")
                self.receiveNextChunk()
            case let .failed(error):
                self.onEvent(.failure(Self.describe(error)))
            case .cancelled:
                if self.isShuttingDown {
                    self.onEvent(.disconnected(L10n.string("irc.disconnected")))
                }
            default:
                break
            }
        }

        connection.start(queue: queue)
    }

    private func disconnectOnQueue(reason: String) {
        isShuttingDown = true
        if hasJoined {
            sendRaw("PART \(configuration.session.channel) :\(reason)")
        }
        sendRaw("QUIT :\(reason)")
        connection?.cancel()
        connection = nil
        hasJoined = false
    }

    private func receiveNextChunk() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let data, let string = String(data: data, encoding: .utf8), !string.isEmpty {
                self.buffer += string
                self.consumeBufferedLines()
            }

            if let error {
                self.onEvent(.failure(Self.describe(error)))
                return
            }

            if isComplete {
                self.onEvent(.disconnected(L10n.string("irc.server_closed")))
                return
            }

            self.receiveNextChunk()
        }
    }

    private func consumeBufferedLines() {
        while let range = buffer.range(of: "\r\n") {
            let line = String(buffer[..<range.lowerBound])
            buffer.removeSubrange(..<range.upperBound)
            handle(line: line)
        }
    }

    private func handle(line: String) {
        if line.hasPrefix("PING ") {
            let token = line.dropFirst(5)
            sendRaw("PONG \(token)")
            return
        }

        guard let message = Self.parse(line: line) else { return }

        switch message.command.uppercased() {
        case "001":
            onEvent(.state(.joining(L10n.format("status.joining", configuration.session.channel))))
            sendJoinIfNeeded()
        case "376", "422":
            sendJoinIfNeeded()
        case "JOIN":
            let nickname = Self.nickname(from: message.prefix)
            if nickname.caseInsensitiveCompare(configuration.nickname) == .orderedSame {
                hasJoined = true
                configureChannelModesIfNeeded()
                onEvent(.joined)
            } else {
                onEvent(.system(L10n.format("irc.user_joined", nickname, configuration.session.channel)))
            }
        case "PART":
            let nickname = Self.nickname(from: message.prefix)
            if nickname.caseInsensitiveCompare(configuration.nickname) != .orderedSame {
                onEvent(.system(L10n.format("irc.user_left", nickname)))
            }
        case "QUIT":
            let nickname = Self.nickname(from: message.prefix)
            if nickname.caseInsensitiveCompare(configuration.nickname) != .orderedSame {
                onEvent(.system(L10n.format("irc.user_quit", nickname)))
            }
        case "PRIVMSG":
            guard message.parameters.count >= 2 else { return }
            let target = message.parameters[0]
            let text = message.parameters[1]
            guard target.caseInsensitiveCompare(configuration.session.channel) == .orderedSame else { return }

            let sender = Self.nickname(from: message.prefix)
            if sender.caseInsensitiveCompare(configuration.nickname) != .orderedSame {
                onEvent(.message(sender: sender, text: text))
            }
        case "MODE":
            if let appliedKey = Self.acceptedChannelKey(for: configuration.session.channel, parameters: message.parameters) {
                onEvent(.channelKeyAccepted(appliedKey))
            }
        case "433":
            onEvent(.failure(L10n.string("irc.nickname_in_use")))
        case "475":
            onEvent(.failure(L10n.string("irc.password_rejected")))
        case "471":
            onEvent(.failure(L10n.string("irc.channel_full")))
        case "473":
            onEvent(.failure(L10n.string("irc.channel_invite_only")))
        case "474":
            onEvent(.failure(L10n.string("irc.channel_banned")))
        case "476":
            onEvent(.failure(L10n.string("irc.channel_invalid")))
        case "NOTICE":
            if message.parameters.count >= 2 {
                onEvent(.system(message.parameters[1]))
            }
        case "ERROR":
            if let detail = message.parameters.last {
                onEvent(.failure(detail))
            }
        default:
            break
        }
    }

    private func sendJoinIfNeeded() {
        guard !hasSentJoin else { return }
        hasSentJoin = true
        sendRaw("JOIN \(configuration.session.channel) \(configuration.session.password)")
    }

    private func configureChannelModesIfNeeded() {
        guard configuration.shouldConfigureChannelModes, !hasConfiguredChannelModes else { return }
        hasConfiguredChannelModes = true
        for command in Self.channelModeCommands(channel: configuration.session.channel, password: configuration.session.password) {
            sendRaw(command)
        }
    }

    private func sendRaw(_ line: String) {
        guard let data = "\(line)\r\n".data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            guard let self, let error else { return }
            self.onEvent(.failure(Self.describe(error)))
        })
    }

    private static func parse(line: String) -> IRCLine? {
        guard !line.isEmpty else { return nil }

        var remainder = line[...]
        var prefix: String?

        if remainder.first == ":" {
            remainder.removeFirst()
            guard let spaceIndex = remainder.firstIndex(of: " ") else { return nil }
            prefix = String(remainder[..<spaceIndex])
            remainder = remainder[remainder.index(after: spaceIndex)...]
        }

        while remainder.first == " " {
            remainder.removeFirst()
        }

        guard !remainder.isEmpty else { return nil }

        let command: String
        if let spaceIndex = remainder.firstIndex(of: " ") {
            command = String(remainder[..<spaceIndex])
            remainder = remainder[remainder.index(after: spaceIndex)...]
        } else {
            command = String(remainder)
            remainder = "".suffix(0)
        }

        var parameters: [String] = []
        while !remainder.isEmpty {
            while remainder.first == " " {
                remainder.removeFirst()
            }

            guard !remainder.isEmpty else { break }
            if remainder.first == ":" {
                parameters.append(String(remainder.dropFirst()))
                break
            }

            if let spaceIndex = remainder.firstIndex(of: " ") {
                parameters.append(String(remainder[..<spaceIndex]))
                remainder = remainder[remainder.index(after: spaceIndex)...]
            } else {
                parameters.append(String(remainder))
                break
            }
        }

        return IRCLine(prefix: prefix, command: command, parameters: parameters)
    }

    private static func nickname(from prefix: String?) -> String {
        guard let prefix else { return L10n.string("common.unknown") }
        if let bangIndex = prefix.firstIndex(of: "!") {
            return String(prefix[..<bangIndex])
        }
        return prefix
    }

    static func channelModeCommands(channel: String, password: String) -> [String] {
        [
            "MODE \(channel) +s",
            "MODE \(channel) +k \(password)",
        ]
    }

    static func acceptedChannelKey(for channel: String, parameters: [String]) -> String? {
        guard parameters.count >= 3 else { return nil }
        guard parameters[0].caseInsensitiveCompare(channel) == .orderedSame else { return nil }

        let modes = parameters[1]
        var modeIsAdding = true
        var parameterIndex = 2

        for character in modes {
            switch character {
            case "+":
                modeIsAdding = true
            case "-":
                modeIsAdding = false
            case "k":
                guard parameterIndex < parameters.count else { return nil }
                let key = parameters[parameterIndex]
                parameterIndex += 1
                if modeIsAdding, key != "*" {
                    return key
                }
            case "l":
                if modeIsAdding, parameterIndex < parameters.count {
                    parameterIndex += 1
                }
            default:
                break
            }
        }

        return nil
    }

    private static func describe(_ error: Error) -> String {
        if let networkError = error as? NWError {
            return networkError.debugDescription
        }
        return error.localizedDescription
    }
}
