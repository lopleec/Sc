import AppKit
import Carbon
import Foundation
import SwiftUI

enum ServerPreset: String, CaseIterable, Codable, Identifiable {
    case libera
    case rizon
    case oftc
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .libera:
            L10n.string("server.preset.libera")
        case .rizon:
            L10n.string("server.preset.rizon")
        case .oftc:
            L10n.string("server.preset.oftc")
        case .custom:
            L10n.string("server.preset.custom")
        }
    }

    var defaultConfiguration: ServerConfiguration? {
        switch self {
        case .libera:
            ServerConfiguration(host: "irc.libera.chat", port: 6697, useTLS: true)
        case .rizon:
            ServerConfiguration(host: "irc.rizon.net", port: 6697, useTLS: true)
        case .oftc:
            ServerConfiguration(host: "irc.oftc.net", port: 6697, useTLS: true)
        case .custom:
            nil
        }
    }
}

struct ServerConfiguration: Codable, Equatable {
    var host: String
    var port: Int
    var useTLS: Bool

    var summary: String {
        L10n.format(
            "server.summary",
            host,
            port,
            L10n.string(useTLS ? "server.mode.tls" : "server.mode.plain")
        )
    }

    func sanitized() -> ServerConfiguration {
        ServerConfiguration(
            host: host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: (1...65535).contains(port) ? port : 6697,
            useTLS: useTLS
        )
    }
}

struct SessionDescriptor: Codable, Equatable {
    static let channelPrefix = "#sc-"
    static let passwordLength = 16

    var server: ServerConfiguration
    var channel: String
    var password: String

    static func random(server: ServerConfiguration) -> SessionDescriptor {
        SessionDescriptor(
            server: server,
            channel: "\(channelPrefix)\(RandomToken.generate(length: 18).lowercased())",
            password: RandomToken.generate(length: passwordLength, from: RandomToken.lowercaseAlphaNumericAlphabet)
        )
    }
}

struct AppearanceSettings: Codable, Equatable {
    var overlayOpacity: Double = 0.72
    var fontSize: Double = 17
    var overlayWidth: Double = 420
    var edgePadding: Double = 18
    var bottomPadding: Double = 26
    var messageLimit: Int = 6
    var messageLineLimit: Int = 2
    var previewDuration: Double = 6
    var showIncomingPreview: Bool = true
    var showTimestamps: Bool = false

    private enum CodingKeys: String, CodingKey {
        case overlayOpacity
        case fontSize
        case overlayWidth
        case edgePadding
        case bottomPadding
        case messageLimit
        case messageLineLimit
        case previewDuration
        case showIncomingPreview
        case showTimestamps
    }

    init(
        overlayOpacity: Double = 0.72,
        fontSize: Double = 17,
        overlayWidth: Double = 420,
        edgePadding: Double = 18,
        bottomPadding: Double = 26,
        messageLimit: Int = 6,
        messageLineLimit: Int = 2,
        previewDuration: Double = 6,
        showIncomingPreview: Bool = true,
        showTimestamps: Bool = false
    ) {
        self.overlayOpacity = overlayOpacity
        self.fontSize = fontSize
        self.overlayWidth = overlayWidth
        self.edgePadding = edgePadding
        self.bottomPadding = bottomPadding
        self.messageLimit = messageLimit
        self.messageLineLimit = messageLineLimit
        self.previewDuration = previewDuration
        self.showIncomingPreview = showIncomingPreview
        self.showTimestamps = showTimestamps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overlayOpacity = try container.decodeIfPresent(Double.self, forKey: .overlayOpacity) ?? 0.72
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? 17
        overlayWidth = try container.decodeIfPresent(Double.self, forKey: .overlayWidth) ?? 420
        edgePadding = try container.decodeIfPresent(Double.self, forKey: .edgePadding) ?? 18
        bottomPadding = try container.decodeIfPresent(Double.self, forKey: .bottomPadding) ?? 26
        messageLimit = try container.decodeIfPresent(Int.self, forKey: .messageLimit) ?? 6
        messageLineLimit = try container.decodeIfPresent(Int.self, forKey: .messageLineLimit) ?? 2
        previewDuration = try container.decodeIfPresent(Double.self, forKey: .previewDuration) ?? 6
        showIncomingPreview = try container.decodeIfPresent(Bool.self, forKey: .showIncomingPreview) ?? true
        showTimestamps = try container.decodeIfPresent(Bool.self, forKey: .showTimestamps) ?? false
    }

    func clamped() -> AppearanceSettings {
        AppearanceSettings(
            overlayOpacity: min(max(overlayOpacity, 0.35), 0.95),
            fontSize: min(max(fontSize, 13), 28),
            overlayWidth: min(max(overlayWidth, 320), 620),
            edgePadding: min(max(edgePadding, 0), 60),
            bottomPadding: min(max(bottomPadding, 0), 80),
            messageLimit: min(max(messageLimit, 3), 20),
            messageLineLimit: min(max(messageLineLimit, 0), 6),
            previewDuration: min(max(previewDuration, 0), 15),
            showIncomingPreview: showIncomingPreview,
            showTimestamps: showTimestamps
        )
    }

    var overlayHeight: CGFloat {
        let safe = clamped()
        return CGFloat((Double(safe.messageLimit) * (safe.fontSize + 8)) + safe.fontSize + 70)
    }
}

struct AppSettings: Codable, Equatable {
    var nickname: String = AutoNickname.generate()
    var appLanguage: AppLanguage = .system
    var selectedServerPreset: ServerPreset = .libera
    var customServer: ServerConfiguration = .init(host: "irc.example.net", port: 6697, useTLS: true)
    var appearance: AppearanceSettings = .init()

    private enum CodingKeys: String, CodingKey {
        case nickname
        case appLanguage
        case selectedServerPreset
        case customServer
        case appearance
    }

    init(
        nickname: String = AutoNickname.generate(),
        appLanguage: AppLanguage = .system,
        selectedServerPreset: ServerPreset = .libera,
        customServer: ServerConfiguration = .init(host: "irc.example.net", port: 6697, useTLS: true),
        appearance: AppearanceSettings = .init()
    ) {
        self.nickname = nickname
        self.appLanguage = appLanguage
        self.selectedServerPreset = selectedServerPreset
        self.customServer = customServer
        self.appearance = appearance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? AutoNickname.generate()
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? .system
        selectedServerPreset = try container.decodeIfPresent(ServerPreset.self, forKey: .selectedServerPreset) ?? .libera
        customServer = try container.decodeIfPresent(ServerConfiguration.self, forKey: .customServer) ?? .init(host: "irc.example.net", port: 6697, useTLS: true)
        appearance = try container.decodeIfPresent(AppearanceSettings.self, forKey: .appearance) ?? .init()
    }

    var normalizedNickname: String {
        NicknameRules.normalized(nickname)
    }

    func resolvedServerConfiguration() -> ServerConfiguration {
        switch selectedServerPreset {
        case .custom:
            customServer.sanitized()
        case .libera, .rizon, .oftc:
            selectedServerPreset.defaultConfiguration ?? customServer.sanitized()
        }
    }

    func sanitized() -> AppSettings {
        AppSettings(
            nickname: NicknameRules.sanitizeInput(nickname),
            appLanguage: appLanguage,
            selectedServerPreset: selectedServerPreset,
            customServer: customServer.sanitized(),
            appearance: appearance.clamped()
        )
    }
}

struct ChatMessage: Identifiable, Equatable {
    enum Kind: String {
        case chat
        case system
    }

    let id = UUID()
    let sender: String?
    let text: String
    let timestamp: Date
    let kind: Kind
    let isOwnMessage: Bool

    static func system(_ text: String) -> ChatMessage {
        ChatMessage(sender: nil, text: text, timestamp: .now, kind: .system, isOwnMessage: false)
    }
}

enum ConnectionState: Equatable {
    case idle
    case connecting(String)
    case joining(String)
    case connected(String)
    case failed(String)
    case disconnected(String)

    var label: String {
        switch self {
        case .idle:
            L10n.string("status.ready")
        case let .connecting(detail),
             let .joining(detail),
             let .connected(detail),
             let .failed(detail),
             let .disconnected(detail):
            detail
        }
    }

    var tone: Color {
        switch self {
        case .idle:
            .secondary
        case .connecting, .joining:
            Color.yellow
        case .connected:
            Color.green
        case .failed:
            Color.red
        case .disconnected:
            Color.orange
        }
    }

    var isBusy: Bool {
        switch self {
        case .connecting, .joining:
            true
        case .idle, .connected, .failed, .disconnected:
            false
        }
    }
}

enum HotKeyCaptureStatus: Equatable {
    case standard
    case enhanced
    case permissionRequired
    case unavailable

    var label: String {
        switch self {
        case .standard:
            L10n.string("overview.hotkey_capture.standard")
        case .enhanced:
            L10n.string("overview.hotkey_capture.enhanced")
        case .permissionRequired:
            L10n.string("overview.hotkey_capture.permission")
        case .unavailable:
            L10n.string("overview.hotkey_capture.unavailable")
        }
    }

    var tone: Color {
        switch self {
        case .standard:
            .secondary
        case .enhanced:
            .green
        case .permissionRequired:
            .orange
        case .unavailable:
            .red
        }
    }

    var iconName: String {
        switch self {
        case .standard:
            "keyboard"
        case .enhanced:
            "display.and.arrow.down"
        case .permissionRequired:
            "hand.raised.fill"
        case .unavailable:
            "exclamationmark.triangle.fill"
        }
    }

    var note: String {
        switch self {
        case .standard:
            L10n.string("overview.hotkey_note.standard")
        case .enhanced:
            L10n.string("overview.hotkey_note.enhanced")
        case .permissionRequired:
            L10n.string("overview.hotkey_note.permission")
        case .unavailable:
            L10n.string("overview.hotkey_note.unavailable")
        }
    }
}

enum InviteCodeError: LocalizedError {
    case invalidPrefix
    case invalidPayload
    case invalidChannel
    case invalidServer

    var errorDescription: String? {
        switch self {
        case .invalidPrefix:
            L10n.string("error.invite.invalid_prefix")
        case .invalidPayload:
            L10n.string("error.invite.invalid_payload")
        case .invalidChannel:
            L10n.string("error.invite.invalid_channel")
        case .invalidServer:
            L10n.string("error.invite.invalid_server")
        }
    }
}

private struct InvitePayload: Codable, Equatable {
    var server: String
    var port: Int
    var tls: Bool
    var channel: String
    var password: String
}

enum InviteCodeCodec {
    private static let prefix = "SC1:"

    static func encode(_ session: SessionDescriptor) throws -> String {
        let payload = InvitePayload(
            server: session.server.host,
            port: session.server.port,
            tls: session.server.useTLS,
            channel: session.channel,
            password: session.password
        )
        let data = try JSONEncoder().encode(payload)
        return prefix + Base64URL.encode(data)
    }

    static func decode(_ rawCode: String) throws -> SessionDescriptor {
        let trimmed = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else {
            throw InviteCodeError.invalidPrefix
        }

        let encodedPayload = String(trimmed.dropFirst(prefix.count))
        guard let payloadData = Base64URL.decode(encodedPayload),
              let payload = try? JSONDecoder().decode(InvitePayload.self, from: payloadData)
        else {
            throw InviteCodeError.invalidPayload
        }

        let server = payload.server.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !server.isEmpty else {
            throw InviteCodeError.invalidServer
        }

        let channel = payload.channel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard channel.hasPrefix("#"), channel.count > 4 else {
            throw InviteCodeError.invalidChannel
        }

        return SessionDescriptor(
            server: ServerConfiguration(host: server, port: payload.port, useTLS: payload.tls).sanitized(),
            channel: channel,
            password: payload.password
        )
    }
}

enum SettingsStore {
    private static let key = "Sc.AppSettings"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return AppSettings().sanitized()
        }

        return decoded.sanitized()
    }

    static func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }

        UserDefaults.standard.set(data, forKey: key)
    }
}

enum AutoNickname {
    static let fallbackName = "Player"

    static func generate() -> String {
        let prefixes = ["Bright", "Quartz", "Solar", "Pixel", "Echo", "Nova", "Rune", "Glow"]
        let suffixes = ["Fox", "Wolf", "Mage", "Crafter", "Pilot", "Seeker", "Spark", "Knight"]
        let prefix = prefixes.randomElement() ?? "Pixel"
        let suffix = suffixes.randomElement() ?? "Crafter"
        return "\(prefix)\(suffix)\(Int.random(in: 10...99))"
    }
}

enum NicknameRules {
    private static let maxLength = 24
    private static let allowedScalars = CharacterSet.alphanumerics

    static func sanitizeInput(_ raw: String) -> String {
        let filtered = raw.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.filter {
            $0.isASCII && allowedScalars.contains($0)
        }

        return String(String.UnicodeScalarView(filtered).prefix(maxLength))
    }

    static func normalized(_ raw: String) -> String {
        let sanitized = sanitizeInput(raw)
        return sanitized.isEmpty ? AutoNickname.fallbackName : sanitized
    }
}

enum RandomToken {
    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    static let lowercaseAlphaNumericAlphabet = Array("abcdefghijklmnopqrstuvwxyz0123456789")

    static func generate(length: Int) -> String {
        generate(length: length, from: alphabet)
    }

    static func generate(length: Int, from alphabet: [Character]) -> String {
        String((0..<length).map { _ in alphabet.randomElement() ?? "x" })
    }
}

enum Base64URL {
    static func encode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decode(_ string: String) -> Data? {
        var padded = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = padded.count % 4
        if remainder != 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: padded)
    }
}

enum NicknameColorPalette {
    static func color(for nickname: String, sessionKey: String) -> Color {
        let hash = stableHash("\(sessionKey)|\(nickname.lowercased())")
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.88, brightness: 0.98)
    }

    static func stableHash(_ string: String) -> UInt64 {
        let prime: UInt64 = 1_099_511_628_211
        var hash: UInt64 = 14_695_981_039_346_656_037

        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }

        return hash
    }
}

@MainActor
final class AppModel: ObservableObject {
    private enum OverlayPresentationMode {
        case hidden
        case manual
        case preview
    }

    private struct PendingSessionStart {
        let session: SessionDescriptor
        let inviteCode: String
        let banner: String
        let createdByThisClient: Bool
    }

    static let shared = AppModel()

    @Published var settings: AppSettings {
        didSet { persistSettingsIfNeeded() }
    }
    @Published var connectionState: ConnectionState = .idle
    @Published var currentSession: SessionDescriptor?
    @Published var currentInviteCode = ""
    @Published var joinCodeInput = ""
    @Published var messages: [ChatMessage] = []
    @Published var composerText = ""
    @Published var overlayVisible = false
    @Published var overlayFocusToken = UUID()
    @Published private(set) var overlayWantsKeyboardFocus = false
    @Published var bannerText: String?
    @Published private(set) var hotKeyCaptureStatus: HotKeyCaptureStatus = .standard

    private var overlayController: OverlayPanelController?
    private var hotKeyController: HotKeyController?
    private var eventTapHotKeyController: EventTapHotKeyController?
    private var ircClient: IRCClient?
    private var connectionToken = UUID()
    private var isNormalizingSettings = false
    private var currentSessionIsCreator = false
    private var overlayPresentationMode: OverlayPresentationMode = .hidden
    private var previewHideTask: Task<Void, Never>?
    private var invitePublicationTask: Task<Void, Never>?
    private var pendingSessionStart: PendingSessionStart?
    private var lastHotKeyTriggerUptime: TimeInterval = 0

    private init(settings: AppSettings = SettingsStore.load()) {
        self.settings = settings.sanitized()
        L10n.setAppLanguage(self.settings.appLanguage)
    }

    var displayedMessages: [ChatMessage] {
        Array(messages.suffix(settings.appearance.clamped().messageLimit))
    }

    var hasActiveSession: Bool {
        currentSession != nil && ircClient != nil
    }

    var nicknamePreviewColor: Color {
        NicknameColorPalette.color(for: settings.normalizedNickname, sessionKey: currentSession?.channel ?? "preview")
    }

    var appLocale: Locale {
        settings.appLanguage.locale
    }

    var shouldShowFullScreenHotKeyPermissionButton: Bool {
        hotKeyCaptureStatus == .permissionRequired
    }

    func installSystemServices() {
        if overlayController == nil {
            overlayController = OverlayPanelController(appModel: self)
        }

        if hotKeyController == nil {
            hotKeyController = HotKeyController(keyCode: UInt32(kVK_ANSI_Slash), modifiers: UInt32(cmdKey)) { [weak self] in
                DispatchQueue.main.async {
                    self?.handleGlobalHotKeyTrigger()
                }
            }
        }

        if eventTapHotKeyController == nil {
            eventTapHotKeyController = EventTapHotKeyController(
                keyCode: CGKeyCode(kVK_ANSI_Slash),
                requiredModifiers: [.maskCommand]
            ) { [weak self] in
                DispatchQueue.main.async {
                    self?.handleGlobalHotKeyTrigger()
                }
            } statusHandler: { [weak self] status in
                DispatchQueue.main.async {
                    self?.apply(eventTapStatus: status)
                }
            }
        }

        hotKeyController?.register()
        eventTapHotKeyController?.refresh()
        overlayController?.updateFrame(with: settings.appearance)
    }

    func refreshHotKeyMonitoring() {
        eventTapHotKeyController?.refresh()
    }

    func requestFullScreenHotKeyPermission() {
        eventTapHotKeyController?.requestPermission()
        presentBanner(L10n.string("banner.input_monitoring_requested"))
    }

    func shutdown() {
        connectionToken = UUID()
        ircClient?.disconnect(reason: L10n.string("app.title"))
        ircClient = nil
        cancelPreviewAutoHide()
        cancelInvitePublication()
        hideOverlay()
        hotKeyController?.unregister()
        hotKeyController = nil
        eventTapHotKeyController?.stop()
        eventTapHotKeyController = nil
        overlayController?.close()
        overlayController = nil
    }

    func createSession() {
        do {
            let server = try validatedResolvedServer()
            let session = SessionDescriptor.random(server: server)
            let inviteCode = try InviteCodeCodec.encode(session)
            startSession(
                session,
                inviteCode: inviteCode,
                banner: L10n.format("banner.created", session.channel, server.summary),
                createdByThisClient: true
            )
        } catch {
            presentBanner(error.localizedDescription)
        }
    }

    func joinSessionFromInvite() {
        do {
            let session = try InviteCodeCodec.decode(joinCodeInput)
            try _ = validated(server: session.server)
            startSession(
                session,
                inviteCode: joinCodeInput.trimmingCharacters(in: .whitespacesAndNewlines),
                banner: L10n.format("banner.joining", session.channel),
                createdByThisClient: false
            )
        } catch {
            presentBanner(error.localizedDescription)
        }
    }

    func leaveCurrentSession() {
        pendingSessionStart = nil
        connectionToken = UUID()
        ircClient?.disconnect(reason: L10n.string("action.stop_session"))
        ircClient = nil
        cancelInvitePublication()
        currentSession = nil
        currentInviteCode = ""
        messages.removeAll()
        composerText = ""
        connectionState = .idle
        currentSessionIsCreator = false
        hideOverlay()
        presentBanner(L10n.string("banner.session_stopped"))
    }

    func copyCurrentInviteCode() {
        guard !currentInviteCode.isEmpty else {
            presentBanner(L10n.string("banner.no_invite_to_copy"))
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentInviteCode, forType: .string)
        presentBanner(L10n.string("banner.invite_copied"))
    }

    func sendCurrentMessage() {
        let trimmed = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let session = currentSession, let ircClient else {
            presentBanner(L10n.string("banner.create_or_join_first"))
            return
        }

        composerText = ""
        messages.append(ChatMessage(sender: settings.normalizedNickname, text: trimmed, timestamp: .now, kind: .chat, isOwnMessage: true))
        ircClient.sendMessage(trimmed)
        connectionState = .connected(L10n.format("status.connected", session.channel))
    }

    func toggleOverlayFromHotKey() {
        guard hasActiveSession else {
            NSSound.beep()
            presentBanner(L10n.string("banner.create_or_join_before_overlay"))
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        switch overlayPresentationMode {
        case .manual:
            hideOverlay()
        case .hidden, .preview:
            showOverlayForManualEntry()
        }
    }

    func hideOverlay() {
        cancelPreviewAutoHide()
        overlayPresentationMode = .hidden
        overlayVisible = false
        overlayWantsKeyboardFocus = false
        overlayController?.hide()
    }

    func color(for nickname: String) -> Color {
        NicknameColorPalette.color(for: nickname, sessionKey: currentSession?.channel ?? "preview")
    }

    private func startSession(_ session: SessionDescriptor, inviteCode: String, banner: String, createdByThisClient: Bool) {
        let request = PendingSessionStart(
            session: session,
            inviteCode: inviteCode,
            banner: banner,
            createdByThisClient: createdByThisClient
        )

        guard ircClient == nil else {
            pendingSessionStart = request
            hideOverlay()
            ircClient?.disconnect(reason: L10n.string("action.stop_session"))
            return
        }

        performSessionStart(request)
    }

    private func performSessionStart(_ request: PendingSessionStart) {
        connectionToken = UUID()
        ircClient = nil
        cancelInvitePublication()

        let token = UUID()
        connectionToken = token
        currentSession = request.session
        currentInviteCode = request.createdByThisClient ? "" : request.inviteCode
        currentSessionIsCreator = request.createdByThisClient
        messages = [ChatMessage.system(request.banner)]
        composerText = ""
        hideOverlay()
        connectionState = .connecting(L10n.format("status.connecting", request.session.server.summary))

        let configuration = IRCClient.Configuration(
            server: request.session.server,
            nickname: settings.normalizedNickname,
            session: request.session,
            shouldConfigureChannelModes: currentSessionIsCreator
        )

        let client = IRCClient(configuration: configuration) { [weak self] event in
            DispatchQueue.main.async {
                self?.handle(event: event, token: token)
            }
        }

        ircClient = client
        client.connect()
    }

    private func handle(event: IRCClient.Event, token: UUID) {
        guard token == connectionToken else { return }

        switch event {
        case let .state(state):
            connectionState = state
        case .joined:
            if let currentSession {
                if currentSessionIsCreator {
                    scheduleInvitePublicationFallback()
                }
                connectionState = .connected(L10n.format("status.connected", currentSession.channel))
                messages.append(.system(L10n.format("banner.joined_chat_hint", currentSession.channel)))
            }
        case let .message(sender, text):
            messages.append(ChatMessage(sender: sender, text: text, timestamp: .now, kind: .chat, isOwnMessage: false))
            showPreviewOverlayForIncomingMessage()
        case let .channelKeyAccepted(appliedPassword):
            guard currentSessionIsCreator, var currentSession else { return }
            currentSession.password = appliedPassword
            self.currentSession = currentSession
            publishInvite(for: currentSession)
        case let .system(text):
            messages.append(.system(text))
        case let .failure(reason):
            if continuePendingSessionStartIfNeeded() {
                return
            }
            connectionToken = UUID()
            ircClient = nil
            cancelInvitePublication()
            currentSession = nil
            currentInviteCode = ""
            currentSessionIsCreator = false
            hideOverlay()
            connectionState = .failed(reason)
            messages.append(.system(reason))
            presentBanner(reason)
        case let .disconnected(reason):
            if continuePendingSessionStartIfNeeded() {
                return
            }
            connectionToken = UUID()
            ircClient = nil
            cancelInvitePublication()
            currentSession = nil
            currentInviteCode = ""
            currentSessionIsCreator = false
            hideOverlay()
            connectionState = .disconnected(reason)
            messages.append(.system(reason))
            presentBanner(reason)
        }
    }

    private func showOverlayForManualEntry() {
        cancelPreviewAutoHide()
        overlayPresentationMode = .manual
        overlayVisible = true
        overlayWantsKeyboardFocus = true
        overlayFocusToken = UUID()
        overlayController?.show(with: settings.appearance, focus: true)
    }

    private func showPreviewOverlayForIncomingMessage() {
        guard hasActiveSession else { return }
        guard overlayPresentationMode != .manual else { return }
        guard settings.appearance.clamped().showIncomingPreview else { return }

        overlayPresentationMode = .preview
        overlayVisible = true
        overlayWantsKeyboardFocus = false
        overlayController?.show(with: settings.appearance, focus: false)
        schedulePreviewAutoHide()
    }

    private func schedulePreviewAutoHide() {
        cancelPreviewAutoHide()
        let delay = settings.appearance.clamped().previewDuration
        guard delay > 0 else { return }
        previewHideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.overlayPresentationMode == .preview else { return }
            self.hideOverlay()
        }
    }

    private func cancelPreviewAutoHide() {
        previewHideTask?.cancel()
        previewHideTask = nil
    }

    private func scheduleInvitePublicationFallback() {
        cancelInvitePublication()
        invitePublicationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard let self, self.currentSessionIsCreator, self.currentInviteCode.isEmpty, let currentSession = self.currentSession else {
                return
            }
            self.publishInvite(for: currentSession)
        }
    }

    private func cancelInvitePublication() {
        invitePublicationTask?.cancel()
        invitePublicationTask = nil
    }

    private func publishInvite(for session: SessionDescriptor) {
        cancelInvitePublication()
        currentInviteCode = (try? InviteCodeCodec.encode(session)) ?? ""
    }

    private func handleGlobalHotKeyTrigger() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastHotKeyTriggerUptime > 0.25 else { return }
        lastHotKeyTriggerUptime = now
        toggleOverlayFromHotKey()
    }

    private func apply(eventTapStatus: EventTapHotKeyController.Status) {
        switch eventTapStatus {
        case .active:
            hotKeyCaptureStatus = .enhanced
        case .permissionRequired:
            hotKeyCaptureStatus = .permissionRequired
        case .unavailable:
            hotKeyCaptureStatus = .unavailable
        }
    }

    private func continuePendingSessionStartIfNeeded() -> Bool {
        guard let pendingSessionStart else { return false }

        ircClient = nil
        cancelInvitePublication()
        currentSession = nil
        currentInviteCode = ""
        currentSessionIsCreator = false
        hideOverlay()
        self.pendingSessionStart = nil
        performSessionStart(pendingSessionStart)
        return true
    }

    private func validatedResolvedServer() throws -> ServerConfiguration {
        try validated(server: settings.resolvedServerConfiguration())
    }

    private func validated(server: ServerConfiguration) throws -> ServerConfiguration {
        let sanitized = server.sanitized()

        guard !sanitized.host.isEmpty else {
            throw InviteCodeError.invalidServer
        }

        return sanitized
    }

    private func presentBanner(_ text: String) {
        bannerText = text
    }

    private func persistSettingsIfNeeded() {
        guard !isNormalizingSettings else { return }
        let sanitized = settings.sanitized()

        if sanitized != settings {
            isNormalizingSettings = true
            settings = sanitized
            isNormalizingSettings = false
            return
        }

        L10n.setAppLanguage(sanitized.appLanguage)
        SettingsStore.save(sanitized)
        overlayController?.updateFrame(with: sanitized.appearance)
    }
}
