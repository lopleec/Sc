import SwiftUI

struct OverlayChatView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme

    private var lineLimit: Int? {
        let limit = model.settings.appearance.clamped().messageLineLimit
        return limit == 0 ? nil : limit
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 10) {
                header

                Divider()

                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(model.messages) { message in
                            messageLine(message)
                                .id(message.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                Divider()

                VStack(alignment: .leading, spacing: 2) {
                    OverlayComposerField(
                        text: $model.composerText,
                        placeholder: L10n.string("overlay.input.placeholder"),
                        fontSize: max(model.settings.appearance.fontSize - 1, 12),
                        focusRequested: model.overlayWantsKeyboardFocus,
                        focusToken: model.overlayFocusToken,
                        onSubmit: model.sendCurrentMessage,
                        onCancel: model.hideOverlay
                    )
                    .frame(height: max(model.settings.appearance.fontSize + 4, 20))

                    HStack(spacing: 8) {
                        Text(L10n.string("overlay.return_to_send"))
                        Text(L10n.string("overlay.esc_to_hide"))
                    }
                    .font(.system(size: max(model.settings.appearance.fontSize - 9, 8), weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(colorScheme == .dark ? Color.black.opacity(0.18) : Color.white.opacity(0.22))
                    }
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.22 : 0.10), radius: 18, y: 10)
            .padding(2)
            .onChange(of: model.overlayFocusToken) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    scrollToBottom(with: proxy, animated: false)
                }
            }
            .onChange(of: model.messages.count) {
                scrollToBottom(with: proxy)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    scrollToBottom(with: proxy, animated: false)
                }
            }
            .onExitCommand {
                model.hideOverlay()
            }
        }
        .environment(\.locale, model.appLocale)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Label(L10n.string("app.title"), systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)

            if let channel = model.currentSession?.channel {
                Text(channel)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Command + /")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func messageLine(_ message: ChatMessage) -> some View {
        if message.kind == .system {
            VStack(alignment: .leading, spacing: 2) {
                if model.settings.appearance.showTimestamps {
                    Text(message.timestamp, format: .dateTime.hour().minute())
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text(message.text)
                    .font(.system(size: max(model.settings.appearance.fontSize - 3, 11), weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(lineLimit)
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                if model.settings.appearance.showTimestamps {
                    Text(message.timestamp, format: .dateTime.hour().minute())
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(message.sender ?? L10n.string("common.unknown"))
                        .foregroundStyle(model.color(for: message.sender ?? L10n.string("common.unknown")))
                        .fontWeight(.semibold)

                    Text(message.text)
                        .foregroundStyle(.primary)
                }
                .font(.system(size: max(model.settings.appearance.fontSize - 2, 12), weight: .medium, design: .rounded))
                .lineLimit(lineLimit)
            }
        }
    }

    private func scrollToBottom(with proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastMessage = model.messages.last else { return }

        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.16)) {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}
