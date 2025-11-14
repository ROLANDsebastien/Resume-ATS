//
//  AutoSaveService.swift
//  Resume-ATS
//
//  Created to ensure automatic periodic saving and prevent data loss
//

import Combine
import Foundation
import SwiftData

/// Centralized service to handle automatic saving of data
/// This prevents data loss by ensuring regular saves even if the app crashes
class AutoSaveService: ObservableObject {
    static let shared = AutoSaveService()

    @Published var isAutoSaveEnabled: Bool = true
    @Published var lastAutoSaveTime: Date?
    @Published var autoSaveInterval: TimeInterval = 180.0  // 3 minutes by default

    private var autoSaveTimer: Timer?
    private var modelContainer: ModelContainer?
    private let saveQueue = DispatchQueue(label: "com.resumeats.autosave", qos: .utility)
    private var isSaving = false
    private let saveLock = NSLock()

    private init() {
        print("🔄 AutoSaveService initialisé")
    }

    /// Configure the auto-save service with a model container
    /// - Parameter container: The SwiftData ModelContainer to use for saving
    func configure(with container: ModelContainer) {
        self.modelContainer = container
        print("✅ AutoSaveService configuré avec ModelContainer")
    }

    /// Start the automatic save timer
    func startAutoSave() {
        guard isAutoSaveEnabled else {
            print("⏰ AutoSave désactivé - pas de démarrage du timer")
            return
        }

        stopAutoSave()  // Stop any existing timer

        print("⏰ Démarrage AutoSave timer (intervalle: \(Int(autoSaveInterval))s)")

        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) {
            [weak self] _ in
            self?.performAutoSave()
        }

        // Ensure timer runs even when UI is not updating
        if let timer = autoSaveTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    /// Stop the automatic save timer
    func stopAutoSave() {
        if let timer = autoSaveTimer {
            timer.invalidate()
            autoSaveTimer = nil
            print("⏰ AutoSave timer arrêté")
        }
    }

    /// Perform an automatic save
    private func performAutoSave() {
        // Check if already saving
        saveLock.lock()
        if isSaving {
            print("⚠️ AutoSave déjà en cours - ignoré")
            saveLock.unlock()
            return
        }
        isSaving = true
        saveLock.unlock()

        defer {
            saveLock.lock()
            isSaving = false
            saveLock.unlock()
        }

        guard let container = modelContainer else {
            print("❌ AutoSave: Pas de ModelContainer configuré")
            return
        }

        print("")
        print("═══════════════════════════════════════════════════════════")
        print("⏰ AUTO-SAVE PÉRIODIQUE")
        print("═══════════════════════════════════════════════════════════")

        let context = ModelContext(container)

        if context.hasChanges {
            do {
                try context.save()

                DispatchQueue.main.async {
                    self.lastAutoSaveTime = Date()
                }

                print("✅ AutoSave réussi")
                print("   Heure: \(Date().formatted(date: .omitted, time: .standard))")

                // Force SQLite checkpoint to ensure data is written to disk
                if let dbPath = getDatabasePath() {
                    saveQueue.async {
                        if SQLiteHelper.checkpointDatabase(at: dbPath) {
                            print("   ✅ Checkpoint SQLite effectué")
                        }
                    }
                }

            } catch {
                print("❌ ERREUR AutoSave: \(error)")
                print("   Type: \(type(of: error))")

                // Try to diagnose the issue
                if let nsError = error as NSError? {
                    print("   Code: \(nsError.code)")
                    print("   Domain: \(nsError.domain)")
                    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                        print("   Underlying: \(underlyingError.localizedDescription)")
                    }
                }
            }
        } else {
            print("ℹ️  AutoSave: Pas de changements à sauvegarder")
        }

        print("═══════════════════════════════════════════════════════════")
        print("")
    }

    /// Force an immediate save (synchronous)
    /// - Parameter reason: Reason for the forced save (for logging)
    /// - Returns: True if save succeeded, false otherwise
    @discardableResult
    func forceSave(reason: String) -> Bool {
        guard let container = modelContainer else {
            print("❌ ForceSave: Pas de ModelContainer configuré")
            return false
        }

        print("")
        print("═══════════════════════════════════════════════════════════")
        print("💾 FORCE SAVE: \(reason)")
        print("═══════════════════════════════════════════════════════════")

        let context = ModelContext(container)

        if context.hasChanges {
            do {
                try context.save()
                print("✅ ForceSave réussi")

                DispatchQueue.main.async {
                    self.lastAutoSaveTime = Date()
                }

                // Checkpoint immediately for critical saves
                if let dbPath = getDatabasePath() {
                    _ = SQLiteHelper.checkpointDatabase(at: dbPath)
                }

                print("═══════════════════════════════════════════════════════════")
                print("")
                return true

            } catch {
                print("❌ ERREUR ForceSave: \(error)")
                print("═══════════════════════════════════════════════════════════")
                print("")
                return false
            }
        } else {
            print("ℹ️  Pas de changements à sauvegarder")
            print("═══════════════════════════════════════════════════════════")
            print("")
            return true
        }
    }

    /// Get database path
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
        let dbPath = appSupport.appendingPathComponent(bundleID)
            .appendingPathComponent("default.store")

        if FileManager.default.fileExists(atPath: dbPath.path) {
            return dbPath
        }

        let fallbackPath = appSupport.appendingPathComponent("default.store")
        if FileManager.default.fileExists(atPath: fallbackPath.path) {
            return fallbackPath
        }

        return nil
    }

    /// Get time since last auto-save
    func timeSinceLastSave() -> TimeInterval? {
        guard let lastSave = lastAutoSaveTime else {
            return nil
        }
        return Date().timeIntervalSince(lastSave)
    }

    /// Check if data is at risk (no save in a long time)
    func isDataAtRisk() -> Bool {
        guard let timeSince = timeSinceLastSave() else {
            return false
        }
        // Data is at risk if no save in more than 10 minutes
        return timeSince > 600
    }

    deinit {
        stopAutoSave()
        print("🔄 AutoSaveService déinitialisé")
    }
}
