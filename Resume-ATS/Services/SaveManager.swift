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
    private let autoBackupInterval: TimeInterval = 3600  // Backup every hour

    private init() {
        print("💾 SaveManager initialized")
    }

    /// Configure SaveManager with the ModelContainer
    func configure(with container: ModelContainer) {
        self.modelContainer = container
        print("✅ SaveManager configured with ModelContainer")
    }

    /// Register the main UI's ModelContext (CRITICAL - MUST BE CALLED)
    /// This is the ONLY context that should be used for saving
    func registerMainContext(_ context: ModelContext) {
        self.mainModelContext = context
        print("🔗 SaveManager: Main UI context registered")
    }

    /// Start automatic saving every 30 seconds
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

    /// Stop automatic saving and backup
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

    /// Stop automatic backup
    func stopAutoBackup() {
        if let timer = autoBackupTimer {
            timer.invalidate()
            autoBackupTimer = nil
            print("⏰ SaveManager: Auto-backup stopped")
        }
    }

    /// Perform automatic save - called by timer
    /// CRITICAL: Uses the registered UI context, NOT a new context
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

    /// Perform automatic backup - called by timer
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

    /// Force an immediate save from UI context with optional backup
    /// This is the PRIMARY method for saving during app lifecycle events
    @discardableResult
    func forceSave(
        from container: ModelContainer,
        reason: String,
        shouldBackup: Bool = false
    ) -> Bool {
        // Try to use the registered UI context first
        if let context = mainModelContext {
            let success = saveContext(context, reason: reason)

            if success && shouldBackup {
                performBackup(reason: reason)
            }

            return success
        } else {
            // Fallback: create a temporary context (less ideal but safer than data loss)
            print("⚠️  SaveManager: Using fallback context (UI context not registered)")
            let tempContext = ModelContext(container)
            let success = saveContext(tempContext, reason: reason)

            if success && shouldBackup {
                performBackup(reason: reason)
            }

            return success
        }
    }

    /// Save data from the UI context
    /// CRITICAL: This MUST use the UI's ModelContext to prevent data loss
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

        // Register this context if not already registered
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

            // Request SQLite checkpoint
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

    /// Request SQLite database checkpoint
    /// This ensures data is written to disk immediately
    private func requestDatabaseCheckpoint() {
        if let dbPath = getDatabasePath() {
            DispatchQueue.global(qos: .utility).async {
                // Use SQLiteHelper to perform a proper WAL checkpoint
                // This merges the WAL file into the main database file
                _ = SQLiteHelper.checkpointDatabase(at: dbPath)
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
        return Date().timeIntervalSince(lastSave) > 300  // 5 minutes
    }

    deinit {
        stopAutoSave()
        stopAutoBackup()
    }
}
