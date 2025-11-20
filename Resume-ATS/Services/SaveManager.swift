import Combine
import Foundation
import SwiftData

class SaveManager: ObservableObject {
    static let shared = SaveManager()

    @Published var isSaving = false
    @Published var lastSaveTime: Date?
    @Published var lastBackupTime: Date?
    @Published var saveError: String?

    private var modelContainer: ModelContainer?
    private var autoSaveTimer: Timer?
    private var autoBackupTimer: Timer?
    private let saveLock = NSLock()
    private weak var mainModelContext: ModelContext?

    var backupCallback: ((String) -> URL?)? = nil

    private let autoSaveInterval: TimeInterval = 30
    private let autoBackupInterval: TimeInterval = 3600

    private init() {
        print("💾 SaveManager initialized")
    }

    func configure(with container: ModelContainer) {
        self.modelContainer = container
        print("✅ SaveManager configured with ModelContainer")
    }

    func registerMainContext(_ context: ModelContext) {
        self.mainModelContext = context
        print("🔗 SaveManager: Main UI context registered")
    }

    func startAutoSave() {
        guard modelContainer != nil else {
            print("❌ SaveManager: Cannot start auto-save without ModelContainer")
            return
        }

        stopAutoSave()

        print("⏰ SaveManager: Starting auto-save (interval: \(Int(autoSaveInterval))s)")

        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) {
            [weak self] _ in
            self?.performAutoSave()
        }

        if let timer = autoSaveTimer {
            RunLoop.current.add(timer, forMode: .common)
        }

        startAutoBackup()
    }

    func stopAutoSave() {
        if let timer = autoSaveTimer {
            timer.invalidate()
            autoSaveTimer = nil
            print("⏰ SaveManager: Auto-save stopped")
        }

        stopAutoBackup()
    }

    func startAutoBackup() {
        guard modelContainer != nil else {
            print("❌ SaveManager: Cannot start auto-backup without ModelContainer")
            return
        }

        stopAutoBackup()

        print(
            "⏰ SaveManager: Starting auto-backup (interval: \(Int(autoBackupInterval))s = \(Int(autoBackupInterval / 60))m)"
        )

        autoBackupTimer = Timer.scheduledTimer(withTimeInterval: autoBackupInterval, repeats: true)
        {
            [weak self] _ in
            self?.performAutoBackup()
        }

        if let timer = autoBackupTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func stopAutoBackup() {
        if let timer = autoBackupTimer {
            timer.invalidate()
            autoBackupTimer = nil
            print("⏰ SaveManager: Auto-backup stopped")
        }
    }

    private func performAutoSave() {
        guard let context = mainModelContext else {
            print("⚠️  SaveManager: Auto-save skipped - no UI context registered")
            return
        }

        print("")
        print("═══════════════════════════════════════════════════════════")
        print("💾 SaveManager: Auto-save triggered")
        print("   Time: \(Date().formatted(date: .abbreviated, time: .standard))")
        print("═══════════════════════════════════════════════════════════")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let success = self?.saveContext(context, reason: "Auto-save") ?? false
            if success {
                print("✅ Auto-save completed")
            } else {
                print("❌ Auto-save failed")
            }
            print("═══════════════════════════════════════════════════════════")
            print("")
        }
    }

    private func performAutoBackup() {
        print("")
        print("═══════════════════════════════════════════════════════════")
        print("📦 SaveManager: Starting automatic backup...")
        print("   Time: \(Date().formatted(date: .abbreviated, time: .standard))")
        print("═══════════════════════════════════════════════════════════")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let backupURL = self?.backupCallback?("Automatic hourly backup")

            DispatchQueue.main.async {
                if backupURL != nil {
                    self?.lastBackupTime = Date()
                    print("✅ SaveManager: Automatic backup completed successfully")
                    print("   Backup: \(backupURL?.lastPathComponent ?? "unknown")")
                } else {
                    print("❌ SaveManager: Automatic backup failed")
                }
                print("═══════════════════════════════════════════════════════════")
                print("")
            }
        }
    }

    @discardableResult
    func forceSave(
        from container: ModelContainer,
        reason: String,
        shouldBackup: Bool = false
    ) -> Bool {
        if let context = mainModelContext {
            let success = saveContext(context, reason: reason)

            if success && shouldBackup {
                performBackup(reason: reason)
            }

            return success
        } else {
            print("⚠️  SaveManager: Using fallback context (UI context not registered)")
            let tempContext = ModelContext(container)
            let success = saveContext(tempContext, reason: reason)

            if success && shouldBackup {
                performBackup(reason: reason)
            }

            return success
        }
    }

    @discardableResult
    func saveFromUIContext(
        _ context: ModelContext,
        reason: String
    ) -> Bool {
        print("")
        print("╔════════════════════════════════════════════════════════╗")
        print("💾 SAVE FROM UI CONTEXT")
        print("Reason: \(reason)")
        print("╚════════════════════════════════════════════════════════╝")

        if mainModelContext == nil {
            mainModelContext = context
            print("🔗 Auto-registered UI context")
        }

        return saveContext(context, reason: reason)
    }

    /// Internal method to save a context
    /// This is the ONLY method that performs actual saves
    private func saveContext(
        _ context: ModelContext,
        reason: String
    ) -> Bool {
        saveLock.lock()
        defer { saveLock.unlock() }

        DispatchQueue.main.async {
            self.isSaving = true
        }

        defer {
            DispatchQueue.main.async {
                self.isSaving = false
                self.lastSaveTime = Date()
            }
        }

        if !context.hasChanges {
            print("ℹ️  No changes to save for: \(reason)")
            return true
        }

        do {
            try context.save()
            print("✅ SaveManager: \(reason) successful")

            requestDatabaseCheckpoint()

            DispatchQueue.main.async {
                self.saveError = nil
            }

            return true

        } catch {
            let errorMsg = error.localizedDescription
            print("❌ SaveManager save error (\(reason)): \(errorMsg)")

            DispatchQueue.main.async {
                self.saveError = errorMsg
            }

            return false
        }
    }

    private func requestDatabaseCheckpoint() {
        if let dbPath = getDatabasePath() {
            DispatchQueue.global(qos: .utility).async {
                _ = SQLiteHelper.checkpointDatabase(at: dbPath)
            }
        }
    }

    private func performBackup(reason: String) {
        print("📦 Starting backup: \(reason)")

        DispatchQueue.global(qos: .userInitiated).async {
            let backupURL = self.backupCallback?(reason)

            DispatchQueue.main.async {
                if backupURL != nil {
                    print("✅ Backup created successfully")
                    self.lastBackupTime = Date()
                } else {
                    print("❌ Backup failed")
                }
            }
        }
    }

    private func getDatabasePath() -> URL? {
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }

        let bundleID = "com.sebastienroland.Resume-ATS"
        let dbPath =
            appSupport
            .appendingPathComponent(bundleID)
            .appendingPathComponent("default.store")

        if FileManager.default.fileExists(atPath: dbPath.path) {
            return dbPath
        }

        return nil
    }

    func isDataAtRisk() -> Bool {
        guard let lastSave = lastSaveTime else {
            return true
        }
        return Date().timeIntervalSince(lastSave) > 300
    }

    deinit {
        stopAutoSave()
        stopAutoBackup()
    }
}
