import Foundation
import CoreGraphics

/// Manages HiDPI display override plists.
/// Installs/removes override files in /Library/Displays/Contents/Resources/Overrides/
/// to add HiDPI resolution modes to external monitors.
final class DisplayOverrideManager {
    static let shared = DisplayOverrideManager()
    private init() {}

    private let overridesDir = "/Library/Displays/Contents/Resources/Overrides"

    struct HiDPIResolution {
        let logicalWidth: Int
        let logicalHeight: Int
        var label: String { "\(logicalWidth) x \(logicalHeight)" }
        var backingWidth: Int { logicalWidth * 2 }
        var backingHeight: Int { logicalHeight * 2 }
    }

    /// Calculate a near-native resolution (~99.5% of physical) for "invisible" HiDPI.
    /// macOS won't allow exact native as HiDPI, but near-native is indistinguishable.
    func nearNativeResolution(physicalWidth: Int, physicalHeight: Int) -> HiDPIResolution {
        // Try decreasing width by small steps, find one that keeps close aspect ratio
        let targetRatio = Double(physicalWidth) / Double(physicalHeight)
        for offset in stride(from: 8, through: 32, by: 2) {
            let w = physicalWidth - offset
            let h = Int(Double(w) / targetRatio)
            // Check aspect ratio is close enough (within 0.1%)
            let actualRatio = Double(w) / Double(h)
            if abs(actualRatio - targetRatio) / targetRatio < 0.001 {
                return HiDPIResolution(logicalWidth: w, logicalHeight: h)
            }
        }
        // Fallback: just subtract 16 from each
        return HiDPIResolution(logicalWidth: physicalWidth - 16, logicalHeight: physicalHeight - 6)
    }

    /// Generate all recommended HiDPI resolutions including near-native
    func recommendedResolutions(physicalWidth: Int, physicalHeight: Int) -> [HiDPIResolution] {
        let aspectW = physicalWidth
        let aspectH = physicalHeight
        let g = gcd(aspectW, aspectH)
        let ratioW = aspectW / g
        let ratioH = aspectH / g

        var results: [HiDPIResolution] = []

        // Add near-native first (most important for "same resolution" experience)
        let nearNative = nearNativeResolution(physicalWidth: physicalWidth, physicalHeight: physicalHeight)
        results.append(nearNative)

        // Add standard scaled resolutions
        let candidates = [960, 1024, 1280, 1440, 1600, 1680, 1720, 1920, 1935,
                          2048, 2240, 2365, 2560, 2580, 2752, 2880, 3072, 3200, 3440, 3840]

        for w in candidates {
            let h = w * ratioH / ratioW
            guard h * ratioW == w * ratioH else { continue }
            guard w >= 640, h >= 480 else { continue }
            guard w <= physicalWidth else { continue }
            // Skip if too close to near-native (avoid duplicates)
            if abs(w - nearNative.logicalWidth) < 20 { continue }
            results.append(HiDPIResolution(logicalWidth: w, logicalHeight: h))
        }

        return results.sorted { $0.logicalWidth > $1.logicalWidth }
    }

    /// Check if override is already installed for a display
    func isInstalled(vendorID: UInt32, productID: UInt32) -> Bool {
        let path = overridePath(vendorID: vendorID, productID: productID)
        return FileManager.default.fileExists(atPath: path)
    }

    /// Install HiDPI override plist (requires admin privileges)
    func install(vendorID: UInt32, productID: UInt32,
                 resolutions: [HiDPIResolution],
                 completion: @escaping (Bool, String) -> Void) {

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let plist = self.generatePlist(vendorID: vendorID, productID: productID,
                                               resolutions: resolutions)
                let tempFile = NSTemporaryDirectory() + "cidra_display_override.plist"
                try plist.write(toFile: tempFile, atomically: true, encoding: .utf8)

                let vendorHex = String(format: "%x", vendorID)
                let productHex = String(format: "%x", productID)
                let displayDir = "\(self.overridesDir)/DisplayVendorID-\(vendorHex)"
                let displayFile = "\(displayDir)/DisplayProductID-\(productHex)"

                let script = """
                mkdir -p "\(displayDir)" && \
                cp "\(tempFile)" "\(displayFile)" && \
                chown root:wheel "\(displayFile)" && \
                chmod 644 "\(displayFile)" && \
                rm "\(tempFile)" && \
                defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES
                """

                try self.runPrivileged(script)

                DispatchQueue.main.async {
                    completion(true, "HiDPI override installed. Reboot required.")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Remove HiDPI override (requires admin privileges)
    func uninstall(vendorID: UInt32, productID: UInt32,
                   completion: @escaping (Bool, String) -> Void) {

        let vendorHex = String(format: "%x", vendorID)
        let displayDir = "\(overridesDir)/DisplayVendorID-\(vendorHex)"

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.runPrivileged("rm -rf \"\(displayDir)\"")
                DispatchQueue.main.async {
                    completion(true, "HiDPI override removed. Reboot required.")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Plist Generation

    private func generatePlist(vendorID: UInt32, productID: UInt32,
                               resolutions: [HiDPIResolution]) -> String {
        var dataEntries: [String] = []

        for res in resolutions {
            // Each resolution needs TWO data entries:
            // 1. Non-HiDPI: width(4 bytes) + height(4 bytes) + flags(4 bytes = 0x00000001)
            // 2. HiDPI:     width(4 bytes) + height(4 bytes) + flags(4 bytes = 0x00000001) + hidpi(4 bytes = 0x00200000)
            let w = res.backingWidth
            let h = res.backingHeight

            // Non-HiDPI entry (12 bytes)
            var nonHiDPI = Data()
            nonHiDPI.append(contentsOf: withUnsafeBytes(of: UInt32(w).bigEndian) { Array($0) })
            nonHiDPI.append(contentsOf: withUnsafeBytes(of: UInt32(h).bigEndian) { Array($0) })
            nonHiDPI.append(contentsOf: withUnsafeBytes(of: UInt32(0x00000001).bigEndian) { Array($0) })
            dataEntries.append("            <data>\(nonHiDPI.base64EncodedString())</data>")

            // HiDPI entry (16 bytes) — this is the one that enables Retina scaling
            var hiDPI = Data()
            hiDPI.append(contentsOf: withUnsafeBytes(of: UInt32(w).bigEndian) { Array($0) })
            hiDPI.append(contentsOf: withUnsafeBytes(of: UInt32(h).bigEndian) { Array($0) })
            hiDPI.append(contentsOf: withUnsafeBytes(of: UInt32(0x00000001).bigEndian) { Array($0) })
            hiDPI.append(contentsOf: withUnsafeBytes(of: UInt32(0x00200000).bigEndian) { Array($0) })
            dataEntries.append("            <data>\(hiDPI.base64EncodedString())</data>")
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>DisplayProductID</key>
            <integer>\(productID)</integer>
            <key>DisplayVendorID</key>
            <integer>\(vendorID)</integer>
            <key>scale-resolutions</key>
            <array>
        \(dataEntries.joined(separator: "\n"))
            </array>
            <key>target-default-ppmm</key>
            <real>10.0699301</real>
        </dict>
        </plist>
        """
    }

    // MARK: - Privileged Execution

    /// Runs a shell command with admin privileges via osascript.
    /// SECURITY: Only called with internally-constructed commands derived from UInt32 values.
    /// Never pass user-controlled strings to this method.
    private func runPrivileged(_ command: String) throws {
        // Validate: reject any command containing shell metacharacters that shouldn't be there
        let dangerousChars = CharacterSet(charactersIn: ";|&$`\\'\n")
            .subtracting(CharacterSet(charactersIn: "\"/ -."))
        guard command.unicodeScalars.allSatisfy({ !dangerousChars.contains($0) || "/\"- .".unicodeScalars.contains($0) }) else {
            throw NSError(domain: "Cidra", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Blocked: command contains suspicious characters"])
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        // Pass command directly to osascript — no temp script file
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "\"", with: "\\\"")
        process.arguments = ["-e", "do shell script \"\(escaped)\" with administrator privileges"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw NSError(domain: "Cidra", code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: output])
        }
    }

    // MARK: - Helpers

    private func overridePath(vendorID: UInt32, productID: UInt32) -> String {
        let vendorHex = String(format: "%x", vendorID)
        let productHex = String(format: "%x", productID)
        return "\(overridesDir)/DisplayVendorID-\(vendorHex)/DisplayProductID-\(productHex)"
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}

private extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex
        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let b = UInt8(hexString[index..<nextIndex], radix: 16) else { return nil }
            data.append(b)
            index = nextIndex
        }
        self = data
    }
}
