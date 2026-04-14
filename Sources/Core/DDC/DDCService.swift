import Foundation
import CoreGraphics

final class DDCService {
    static let shared = DDCService()

    private let transport: DDCTransport?
    private let queue = DispatchQueue(label: "com.cidra.ddc", qos: .utility)

    private var pendingBrightness: UInt16?
    private var pendingVolume: UInt16?
    private var scheduled = false

    /// Whether the external monitor supports DDC/CI (thread-safe via queue)
    private var _ddcSupported = false
    var ddcSupported: Bool {
        queue.sync { _ddcSupported }
    }
    /// The display ID of the external monitor (for gamma fallback)
    var externalDisplayID: CGDirectDisplayID = 0

    private init() {
        #if arch(arm64)
        transport = AppleSiliconDDCTransport()
        #else
        transport = nil
        #endif

        // Probe DDC support on background queue
        if let transport {
            queue.async { [weak self] in
                let supported = transport.probeDDC()
                self?._ddcSupported = supported
                CidraLog.write("[DDC] Probe result: DDC \(supported ? "supported" : "NOT supported — using gamma fallback")")
            }
        }
    }

    var isAvailable: Bool { transport != nil }

    func setBrightness(_ value: Int, displayID: CGDirectDisplayID = 0) {
        if ddcSupported {
            let clamped = UInt16(min(max(value, 0), 100))
            queue.async { [weak self] in
                self?.pendingBrightness = clamped
                self?.scheduleFlush()
            }
        } else {
            // Gamma fallback
            let targetID = displayID != 0 ? displayID : externalDisplayID
            guard targetID != 0 else { return }
            let normalized = Double(min(max(value, 0), 100)) / 100.0
            GammaBrightnessService.shared.setBrightness(normalized, displayID: targetID)
        }
    }

    func setVolume(_ value: Int) {
        guard ddcSupported else { return } // Volume only works with DDC
        let clamped = UInt16(min(max(value, 0), 100))
        queue.async { [weak self] in
            self?.pendingVolume = clamped
            self?.scheduleFlush()
        }
    }

    // MARK: - Throttled Flush

    private func scheduleFlush() {
        guard !scheduled else { return }
        scheduled = true
        queue.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.flush()
        }
    }

    private func flush() {
        scheduled = false
        guard let transport else { return }

        let brightness = pendingBrightness
        let volume = pendingVolume
        pendingBrightness = nil
        pendingVolume = nil

        if let b = brightness {
            do {
                try transport.write(command: VCPCode.brightness.rawValue, value: b)
            } catch {
                CidraLog.write("[DDC] Brightness FAIL: \(error)")
            }
        }

        if let v = volume {
            do {
                try transport.write(command: VCPCode.volume.rawValue, value: v)
            } catch {
                CidraLog.write("[DDC] Volume FAIL: \(error)")
            }
        }
    }
}
