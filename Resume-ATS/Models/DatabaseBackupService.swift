//
//  DatabaseBackupService.swift
//  Resume-ATS
//
//  Created to provide automated backup functionality
//

import Foundation
import SwiftData
import Combine

/// Service to provide automated database backup functionality
/// This replaces the removed DatabaseVersioningService to prevent data loss
class DatabaseBackupService: ObservableObject {
    static let shared = DatabaseBackupService()
    
    let objectWillChange = ObservableObjectPublisher()
    
    private let fileManager = FileManager.default
    private let backupDirectoryName = "ResumeATS_Backups"
    private let maxBackups = 5  // Keep maximum 5 backups
    
    private var backupDirectory: URL? {
        guard let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        return appSupport.appendingPathComponent(backupDirectoryName)
    }
    
    private init() {
        // Ensure backup directory exists
        if let backupDir = backupDirectory {
            try? fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
        }
    }
    
    /// Creates a backup of the current database
    func createBackup(reason: String = "Manual backup") -> URL? {
        guard let backupDir = backupDirectory else {
            print("❌ Backup: Impossible d'accéder au répertoire de backup")
            return nil
        }
        
        // Get the main database location
        guard let dbPath = getDatabasePath() else {
            print("❌ Backup: Impossible de localiser la base de données")
            return nil
        }
        
        guard fileManager.fileExists(atPath: dbPath.path) else {
            print("⚠️  Backup: Fichier de base de données non trouvé: \(dbPath.path)")
            return nil
        }
        
        // Create unique backup name with timestamp
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withTimeZone]
        let timestamp = dateFormatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupFileName = "db_backup_\(timestamp).store"
        let backupURL = backupDir.appendingPathComponent(backupFileName)
        
        do {
            try fileManager.copyItem(at: dbPath, to: backupURL)
            
            // Also backup related files (.wal, .shm)
            backupRelatedFiles(originalPath: dbPath, backupDir: backupDir, timestamp: timestamp)
            
            print("✅ Backup créé: \(backupFileName)")
            print("   Raison: \(reason)")
            print("   Chemin: \(backupURL.path)")
            
            // Clean up old backups
            cleanupOldBackups()
            
            return backupURL
        } catch {
            print("❌ Échec de la création du backup: \(error)")
            return nil
        }
    }
    
    /// Gets the path to the main SwiftData database
    private func getDatabasePath() -> URL? {
        guard let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        
        // Look for the main database file
        let bundleID = "com.sebastienroland.Resume-ATS"
        let dbPath = appSupport.appendingPathComponent(bundleID).appendingPathComponent("default.store")
        
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
    private func backupRelatedFiles(originalPath: URL, backupDir: URL, timestamp: String) {
        let relatedExtensions = ["-wal", "-shm"]
        
        for ext in relatedExtensions {
            let relatedPath = URL(fileURLWithPath: originalPath.path + ext)
            if fileManager.fileExists(atPath: relatedPath.path) {
                let backupRelatedPath = backupDir.appendingPathComponent("db_backup_\(timestamp)\(ext)")
                do {
                    try fileManager.copyItem(at: relatedPath, to: backupRelatedPath)
                    print("   Copié fichier associé: \(relatedPath.lastPathComponent)")
                } catch {
                    print("   ⚠️  Échec copie fichier associé \(relatedPath.lastPathComponent): \(error)")
                }
            }
        }
    }
    
    /// Removes old backups beyond the limit
    private func cleanupOldBackups() {
        guard let backupDir = backupDirectory else { return }
        
        do {
            let backupFiles = try fileManager.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "store" }
            
            // Sort by creation date, newest first
            let sortedBackups = backupFiles.sorted { url1, url2 in
                do {
                    let values1 = try url1.resourceValues(forKeys: [.creationDateKey])
                    let values2 = try url2.resourceValues(forKeys: [.creationDateKey])
                    return (values1.creationDate ?? Date.distantPast) > (values2.creationDate ?? Date.distantPast)
                } catch {
                    return true
                }
            }
            
            // Only remove if we have more than the maximum allowed
            if sortedBackups.count > maxBackups {
                let filesToRemove = Array(sortedBackups.suffix(from: maxBackups))
                for backupFile in filesToRemove {
                    try fileManager.removeItem(at: backupFile)
                    print("🗑️  Backup ancien supprimé: \(backupFile.lastPathComponent)")
                }
            }
        } catch {
            print("⚠️  Erreur lors du nettoyage des anciens backups: \(error)")
        }
    }
    
    /// Restores from a specific backup
    func restoreFromBackup(backupURL: URL) throws {
        guard let dbPath = getDatabasePath() else {
            throw NSError(
                domain: "DatabaseBackupService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Impossible de localiser la base de données"]
            )
        }
        
        // Backup current database before restoring
        _ = createBackup(reason: "Backup before restore")
        
        // Remove current database files
        let relatedExtensions = ["", "-wal", "-shm"]
        for ext in relatedExtensions {
            let filePath = URL(fileURLWithPath: dbPath.path + ext)
            if fileManager.fileExists(atPath: filePath.path) {
                try? fileManager.removeItem(at: filePath)
            }
        }
        
        // Restore from backup
        let backupStorePath = backupURL
        let restorePath = dbPath
        
        try fileManager.copyItem(at: backupStorePath, to: restorePath)
        
        // Restore related files if they exist
        let backupBaseName = backupURL.deletingPathExtension().lastPathComponent
        let backupDir = backupURL.deletingLastPathComponent()
        
        for ext in ["-wal", "-shm"] {
            let relatedBackupPath = backupDir.appendingPathComponent(backupBaseName + ext)
            if fileManager.fileExists(atPath: relatedBackupPath.path) {
                let restoreRelatedPath = dbPath.deletingPathExtension().appendingPathComponent(ext)
                try? fileManager.copyItem(at: relatedBackupPath, to: restoreRelatedPath)
            }
        }
        
        print("✅ Base de données restaurée depuis: \(backupURL.lastPathComponent)")
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
                    return (values1.creationDate ?? Date.distantPast) > (values2.creationDate ?? Date.distantPast)
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
                print("⚠️  Erreur lors de la lecture de la taille du backup: \(backup.lastPathComponent)")
            }
        }
        
        return totalSize
    }
}