import Foundation
import CoreGraphics
import IOKit

/// Detects connected displays and extracts display info from EDID data.
final class MonitorDetector {
    static let shared = MonitorDetector()
    private init() {}

    struct DisplayInfo {
        let displayID: CGDirectDisplayID
        let name: String
        let isBuiltIn: Bool
        let width: Int
        let height: Int
        let refreshRate: Int
    }

    /// Returns all currently connected displays
    func detectDisplays() -> [DisplayInfo] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0

        let err = CGGetActiveDisplayList(16, &displayIDs, &displayCount)
        guard err == .success, displayCount > 0 else {
            print("[Monitor] No displays found")
            return []
        }

        return (0..<Int(displayCount)).compactMap { i in
            let id = displayIDs[i]
            let isBuiltIn = CGDisplayIsBuiltin(id) != 0
            let width = CGDisplayPixelsWide(id)
            let height = CGDisplayPixelsHigh(id)
            let name = isBuiltIn ? "Built-in Display" : displayName(for: id)

            let mode = CGDisplayCopyDisplayMode(id)
            let refreshRate = Int(mode?.refreshRate ?? 60)

            return DisplayInfo(
                displayID: id,
                name: name,
                isBuiltIn: isBuiltIn,
                width: width,
                height: height,
                refreshRate: refreshRate
            )
        }
    }

    /// Extract display name from IOKit EDID data
    private func displayName(for displayID: CGDirectDisplayID) -> String {
        // Try IOKit service first (reliable, no private API)
        if let name = ioKitDisplayName(for: displayID) {
            return name
        }

        // Try CoreDisplay private API via dlsym
        if let name = coreDisplayName(for: displayID) {
            return name
        }

        return "External Display"
    }

    private func coreDisplayName(for displayID: CGDirectDisplayID) -> String? {
        typealias Fn = @convention(c) (CGDirectDisplayID) -> Unmanaged<CFDictionary>?
        guard let handle = dlopen(nil, RTLD_LAZY),
              let sym = dlsym(handle, "CoreDisplay_DisplayCreateInfoDictionary") else {
            return nil
        }
        let fn = unsafeBitCast(sym, to: Fn.self)
        guard let dict = fn(displayID)?.takeRetainedValue() as? [String: Any],
              let names = dict[kDisplayProductName as String] as? [String: String] else {
            return nil
        }
        return names["en_US"] ?? names.values.first
    }

    private func ioKitDisplayName(for displayID: CGDirectDisplayID) -> String? {
        var iter: io_iterator_t = 0
        let matching = IOServiceMatching("IODisplayConnect")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == kIOReturnSuccess else {
            return nil
        }
        defer { IOObjectRelease(iter) }

        var service = IOIteratorNext(iter)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iter)
            }

            if let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName))?.takeRetainedValue() as? [String: Any],
               let vendorID = info[kDisplayVendorID] as? UInt32,
               let productID = info[kDisplayProductID] as? UInt32 {

                let cgVendor = CGDisplayVendorNumber(displayID)
                let cgProduct = CGDisplayModelNumber(displayID)

                if vendorID == cgVendor && productID == cgProduct {
                    if let names = info[kDisplayProductName as String] as? [String: String] {
                        return names["en_US"] ?? names.values.first
                    }
                }
            }
        }
        return nil
    }
}

