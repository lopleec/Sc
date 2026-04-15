import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            List {
                overviewSection
                activeSessionSection
                recentMessagesSidebarSection
            }
            .navigationTitle(L10n.string("app.title"))
            .listStyle(.sidebar)
        } detail: {
            Form {
                appIntroSection
                sessionControlsSection
                identitySection
                languageSection
                serverSection
                appearanceSection
                advancedAppearanceSection
                recentMessagesDetailSection
            }
            .formStyle(.grouped)
            .navigationTitle(L10n.string("app.settings.title"))
            .toolbar {
                ToolbarItemGroup {
                    Button(L10n.string("action.copy")) {
                        model.copyCurrentInviteCode()
                    }
                    .disabled(model.currentInviteCode.isEmpty)

                    Button(L10n.string("action.stop_session")) {
                        model.leaveCurrentSession()
                    }
                    .disabled(!model.hasActiveSession)
                }
            }
        }
        .environment(\.locale, model.appLocale)
    }

    private var overviewSection: some View {
        Section {
            LabeledContent {
                Label {
                    Text(model.connectionState.label)
                        .foregroundStyle(model.connectionState.tone)
                } icon: {
                    Image(systemName: connectionIconName)
                        .foregroundStyle(model.connectionState.tone)
                }
            } label: {
                Text(L10n.string("overview.connection"))
            }

            Label(L10n.string("overview.hotkey"), systemImage: "keyboard")
            Label(L10n.string("overview.auto_preview"), systemImage: "bell.badge")
            Label(L10n.string("overview.single_session"), systemImage: "person.2")

            LabeledContent {
                Label {
                    Text(model.hotKeyCaptureStatus.label)
                        .foregroundStyle(model.hotKeyCaptureStatus.tone)
                } icon: {
                    Image(systemName: model.hotKeyCaptureStatus.iconName)
                        .foregroundStyle(model.hotKeyCaptureStatus.tone)
                }
            } label: {
                Text(L10n.string("overview.hotkey_capture"))
            }

            Text(model.hotKeyCaptureStatus.note)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if model.shouldShowFullScreenHotKeyPermissionButton {
                Button(L10n.string("action.enable_fullscreen_hotkey")) {
                    model.requestFullScreenHotKeyPermission()
                }
                .buttonStyle(.borderedProminent)
            }

            if let bannerText = model.bannerText, !bannerText.isEmpty {
                Text(bannerText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var activeSessionSection: some View {
        Section(L10n.string("sidebar.active_session")) {
            if let session = model.currentSession {
                LabeledContent(L10n.string("field.channel")) {
                    Text(session.channel)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }

                LabeledContent(L10n.string("field.server")) {
                    Text(session.server.summary)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                }

                LabeledContent(L10n.string("field.nickname")) {
                    Text(model.settings.normalizedNickname)
                        .foregroundStyle(model.nicknamePreviewColor)
                        .fontWeight(.semibold)
                }
            } else {
                Text(L10n.string("session.none"))
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recentMessagesSidebarSection: some View {
        Section(L10n.string("sidebar.recent_messages")) {
            if model.displayedMessages.isEmpty {
                Text(L10n.string("messages.none.short"))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.displayedMessages) { message in
                    SidebarMessageRow(message: message)
                        .environmentObject(model)
                }
            }
        }
    }

    private var appIntroSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("app.subtitle"))
                    .font(.title3.weight(.semibold))

                Text(L10n.string("app.description"))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }

    private var sessionControlsSection: some View {
        Section {
            ViewThatFits(in: .horizontal) {
                HStack {
                    sessionActionButtons
                }
                VStack(alignment: .leading, spacing: 12) {
                    sessionActionButtons
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("field.join_code"))
                    .foregroundStyle(.secondary)

                TextField(L10n.string("session.join.placeholder"), text: $model.joinCodeInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(3...6)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.string("field.current_invite"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !model.currentInviteCode.isEmpty {
                        ShareLink(item: model.currentInviteCode) {
                            Label(L10n.string("action.share"), systemImage: "square.and.arrow.up")
                        }
                    }
                }

                if model.currentInviteCode.isEmpty {
                    Text(L10n.string("session.current_invite.empty"))
                        .foregroundStyle(.secondary)
                } else {
                    Text(model.currentInviteCode)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }

                Text(L10n.string("session.help"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(L10n.string("session.section"))
        }
    }

    private var sessionActionButtons: some View {
        Group {
            Button(L10n.string("action.create_session")) {
                model.createSession()
            }
            .buttonStyle(.borderedProminent)

            Button(L10n.string("action.join_session")) {
                model.joinSessionFromInvite()
            }
            .buttonStyle(.bordered)

            Button(L10n.string("action.stop_session")) {
                model.leaveCurrentSession()
            }
            .buttonStyle(.bordered)
            .disabled(!model.hasActiveSession)
        }
    }

    private var identitySection: some View {
        Section {
            TextField(L10n.string("field.nickname"), text: nicknameBinding())
                .textFieldStyle(.roundedBorder)

            LabeledContent(L10n.string("identity.color_preview")) {
                Text(model.settings.normalizedNickname)
                    .foregroundStyle(model.nicknamePreviewColor)
                    .fontWeight(.semibold)
            }
        } header: {
            Text(L10n.string("identity.section"))
        } footer: {
            Text(L10n.string("identity.footer"))
        }
    }

    private var languageSection: some View {
        Section {
            Picker(L10n.string("language.selection"), selection: binding(\.appLanguage)) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
        } header: {
            Text(L10n.string("language.section"))
        } footer: {
            Text(L10n.string("language.footer"))
        }
    }

    private var serverSection: some View {
        Section {
            Picker(L10n.string("server.preset"), selection: binding(\.selectedServerPreset)) {
                ForEach(ServerPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }

            if model.settings.selectedServerPreset == .custom {
                TextField(L10n.string("field.host"), text: binding(\.customServer.host))
                    .textFieldStyle(.roundedBorder)

                TextField(L10n.string("field.port"), value: binding(\.customServer.port), format: .number)
                    .textFieldStyle(.roundedBorder)

                Toggle(L10n.string("action.use_tls"), isOn: binding(\.customServer.useTLS))
            } else if let preset = model.settings.selectedServerPreset.defaultConfiguration {
                LabeledContent(L10n.string("field.host")) {
                    Text(preset.host)
                }

                LabeledContent(L10n.string("field.port")) {
                    Text("\(preset.port)")
                }

                LabeledContent(L10n.string("server.mode")) {
                    Text(L10n.string(preset.useTLS ? "server.mode.tls" : "server.mode.plain"))
                }
            }
        } header: {
            Text(L10n.string("server.section"))
        } footer: {
            Text(L10n.string("server.footer"))
        }
    }

    private var appearanceSection: some View {
        Section {
            sliderRow(title: "field.opacity", value: binding(\.appearance.overlayOpacity), range: 0.35...0.95, format: "%.2f")
            sliderRow(title: "field.font_size", value: binding(\.appearance.fontSize), range: 13...28, format: "%.0f")
            sliderRow(title: "field.width", value: binding(\.appearance.overlayWidth), range: 320...620, format: "%.0f px")
            sliderRow(title: "field.left_padding", value: binding(\.appearance.edgePadding), range: 0...60, format: "%.0f px")
            sliderRow(title: "field.bottom_padding", value: binding(\.appearance.bottomPadding), range: 0...80, format: "%.0f px")
            integerFieldRow(title: "field.visible_messages", value: bindingForMessageLimit(), range: 3...20)
        } header: {
            Text(L10n.string("appearance.section"))
        } footer: {
            Text(L10n.string("appearance.footer"))
        }
    }

    private var advancedAppearanceSection: some View {
        Section {
            integerFieldRow(title: "field.message_lines", value: bindingForMessageLineLimit(), range: 0...6)
            doubleFieldRow(title: "field.preview_duration", value: binding(\.appearance.previewDuration), range: 0...15, unit: L10n.string("field.seconds"))
            Toggle(L10n.string("field.auto_preview"), isOn: binding(\.appearance.showIncomingPreview))
            Toggle(L10n.string("field.timestamps"), isOn: binding(\.appearance.showTimestamps))
        } header: {
            Text(L10n.string("appearance.advanced.section"))
        } footer: {
            Text(L10n.string("appearance.advanced.footer"))
        }
    }

    private var recentMessagesDetailSection: some View {
        Section(L10n.string("messages.section")) {
            if model.displayedMessages.isEmpty {
                ContentUnavailableView {
                    Label(L10n.string("messages.none"), systemImage: "bubble.left.and.bubble.right")
                }
            } else {
                ForEach(model.displayedMessages) { message in
                    DetailMessageRow(message: message)
                        .environmentObject(model)
                }
            }
        }
    }

    private var connectionIconName: String {
        switch model.connectionState {
        case .idle:
            "dot.radiowaves.left.and.right"
        case .connecting, .joining:
            "clock.arrow.circlepath"
        case .connected:
            "checkmark.circle.fill"
        case .failed:
            "xmark.octagon.fill"
        case .disconnected:
            "bolt.horizontal.circle"
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent(L10n.string(title)) {
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range)
        }
        .padding(.vertical, 2)
    }

    private func integerFieldRow(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(L10n.string(title))
            Spacer(minLength: 12)
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    private func doubleFieldRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(L10n.string(title))
            Spacer(minLength: 12)
            TextField("", value: value, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
            Text(unit)
                .foregroundStyle(.secondary)
            Stepper("", value: value, in: range, step: 1)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { model.settings[keyPath: keyPath] = $0 }
        )
    }

    private func nicknameBinding() -> Binding<String> {
        Binding(
            get: { model.settings.nickname },
            set: { model.settings.nickname = NicknameRules.sanitizeInput($0) }
        )
    }

    private func bindingForMessageLimit() -> Binding<Int> {
        Binding(
            get: { model.settings.appearance.messageLimit },
            set: { model.settings.appearance.messageLimit = $0 }
        )
    }

    private func bindingForMessageLineLimit() -> Binding<Int> {
        Binding(
            get: { model.settings.appearance.messageLineLimit },
            set: { model.settings.appearance.messageLineLimit = $0 }
        )
    }
}

private struct SidebarMessageRow: View {
    @EnvironmentObject private var model: AppModel
    let message: ChatMessage

    private var timestampText: String {
        message.timestamp.formatted(date: .omitted, time: .shortened)
    }

    private var lineLimit: Int? {
        let limit = model.settings.appearance.clamped().messageLineLimit
        return limit == 0 ? nil : limit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if message.kind == .system {
                if model.settings.appearance.showTimestamps {
                    Text(timestampText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(message.text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(lineLimit)
            } else {
                if model.settings.appearance.showTimestamps {
                    Text(timestampText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(message.sender ?? L10n.string("common.unknown"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(model.color(for: message.sender ?? L10n.string("common.unknown")))

                Text(message.text)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(lineLimit)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct DetailMessageRow: View {
    @EnvironmentObject private var model: AppModel
    let message: ChatMessage

    private var timestampText: String {
        message.timestamp.formatted(date: .omitted, time: .shortened)
    }

    private var lineLimit: Int? {
        let limit = model.settings.appearance.clamped().messageLineLimit
        return limit == 0 ? nil : limit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if model.settings.appearance.showTimestamps {
                Text(timestampText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if message.kind == .system {
                Text(message.text)
                    .foregroundStyle(.secondary)
                    .lineLimit(lineLimit)
            } else {
                Text(message.sender ?? L10n.string("common.unknown"))
                    .foregroundStyle(model.color(for: message.sender ?? L10n.string("common.unknown")))
                    .fontWeight(.semibold)

                Text(message.text)
                    .lineLimit(lineLimit)
            }
        }
        .padding(.vertical, 2)
    }
}
