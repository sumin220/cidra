import Foundation

/// Controls macOS font smoothing settings for sharper text on external monitors.
/// Changes take effect immediately for newly rendered text; some apps may need restart.
final class FontSmoothingService {
    static let shared = FontSmoothingService()
    private init() {}

    /// Current font smoothing level (0=off, 1=light, 2=medium, 3=strong)
    var currentLevel: Int {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["-currentHost", "read", "-g", "AppleFontSmoothing"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(output ?? "") ?? -1
    }

    /// Whether subpixel antialiasing is enabled
    var isSubpixelEnabled: Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["read", "-g", "CGFontRenderingFontSmoothingDisabled"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // If "0" or missing → subpixel is enabled
        return output != "1"
    }

    /// Enable sharpening: font smoothing level 2 + subpixel antialiasing ON
    func enableSharpening() {
        runDefaults(["-currentHost", "write", "-g", "AppleFontSmoothing", "-int", "2"])
        runDefaults(["write", "-g", "CGFontRenderingFontSmoothingDisabled", "-bool", "NO"])
        CidraLog.write("[Font] Sharpening enabled: smoothing=2, subpixel=ON")
    }

    /// Disable sharpening: reset to macOS defaults
    func disableSharpening() {
        runDefaults(["-currentHost", "delete", "-g", "AppleFontSmoothing"])
        runDefaults(["delete", "-g", "CGFontRenderingFontSmoothingDisabled"])
        CidraLog.write("[Font] Sharpening disabled: reset to defaults")
    }

    /// Check if sharpening is currently active
    var isSharpeningActive: Bool {
        currentLevel == 2 && isSubpixelEnabled
    }

    private func runDefaults(_ args: [String]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = args
        try? task.run()
        task.waitUntilExit()
    }
}
