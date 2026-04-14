import Foundation
import AppKit
import Combine

/// Automatically switches presets based on app activation or time of day.
final class AutoTriggerEngine: ObservableObject {
    static let shared = AutoTriggerEngine()

    struct Trigger: Codable, Identifiable {
        let id: UUID
        let presetID: UUID
        var type: TriggerType
        var value: String // app bundle ID or time "HH:mm"

        init(presetID: UUID, type: TriggerType, value: String) {
            self.id = UUID()
            self.presetID = presetID
            self.type = type
            self.value = value
        }
    }

    enum TriggerType: String, Codable, CaseIterable {
        case app = "App"
        case time = "Time"
    }

    @Published var triggers: [Trigger] = []
    private var cancellables = Set<AnyCancellable>()
    private var applyPreset: ((UUID) -> Void)?
    private var timeTimer: Timer?

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Cidra", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("triggers.json")
    }()

    private init() {
        loadTriggers()
    }

    /// Start monitoring. Call with a closure that applies a preset by ID.
    func start(applyPreset: @escaping (UUID) -> Void) {
        self.applyPreset = applyPreset
        startAppMonitoring()
        startTimeMonitoring()
    }

    func stop() {
        cancellables.removeAll()
        timeTimer?.invalidate()
        timeTimer = nil
    }

    // MARK: - Trigger Management

    func addTrigger(_ trigger: Trigger) {
        triggers.append(trigger)
        saveTriggers()
    }

    func removeTrigger(id: UUID) {
        triggers.removeAll { $0.id == id }
        saveTriggers()
    }

    func triggersForPreset(_ presetID: UUID) -> [Trigger] {
        triggers.filter { $0.presetID == presetID }
    }

    // MARK: - App-based Triggers

    private func startAppMonitoring() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleID = app.bundleIdentifier else { return }
                self?.handleAppActivation(bundleID: bundleID)
            }
            .store(in: &cancellables)
    }

    private func handleAppActivation(bundleID: String) {
        if let trigger = triggers.first(where: { $0.type == .app && $0.value == bundleID }) {
            CidraLog.write("[AutoTrigger] App \(bundleID) → preset \(trigger.presetID)")
            applyPreset?(trigger.presetID)
        }
    }

    // MARK: - Time-based Triggers

    private func startTimeMonitoring() {
        let t = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkTimeTriggers()
        }
        RunLoop.main.add(t, forMode: .common)
        timeTimer = t
    }

    private func checkTimeTriggers() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let now = formatter.string(from: Date())

        if let trigger = triggers.first(where: { $0.type == .time && $0.value == now }) {
            CidraLog.write("[AutoTrigger] Time \(now) → preset \(trigger.presetID)")
            applyPreset?(trigger.presetID)
        }
    }

    // MARK: - Persistence

    private func loadTriggers() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let loaded = try? JSONDecoder().decode([Trigger].self, from: data) else { return }
        triggers = loaded
    }

    private func saveTriggers() {
        guard let data = try? JSONEncoder().encode(triggers) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
