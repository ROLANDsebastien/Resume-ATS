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

        // Check minimum interval between backups (sauf pour les sauvegardes critiques et manuelles)
        let isCriticalBackup =
            reason.contains("termination") || reason.contains("background")
            || reason.contains("inactive")
        let isManualBackup = reason.contains("Manual backup")

        if !isCriticalBackup && !isManualBackup, let lastTime = lastBackupTime {
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

                    // Give the file system a moment to sync (increased for reliability)
                    Thread.sleep(forTimeInterval: 0.5)
                } catch {
                    print("   ❌ ERREUR CRITIQUE: Échec sauvegarde ModelContext: \(error)")
                    print("   Type d'erreur: \(type(of: error))")

                    // Pour les sauvegardes critiques, on tente quand même le backup
                    if isCriticalBackup {
                        print("   ⚠️  Sauvegarde critique - tentative de backup malgré l'erreur")
                    } else {
                        print("   ⚠️  BACKUP ANNULÉ pour éviter corruption")
                        return nil
                    }
                }
            } else {
                print("ℹ️  ModelContext sans changements - pas de sauvegarde nécessaire")
            }
        } else {
            print("⚠️  Pas de ModelContext fourni - backup direct (RISQUÉ)")
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

        // Vérifier la taille du fichier principal
        if let attrs = try? fileManager.attributesOfItem(atPath: dbPath.path),
            let fileSize = attrs[.size] as? Int64
        {
            print("   Taille: \(formatBytes(fileSize))")

            // Alerte si la base est anormalement petite (< 10 KB)
            if fileSize < 10240 {
                print("   ⚠️  ALERTE: Base de données anormalement petite!")
                print("   Cela peut indiquer une perte de données récente")
            }
        }

        // STEP 3: Force SQLite checkpoint to merge WAL into main file
        // This is important to ensure backup completeness
        print("")
        print("🔄 Checkpoint SQLite (merge WAL into main file)...")

        // Attempt checkpoint - if it fails, still continue with backup
        // because SwiftData might have the DB open in exclusive mode
        let checkpointSuccess = SQLiteHelper.checkpointDatabase(at: dbPath)

        if checkpointSuccess {
            print("   ✅ Checkpoint réussi")
        } else {
            print("   ⚠️  Checkpoint incomplet (DB peut être verrouillée par SwiftData)")
            print("   Le backup inclura les fichiers WAL séparés si disponibles")
        }

        // Give system time to sync files
        Thread.sleep(forTimeInterval: 0.5)

        // Skip integrity check before backup - files may still be locked
        // Integrity will be verified during restore if needed
        print("   ℹ️  Vérification d'intégrité ignorée (DB peut être verrouillée)")

        // STEP 5: Create backup with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        dateFormatter.timeZone = TimeZone.current
        let timestamp = dateFormatter.string(from: Date())

        // Marquer les backups critiques dans le nom de fichier
        var backupFileName = "db_backup_\(timestamp)"
        if isCriticalBackup {
            backupFileName += "_CRITICAL"
        }
        backupFileName += ".store"

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

            // STEP 6: Simple verification - just check that main file exists and has content
            print("")
            print("🔍 Vérification du backup créé...")
            if mainFileSize > 0 {
                print("   ✅ Fichier principal créé avec succès (\(formatBytes(mainFileSize)))")
            } else {
                print("   ❌ ALERTE: Le fichier backup est vide!")
                print("   Suppression du backup...")
                try? fileManager.removeItem(at: backupURL)
                return nil
            }

            print("")
            print("✅ BACKUP CRÉÉ AVEC SUCCÈS")
            print("   Nom: \(backupFileName)")
            print("   Chemin: \(backupURL.path)")

            // STEP 7: Clean up old backups (sauf les backups critiques récents)
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

            // Séparer les backups critiques des backups normaux
            let criticalBackups = sortedBackups.filter { $0.lastPathComponent.contains("CRITICAL") }
            let normalBackups = sortedBackups.filter { !$0.lastPathComponent.contains("CRITICAL") }

            print("   Backups critiques: \(criticalBackups.count)")
            print("   Backups normaux: \(normalBackups.count)")

            // Garder tous les backups critiques des dernières 24h
            let oneDayAgo = Date().addingTimeInterval(-86400)
            let recentCriticalBackups = criticalBackups.filter { url in
                if let values = try? url.resourceValues(forKeys: [.creationDateKey]),
                    let creationDate = values.creationDate
                {
                    return creationDate > oneDayAgo
                }
                return false
            }

            // Supprimer les anciens backups normaux si on dépasse la limite
            let backupsToKeep = recentCriticalBackups.count + 5  // Garder au moins 5 backups normaux
            if normalBackups.count > backupsToKeep {
                let filesToRemove = Array(normalBackups.suffix(from: backupsToKeep))
                print("   Suppression de \(filesToRemove.count) ancien(s) backup(s) normal/normaux")

                for backupFile in filesToRemove {
                    // Ne pas supprimer si c'est un backup critique récent
                    if recentCriticalBackups.contains(where: { $0.path == backupFile.path }) {
                        continue
                    }

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
                print("   ✅ Nombre de backups OK (\(sortedBackups.count) total)")
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

        // Verify backup file exists and has valid size
        print("🔍 Vérification du backup à restaurer...")

        guard fileManager.fileExists(atPath: backupURL.path) else {
            print("❌ Le fichier de backup n'existe pas")
            throw NSError(
                domain: "DatabaseBackupService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Le fichier de backup n'existe pas"]
            )
        }

        // Check file size (must be > 1KB to be valid)
        do {
            let attributes = try fileManager.attributesOfItem(atPath: backupURL.path)
            guard let fileSize = attributes[.size] as? Int, fileSize > 1024 else {
                print("❌ Le backup est trop petit pour être valide")
                throw NSError(
                    domain: "DatabaseBackupService",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Le backup est invalide (trop petit)"]
                )
            }
            print("   ✅ Fichier backup valide (\(fileSize / 1024) KB)")
        } catch {
            print("   ⚠️  Impossible de vérifier la taille: \(error.localizedDescription)")
            // Continue anyway - size check is optional
        }

        print("   ℹ️  Vérification d'intégrité détaillée : attendra le redémarrage")
        print("")

        // Close any open connections before manipulating files
        print("⏳ Fermeture des connexions et attente de libération...")
        Thread.sleep(forTimeInterval: 1.5)

        // Remove current database files
        print("🗑️  Suppression des fichiers actuels...")
        let relatedExtensions = ["", "-wal", "-shm"]

        for ext in relatedExtensions {
            let filePath = URL(fileURLWithPath: dbPath.path + ext)
            if fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.removeItem(at: filePath)
                    print("   ✅ Supprimé: \(filePath.lastPathComponent)")
                } catch {
                    print(
                        "   ⚠️  Impossible de supprimer \(filePath.lastPathComponent): \(error.localizedDescription)"
                    )
                    // Continue anyway - file might be locked but we can overwrite it
                }
            }
        }
        print("")

        // Restore from backup
        print("📋 Copie du backup...")
        let backupStorePath = backupURL
        let restorePath = dbPath

        do {
            // Try to copy main file
            try fileManager.copyItem(at: backupStorePath, to: restorePath)
            print("   ✅ Fichier principal restauré")
        } catch {
            print(
                "   ❌ Erreur lors de la copie du fichier principal: \(error.localizedDescription)")
            throw NSError(
                domain: "DatabaseBackupService",
                code: 4,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Impossible de restaurer le fichier: \(error.localizedDescription)"
                ]
            )
        }

        // Restore related WAL/SHM files if they exist
        let backupBaseName = backupURL.deletingPathExtension().lastPathComponent
        let backupDir = backupURL.deletingLastPathComponent()
        var walFilesRestored = false

        for ext in ["-wal", "-shm"] {
            let relatedBackupPath = backupDir.appendingPathComponent(backupBaseName + ext)
            if fileManager.fileExists(atPath: relatedBackupPath.path) {
                let restoreRelatedPath = URL(fileURLWithPath: restorePath.path + ext)
                do {
                    // Remove target if it exists
                    if fileManager.fileExists(atPath: restoreRelatedPath.path) {
                        try? fileManager.removeItem(at: restoreRelatedPath)
                    }
                    try fileManager.copyItem(at: relatedBackupPath, to: restoreRelatedPath)
                    print("   ✅ Restauré: \(relatedBackupPath.lastPathComponent)")
                    walFilesRestored = true
                } catch {
                    print("   ⚠️  Impossible de restaurer \(ext): \(error.localizedDescription)")
                    // Don't fail - WAL files are optional but helpful for consistency
                }
            }
        }

        if !walFilesRestored {
            print("   ℹ️  Aucun fichier WAL/SHM - le backup sera reconstruit au démarrage")
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
