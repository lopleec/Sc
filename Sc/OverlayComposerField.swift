import AppKit
import SwiftUI

struct OverlayComposerField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let fontSize: Double
    let focusRequested: Bool
    let focusToken: UUID
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: text)
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.lineBreakMode = .byTruncatingTail
        field.maximumNumberOfLines = 1
        field.usesSingleLineMode = true
        field.delegate = context.coordinator
        field.placeholderString = placeholder
        field.font = .systemFont(ofSize: fontSize, weight: .medium)
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self

        if field.stringValue != text {
            field.stringValue = text
        }

        field.placeholderString = placeholder
        field.font = .systemFont(ofSize: fontSize, weight: .medium)
        context.coordinator.updateFocus(for: field, requested: focusRequested, token: focusToken)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: OverlayComposerField
        private var lastFocusToken: UUID?

        init(parent: OverlayComposerField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.text = control.stringValue
                parent.onSubmit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
                return true
            default:
                return false
            }
        }

        func updateFocus(for field: NSTextField, requested: Bool, token: UUID) {
            guard requested else { return }
            guard lastFocusToken != token else { return }
            lastFocusToken = token

            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
            }
        }
    }
}
