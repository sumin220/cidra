import Foundation

/// Persists presets to ~/Library/Application Support/Cidra/presets.json
final class PresetStore {
    static let shared = PresetStore()

    private let fileURL: URL = {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Application Support directory not found")
        }
        let dir = appSupport.appendingPathComponent("Cidra", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("presets.json")
    }()

    private init() {}

    func loadPresets() -> [Preset] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Preset].self, from: data)
        } catch {
            CidraLog.write("[PresetStore] Load failed: \(error.localizedDescription)")
            return []
        }
    }

    func savePresets(_ presets: [Preset]) {
        do {
            let data = try JSONEncoder().encode(presets)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            CidraLog.write("[PresetStore] Save failed: \(error.localizedDescription)")
        }
    }
}
