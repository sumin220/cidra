import Foundation
import CoreGraphics

/// Controls XDR/HDR extra brightness on built-in Apple displays.
/// Uses CoreDisplay private API to push brightness beyond SDR maximum (up to 1600 nits).
final class XDRBrightnessService {
    static let shared = XDRBrightnessService()

    private typealias SetLinearFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private let setLinearBrightness: SetLinearFn?
    private let builtInID: CGDirectDisplayID?

    private init() {
        let handle = dlopen(nil, RTLD_LAZY)
        if let handle, let sym = dlsym(handle, "CoreDisplay_Display_SetLinearBrightness") {
            setLinearBrightness = unsafeBitCast(sym, to: SetLinearFn.self)
        } else {
            setLinearBrightness = nil
        }

        var ids = [CGDirectDisplayID](repeating: 0, count: 8)
        var count: UInt32 = 0
        CGGetActiveDisplayList(8, &ids, &count)
        builtInID = ids[0..<Int(count)].first { CGDisplayIsBuiltin($0) != 0 }
    }

    /// Set XDR brightness boost.
    /// level: 0.0 = SDR max (no boost), 1.0 = full XDR (1600 nits)
    func setXDRBrightness(_ level: Float) {
        guard let fn = setLinearBrightness, let id = builtInID else { return }

        // Linear brightness: 1.0 = SDR max, values above 1.0 = XDR
        // Map 0~1 input to 1.0~1.6 linear brightness
        let linear = 1.0 + (level * 0.6)
        let result = fn(id, min(max(linear, 1.0), 1.6))
        if result != 0 {
            CidraLog.write("[XDR] SetLinearBrightness failed: \(result)")
        }
    }

    var isAvailable: Bool {
        setLinearBrightness != nil && builtInID != nil
    }
}
