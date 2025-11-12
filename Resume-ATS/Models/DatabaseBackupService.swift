//
//  DatabaseBackupService.swift
//  Resume-ATS
//
//  Created to provide automated backup functionality with data corruption prevention
//

import Combine
import Foundation
import SwiftData

/// Service to provide automated database backup functionality with robust error handling
/// Prevents data loss through proper SQLite WAL checkpointing and concurrency control
class DatabaseBackupService: ObservableObject {
    static let shared = DatabaseBackupService()

    let objectWillChange = ObservableObjectPublisher()

    private let fileManager = FileManager.default
    private let backupDirectoryName = "ResumeATS_Backups"
    private let maxBackups = 10  // Keep maximum 10 backups for safety

    // Concurrency control to prevent simultaneous backups
    private let backupQueue = DispatchQueue(label: "com.resumeats.backup", qos: .utility)
    private var isBackupInProgress = false
    private let backupLock = NSLock()

    // Track last backup time to prevent too frequent backups
    private var lastBackupTime: Date?
    private let minimumBackupInterval: TimeInterval = 60  // Minimum 1 minute between backups

    private var backupDirectory: URL? {
        guard
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }
        return appSupport.appendingPathComponent(backupDirectoryName)
    }

    private init() {
        // Ensure backup directory exists
        if let backupDir = backupDirectory {
            try? fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
        }

        print("📦 DatabaseBackupService initialisé")
        if let backupDir = backupDirectory {
            print("   Dossier backups: \(backupDir.path)")
        }
    }

    /// Creates a backup of the current database with proper synchronization
    /// - Parameters:
    ///   - reason: Description of why the backup is being created
    ///   - modelContext: Optional ModelContext to save before backup
    /// - Returns: URL of the created backup, or nil if failed
    func createBackup(reason: String = "Manual backup", modelContext: ModelContext? = nil) -> URL? {
        // Check if backup is already in progress
        backupLock.lock()
        if isBackupInProgress {
            print("⚠️  Backup déjà en cours - requête ignorée")
            print("   Raison de la requête ignorée: \(reason)")
            backupLock.unlock()
            return nil
        }

        // Check minimum interval between backups
        if let lastTime = lastBackupTime {
            let timeSinceLastBackup = Date().timeIntervalSince(lastTime)
            if timeSinceLastBackup < minimumBackupInterval {
                print("⏱️  Backup trop récent (\(Int(timeSinceLastBackup))s) - ignoré")
                backupLock.unlock()
                return nil
            }
        }

        isBackupInProgress = true
        backupLock.unlock()

        defer {
            backupLock.lock()
            isBackupInProgress = false
            lastBackupTime = Date()
            backupLock.unlock()
        }

        print("")
        print("═══════════════════════════════════════════════════════════")
        print("📦 CRÉATION DE BACKUP")
        print("═══════════════════════════════════════════════════════════")
        print("Raison: \(reason)")
        print("Heure: \(Date().formatted(date: .abbreviated, time: .standard))")
        print("")

        // STEP 1: Save ModelContext if provided
        if let context = modelContext {
            if context.hasChanges {
                print("💾 Sauvegarde du ModelContext avant backup...")
                do {
                    try context.save()
                    print("   ✅ ModelContext sauvegardé")

                    // Give the file system a moment to sync
                    Thread.sleep(forTimeInterval: 0.3)
                } catch {
                    print("   ❌ Échec sauvegarde ModelContext: \(error)")
                    print("   ⚠️  BACKUP ANNULÉ pour éviter corruption")
                    return nil
                }
            } else {
                print("ℹ️  ModelContext sans changements - pas de sauvegarde nécessaire")
            }
        } else {
            print("ℹ️  Pas de ModelContext fourni - backup direct")
        }

        // STEP 2: Get database path
        guard let backupDir = backupDirectory else {
            print("❌ Impossible d'accéder au répertoire de backup")
            return nil
        }

        guard let dbPath = getDatabasePath() else {
            print("❌ Impossible de localiser la base de données")
            return nil
        }

        guard fileManager.fileExists(atPath: dbPath.path) else {
            print("❌ Fichier de base de données non trouvé: \(dbPath.path)")
            return nil
        }

        print("📍 Base de données localisée:")
        print("   \(dbPath.path)")

        // STEP 3: Verify database integrity BEFORE backup
        print("")
        if !SQLiteHelper.verifyDatabaseIntegrity(at: dbPath) {
            print("❌ CORRUPTION DÉTECTÉE - backup annulé")
            print("⚠️  ATTENTION: Votre base de données est corrompue!")
            print("   Vous devriez restaurer depuis un backup précédent")
            return nil
        }

        // STEP 4: Force SQLite checkpoint to merge WAL into main file
        print("")
        print("🔄 Checkpoint SQLite (merge WAL)...")
        if !SQLiteHelper.checkpointDatabase(at: dbPath) {
            print("❌ Checkpoint échoué - backup annulé pour éviter corruption")
            return nil
        }

        // Give SQLite a moment to complete the checkpoint
        Thread.sleep(forTimeInterval: 0.2)

        // STEP 5: Create backup with timestamp
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withTimeZone]
        let timestamp = dateFormatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupFileName = "db_backup_\(timestamp).store"
        let backupURL = backupDir.appendingPathComponent(backupFileName)

        print("")
        print("📋 Copie des fichiers de base de données...")

        do {
            // Copy main database file
            try fileManager.copyItem(at: dbPath, to: backupURL)
            print("   ✅ Copié: \(dbPath.lastPathComponent)")

            // Copy related files (WAL and SHM)
            // After checkpoint, WAL should be empty or very small
            let copiedFiles = backupRelatedFiles(
                originalPath: dbPath, backupDir: backupDir, timestamp: timestamp)

            // Get backup file sizes for verification
            let mainFileSize =
                (try? fileManager.attributesOfItem(atPath: backupURL.path)[.size] as? Int64) ?? 0
            print("")
            print("📊 Taille du backup:")
            print("   Fichier principal: \(formatBytes(mainFileSize))")

            if copiedFiles.contains("wal") {
                let walPath = backupDir.appendingPathComponent("db_backup_\(timestamp)-wal")
                let walSize =
                    (try? fileManager.attributesOfItem(atPath: walPath.path)[.size] as? Int64) ?? 0
                print("   WAL: \(formatBytes(walSize))")

                if walSize > 1024 * 100 {  // More than 100KB
                    print("   ⚠️  WAL volumineux - le checkpoint n'a peut-être pas tout mergé")
                }
            }

            print("")
            print("✅ BACKUP CRÉÉ AVEC SUCCÈS")
            print("   Nom: \(backupFileName)")
            print("   Chemin: \(backupURL.path)")

            // STEP 6: Clean up old backups
            print("")
            cleanupOldBackups()

            print("═══════════════════════════════════════════════════════════")
            print("")

            return backupURL

        } catch {
            print("❌ Échec de la création du backup: \(error)")
            print("   Type d'erreur: \(type(of: error))")

            // Clean up partial backup
            try? fileManager.removeItem(at: backupURL)

            return nil
        }
    }

    /// Gets the path to the main SwiftData database
    private func getDatabasePath() -> URL? {
        guard
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }

        // Look for the main database file
        let bundleID = "com.sebastienroland.Resume-ATS"
        let dbPath = appSupport.appendingPathComponent(bundleID).appendingPathComponent(
            "default.store")

        if fileManager.fileExists(atPath: dbPath.path) {
            return dbPath
        }

        // Fallback: direct path in Application Support
        let fallbackPath = appSupport.appendingPathComponent("default.store")
        if fileManager.fileExists(atPath: fallbackPath.path) {
            return fallbackPath
        }

        return nil
    }

    /// Backup related database files (.wal, .shm)
    /// - Returns: Array of extensions that were successfully backed up
    @discardableResult
    private func backupRelatedFiles(originalPath: URL, backupDir: URL, timestamp: String)
        -> [String]
    {
        let relatedExtensions = ["-wal", "-shm"]
        var copiedFiles: [String] = []

        for ext in relatedExtensions {
            let relatedPath = URL(fileURLWithPath: originalPath.path + ext)
            if fileManager.fileExists(atPath: relatedPath.path) {
                let backupRelatedPath = backupDir.appendingPathComponent(
                    "db_backup_\(timestamp)\(ext)")
                do {
                    try fileManager.copyItem(at: relatedPath, to: backupRelatedPath)
                    print("   ✅ Copié: \(relatedPath.lastPathComponent)")
                    copiedFiles.append(ext.replacingOccurrences(of: "-", with: ""))
                } catch {
                    print("   ⚠️  Échec copie \(relatedPath.lastPathComponent): \(error)")
                }
            }
        }

        return copiedFiles
    }

    /// Removes old backups beyond the limit
    private func cleanupOldBackups() {
        guard let backupDir = backupDirectory else { return }

        print("🧹 Nettoyage des anciens backups...")

        do {
            let backupFiles = try fileManager.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "store" }

            print("   Backups trouvés: \(backupFiles.count)")

            // Sort by creation date, newest first
            let sortedBackups = backupFiles.sorted { url1, url2 in
                do {
                    let values1 = try url1.resourceValues(forKeys: [.creationDateKey])
                    let values2 = try url2.resourceValues(forKeys: [.creationDateKey])
                    return (values1.creationDate ?? Date.distantPast)
                        > (values2.creationDate ?? Date.distantPast)
                } catch {
                    return true
                }
            }

            // Only remove if we have more than the maximum allowed
            if sortedBackups.count > maxBackups {
                let filesToRemove = Array(sortedBackups.suffix(from: maxBackups))
                print("   Suppression de \(filesToRemove.count) ancien(s) backup(s)")

                for backupFile in filesToRemove {
                    // Remove main backup file
                    try fileManager.removeItem(at: backupFile)

                    // Remove associated WAL and SHM files
                    let baseName = backupFile.deletingPathExtension().lastPathComponent
                    for ext in ["-wal", "-shm"] {
                        let relatedFile = backupDir.appendingPathComponent(baseName + ext)
                        if fileManager.fileExists(atPath: relatedFile.path) {
                            try? fileManager.removeItem(at: relatedFile)
                        }
                    }

                    print("   🗑️  Supprimé: \(backupFile.lastPathComponent)")
                }
            } else {
                print("   ✅ Nombre de backups OK (\(backupFiles.count)/\(maxBackups))")
            }
        } catch {
            print("   ⚠️  Erreur lors du nettoyage: \(error)")
        }
    }

    /// Restores from a specific backup
    /// WARNING: This will replace the current database!
    func restoreFromBackup(backupURL: URL) throws {
        print("")
        print("═══════════════════════════════════════════════════════════")
        print("🔄 RESTAURATION DE BACKUP")
        print("═══════════════════════════════════════════════════════════")
        print("Source: \(backupURL.lastPathComponent)")
        print("")

        guard let dbPath = getDatabasePath() else {
            throw NSError(
                domain: "DatabaseBackupService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Impossible de localiser la base de données"]
            )
        }

        // Verify backup integrity before restoring
        print("🔍 Vérification du backup à restaurer...")
        if !SQLiteHelper.verifyDatabaseIntegrity(at: backupURL) {
            print("❌ Le backup est corrompu - restauration annulée")
            throw NSError(
                domain: "DatabaseBackupService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Le backup sélectionné est corrompu"]
            )
        }
        print("   ✅ Backup valide")
        print("")

        // Backup current database before restoring
        print("💾 Sauvegarde de sécurité de la DB actuelle...")
        _ = createBackup(reason: "Backup before restore")
        print("")

        // Remove current database files
        print("🗑️  Suppression des fichiers actuels...")
        let relatedExtensions = ["", "-wal", "-shm"]
        for ext in relatedExtensions {
            let filePath = URL(fileURLWithPath: dbPath.path + ext)
            if fileManager.fileExists(atPath: filePath.path) {
                try? fileManager.removeItem(at: filePath)
                print("   Supprimé: \(filePath.lastPathComponent)")
            }
        }
        print("")

        // Restore from backup
        print("📋 Copie du backup...")
        let backupStorePath = backupURL
        let restorePath = dbPath

        try fileManager.copyItem(at: backupStorePath, to: restorePath)
        print("   ✅ Fichier principal restauré")

        // Restore related files if they exist
        let backupBaseName = backupURL.deletingPathExtension().lastPathComponent
        let backupDir = backupURL.deletingLastPathComponent()

        for ext in ["-wal", "-shm"] {
            let relatedBackupPath = backupDir.appendingPathComponent(backupBaseName + ext)
            if fileManager.fileExists(atPath: relatedBackupPath.path) {
                let restoreRelatedPath = URL(fileURLWithPath: restorePath.path + ext)
                try? fileManager.copyItem(at: relatedBackupPath, to: restoreRelatedPath)
                print("   ✅ Restauré: \(relatedBackupPath.lastPathComponent)")
            }
        }

        print("")
        print("✅ BASE DE DONNÉES RESTAURÉE AVEC SUCCÈS")
        print("   Vous devez REDÉMARRER l'application pour charger les données")
        print("═══════════════════════════════════════════════════════════")
        print("")
    }

    /// Lists available backups
    func listBackups() -> [URL] {
        guard let backupDir = backupDirectory else { return [] }

        do {
            return try fileManager.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "store" }
                .sorted { url1, url2 in
                    do {
                        let values1 = try url1.resourceValues(forKeys: [.creationDateKey])
                        let values2 = try url2.resourceValues(forKeys: [.creationDateKey])
                        return (values1.creationDate ?? Date.distantPast)
                            > (values2.creationDate ?? Date.distantPast)
                    } catch {
                        return true
                    }
                }
        } catch {
            print("⚠️  Erreur lors de la lecture des backups: \(error)")
            return []
        }
    }

    /// Gets total size of all backups
    func getTotalBackupSize() -> Int {
        let backups = listBackups()
        var totalSize = 0

        for backup in backups {
            do {
                let values = try backup.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = values.fileSize {
                    totalSize += fileSize
                }
            } catch {
                print("⚠️  Erreur lors de la lecture de la taille: \(backup.lastPathComponent)")
            }
        }

        return totalSize
    }

    /// Formats bytes into human-readable string
    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0

        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.2f KB", kb)
        } else {
            return "\(bytes) bytes"
        }
    }
}
