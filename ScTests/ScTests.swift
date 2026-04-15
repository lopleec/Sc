import XCTest
@testable import Sc

final class ScTests: XCTestCase {
    func testInviteCodeRoundTripPreservesServerAndSecrets() throws {
        let session = SessionDescriptor(
            server: ServerConfiguration(host: "irc.libera.chat", port: 6697, useTLS: true),
            channel: "#sc-abc123",
            password: "hunter2"
        )

        let encoded = try InviteCodeCodec.encode(session)
        let decoded = try InviteCodeCodec.decode(encoded)

        XCTAssertEqual(decoded, session)
    }

    func testRandomSessionProducesLongRandomChannelAndPassword() {
        let session = SessionDescriptor.random(server: ServerConfiguration(host: "irc.rizon.net", port: 6697, useTLS: true))

        XCTAssertTrue(session.channel.hasPrefix(SessionDescriptor.channelPrefix))
        XCTAssertGreaterThanOrEqual(session.channel.count, 22)
        XCTAssertEqual(session.password.count, SessionDescriptor.passwordLength)
        XCTAssertTrue(session.password.allSatisfy { $0.isNumber || $0.isLowercase })
    }

    func testNicknameColorIsStableWithinASessionButChangesAcrossSessions() {
        let first = NicknameColorPalette.stableHash("room-a|alex")
        let firstAgain = NicknameColorPalette.stableHash("room-a|alex")
        let secondRoom = NicknameColorPalette.stableHash("room-b|alex")

        XCTAssertEqual(first, firstAgain)
        XCTAssertNotEqual(first, secondRoom)
    }

    func testPresetServerResolutionUsesExpectedDefaults() {
        var settings = AppSettings()
        settings.selectedServerPreset = .oftc

        let resolved = settings.resolvedServerConfiguration()

        XCTAssertEqual(resolved.host, "irc.oftc.net")
        XCTAssertEqual(resolved.port, 6697)
        XCTAssertTrue(resolved.useTLS)
    }

    func testChannelModeCommandsLockAndHideCreatedRooms() {
        let commands = IRCClient.channelModeCommands(channel: "#sc-hidden", password: "abc123xyz")

        XCTAssertEqual(commands, ["MODE #sc-hidden +s", "MODE #sc-hidden +k abc123xyz"])
    }

    func testAcceptedChannelKeyUsesServerAppliedValue() {
        let key = IRCClient.acceptedChannelKey(
            for: "#sc-hidden",
            parameters: ["#sc-hidden", "+sk", "serverkey123"]
        )

        XCTAssertEqual(key, "serverkey123")
    }

    func testNicknameSanitizationStripsNonASCIICharacters() {
        var settings = AppSettings()
        settings.nickname = "玩家Alex_42"

        XCTAssertEqual(settings.normalizedNickname, "Alex42")
    }

    func testLegacySettingsDecodeDefaultsLanguageToSystem() throws {
        let legacyPayload = """
        {
          "nickname": "EchoFox42",
          "selectedServerPreset": "libera",
          "customServer": {
            "host": "irc.example.net",
            "port": 6697,
            "useTLS": true
          },
          "appearance": {
            "overlayOpacity": 0.72,
            "fontSize": 17,
            "overlayWidth": 420,
            "edgePadding": 18,
            "bottomPadding": 26,
            "messageLimit": 6
          }
        }
        """

        let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(legacyPayload.utf8))

        XCTAssertEqual(decoded.appLanguage, .system)
    }
}
