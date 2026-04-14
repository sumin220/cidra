import AppKit
import SwiftUI

final class OSDOverlayWindow: NSWindow {
    private var hostingView: NSHostingView<OSDView>?
    private var dismissWorkItem: DispatchWorkItem?
    private var isShowing = false

    init(type: OSDType, value: Double) {
        let frame = NSRect(x: 0, y: 0, width: 200, height: 44)

        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let view = OSDView(type: type, value: value)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = frame
        self.contentView = hosting
        self.hostingView = hosting
    }

    func update(type: OSDType, value: Double) {
        hostingView?.rootView = OSDView(type: type, value: value)
    }

    func showOnScreen(_ screen: NSScreen) {
        // Cancel pending dismiss
        dismissWorkItem?.cancel()

        // Position: bottom center, 80px from bottom
        let x = screen.frame.midX - frame.width / 2
        let y = screen.frame.minY + 80
        setFrameOrigin(NSPoint(x: x, y: y))

        if !isShowing {
            // First appearance — fade in
            isShowing = true
            alphaValue = 0
            orderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                self.animator().alphaValue = 1
            }
        }
        // If already showing, value is already updated via update() — no animation needed

        // Reset dismiss timer
        let work = DispatchWorkItem { [weak self] in
            self?.fadeOut()
        }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func fadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 0
        } completionHandler: {
            self.isShowing = false
            self.orderOut(nil)
            self.alphaValue = 1
        }
    }
}
