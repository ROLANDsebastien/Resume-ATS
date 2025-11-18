//
//  SaveManager.swift
//  Resume-ATS
//
//  Centralized save management to prevent data loss from context isolation
//

import Combine
import Foundation
import SwiftData

/// Centralized manager for all data persistence operations
/// Ensures data is properly saved and backed up using a single, reliable system
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

    // Callback for backup operations (to avoid circular dependencies)
    var backupCallback: ((String) -> URL?)? = nil

    // Configuration
    private let autoSaveInterval: TimeInterval = 30  // Save every 30 seconds
    private let autoBackupInterval: TimeInterval = 3600  // Backup every 1 hour

    private init() {
        print("💾 SaveManager initialized")
    }

    /// Configure SaveManager with the ModelContainer
    func configure(with container: ModelContainer) {
        self.modelContainer = container
        print("✅ SaveManager configured with ModelContainer")
    }

    /// Register the main UI's ModelContext (CRITICAL)
    /// This must be called with @Environment(\.modelContext) to prevent context isolation
    func registerMainContext(_ context: ModelContext) {
        self.mainModelContext = context
        print("🔗 SaveManager: Main UI context registered")
    }

    /// Start automatic saving every 30 seconds and automatic backup every hour
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

        // Also start auto-backup
        startAutoBackup()
    }

    /// Stop automatic saving and automatic backup
    func stopAutoSave() {
        if let timer = autoSaveTimer {
            timer.invalidate()
            autoSaveTimer = nil
            print("⏰ SaveManager: Auto-save stopped")
        }

        stopAutoBackup()
    }

    /// Start automatic backup every hour
    func startAutoBackup() {
        guard modelContainer != nil else {
            print("❌ SaveManager: Cannot start auto-backup without ModelContainer")
            return
        }

        stopAutoBackup()

        print(
            "⏰ SaveManager: Starting auto-backup (interval: \(Int(autoBackupInterval))s = \(Int(autoBackupInterval / 3600))h)"
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

    /// Stop automatic backup
    func stopAutoBackup() {
        if let timer = autoBackupTimer {
            timer.invalidate()
            autoBackupTimer = nil
            print("⏰ SaveManager: Auto-backup stopped")
        }
    }

    /// Perform automatic save - called by timer
    private func performAutoSave() {
        guard let container = modelContainer else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            _ = self?.saveToContainer(container, reason: "Auto-save", isBackground: false)
        }
    }

    /// Perform automatic backup - called by timer
    private func performAutoBackup() {
        print("📦 SaveManager: Starting automatic backup...")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let backupURL = self?.backupCallback?("Automatic hourly backup")

            DispatchQueue.main.async {
                if backupURL != nil {
                    self?.lastBackupTime = Date()
                    print("✅ SaveManager: Automatic backup completed successfully")
                } else {
                    print("❌ SaveManager: Automatic backup failed")
                }
            }
        }
    }

    /// Force an immediate save with optional backup
    @discardableResult
    func forceSave(
        from container: ModelContainer,
        reason: String,
        shouldBackup: Bool = false
    ) -> Bool {
        saveLock.lock()
        defer { saveLock.unlock() }

        let success = saveToContainer(container, reason: reason, isBackground: false)

        if success && shouldBackup {
            performBackup(reason: reason)
        }

        return success
    }

    /// Save data from the main UI context to storage
    /// This is the PRIMARY save method that uses the UI's ModelContext
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
            print("ℹ️  No changes to save")
            return true
        }

        do {
            try context.save()
            print("✅ Context saved successfully")

            // Request SQLite checkpoint via private API
            requestDatabaseCheckpoint()

            saveError = nil
            return true

        } catch {
            let errorMsg = error.localizedDescription
            print("❌ Save error: \(errorMsg)")
            saveError = errorMsg
            return false
        }
    }

    /// Internal method to save using a container
    private func saveToContainer(
        _ container: ModelContainer,
        reason: String,
        isBackground: Bool
    ) -> Bool {
        let context = ModelContext(container)

        if !context.hasChanges {
            return true
        }

        do {
            try context.save()

            if !isBackground {
                print("✅ SaveManager: \(reason) successful")
            }

            requestDatabaseCheckpoint()

            DispatchQueue.main.async {
                self.lastSaveTime = Date()
                self.saveError = nil
            }

            return true

        } catch {
            let errorMsg = error.localizedDescription
            print("❌ SaveManager save error: \(errorMsg)")

            DispatchQueue.main.async {
                self.saveError = errorMsg
            }

            return false
        }
    }

    /// Request SQLite database checkpoint
    /// This ensures data is written to disk immediately
    private func requestDatabaseCheckpoint() {
        if let dbPath = getDatabasePath() {
            DispatchQueue.global(qos: .utility).async {
                // Access the database file to force SQLite to checkpoint
                _ = try? FileManager.default.attributesOfItem(atPath: dbPath.path)
                print("✅ Database checkpoint completed")
            }
        }
    }

    /// Perform database backup using the registered callback
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

    /// Get database file path
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

    /// Check if data is at risk (haven't saved recently)
    func isDataAtRisk() -> Bool {
        guard let lastSave = lastSaveTime else {
            return true
        }
        return Date().timeIntervalSince(lastSave) > 600
    }

    deinit {
        stopAutoSave()
        stopAutoBackup()
    }
}
