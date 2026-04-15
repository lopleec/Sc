import ApplicationServices
import Foundation

final class EventTapHotKeyController {
    enum Status: Equatable {
        case active
        case permissionRequired
        case unavailable
    }

    private let keyCode: CGKeyCode
    private let requiredModifiers: CGEventFlags
    private let handler: () -> Void
    private let statusHandler: (Status) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(
        keyCode: CGKeyCode,
        requiredModifiers: CGEventFlags,
        handler: @escaping () -> Void,
        statusHandler: @escaping (Status) -> Void
    ) {
        self.keyCode = keyCode
        self.requiredModifiers = requiredModifiers
        self.handler = handler
        self.statusHandler = statusHandler
    }

    deinit {
        stop()
    }

    func refresh() {
        stop()

        guard CGPreflightListenEventAccess() else {
            statusHandler(.permissionRequired)
            return
        }

        installTap()
    }

    func requestPermission() {
        _ = CGRequestListenEventAccess()
        refresh()
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }

    private func installTap() {
        let eventMask = CGEventMask(1) << CGEventType.keyDown.rawValue
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let controller = Unmanaged<EventTapHotKeyController>.fromOpaque(userInfo).takeUnretainedValue()
            return controller.handleTapEvent(type: type, event: event)
        }

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            statusHandler(.unavailable)
            return
        }

        guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            CFMachPortInvalidate(eventTap)
            statusHandler(.unavailable)
            return
        }

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        statusHandler(.active)
    }

    private func handleTapEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        guard event.getIntegerValueField(.keyboardEventAutorepeat) == 0 else {
            return Unmanaged.passUnretained(event)
        }

        let pressedKeyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard pressedKeyCode == keyCode else {
            return Unmanaged.passUnretained(event)
        }

        let relevantModifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]
        let activeModifiers = event.flags.intersection(relevantModifiers)
        let expectedModifiers = requiredModifiers.intersection(relevantModifiers)
        guard activeModifiers == expectedModifiers else {
            return Unmanaged.passUnretained(event)
        }

        handler()
        return Unmanaged.passUnretained(event)
    }
}
