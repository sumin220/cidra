import Foundation
import CoreGraphics

/// Controls built-in display brightness via DisplayServices private framework.
/// Works on Apple Silicon Macs where IODisplayConnect is unavailable.
final class BuiltInBrightnessService {
    static let shared = BuiltInBrightnessService()

    private typealias SetBrightnessFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private typealias GetBrightnessFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

    private let setBrightnessFn: SetBrightnessFn?
    private let getBrightnessFn: GetBrightnessFn?
    private let builtInDisplayID: CGDirectDisplayID?

    private init() {
        let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)

        if let handle, let sym = dlsym(handle, "DisplayServicesSetBrightness") {
            setBrightnessFn = unsafeBitCast(sym, to: SetBrightnessFn.self)
        } else {
            setBrightnessFn = nil
        }

        if let handle, let sym = dlsym(handle, "DisplayServicesGetBrightness") {
            getBrightnessFn = unsafeBitCast(sym, to: GetBrightnessFn.self)
        } else {
            getBrightnessFn = nil
        }

        // Find built-in display ID
        var ids = [CGDirectDisplayID](repeating: 0, count: 8)
        var count: UInt32 = 0
        CGGetActiveDisplayList(8, &ids, &count)
        builtInDisplayID = ids[0..<Int(count)].first { CGDisplayIsBuiltin($0) != 0 }
    }

    func setBrightness(_ value: Double) {
        guard let fn = setBrightnessFn, let id = builtInDisplayID else {
            print("[Brightness] DisplayServices not available")
            return
        }
        let clamped = Float(min(max(value, 0), 1))
        let result = fn(id, clamped)
        if result != 0 {
            print("[Brightness] SetBrightness failed: \(result)")
        }
    }

    func getBrightness() -> Double? {
        guard let fn = getBrightnessFn, let id = builtInDisplayID else { return nil }
        var val: Float = 0
        let result = fn(id, &val)
        guard result == 0 else { return nil }
        return Double(val)
    }
}
