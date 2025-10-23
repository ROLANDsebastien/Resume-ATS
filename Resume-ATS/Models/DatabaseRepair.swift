//
//  DatabaseRepair.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 19/10/2025.
//

import Foundation
import SwiftData

/// Utility class to help recover and migrate database data
class DatabaseRepair {

    /// Attempts to recover data from corrupted or incompatible database
    static func attemptRecovery() {
        print("🔧 Tentative de récupération de la base de données...")

        let fileManager = FileManager.default
        let storeURL = getStoreURL()

        print("📁 Emplacement de la base de données:")
        print("   \(storeURL.path)")

        // Check if store exists
        if fileManager.fileExists(atPath: storeURL.path) {
            print("✅ Fichier de base trouvé")

            do {
                let attributes = try fileManager.attributesOfItem(atPath: storeURL.path)
                let fileSize = attributes[FileAttributeKey.size] as? Int ?? 0
                print("📊 Taille: \(formatBytes(fileSize))")
            } catch {
                print("⚠️  Impossible de lire les attributs du fichier")
            }
        } else {
            print("❌ Fichier de base non trouvé - la base sera créée au prochain démarrage")
        }

        // Check associated files
        let walURL = URL(fileURLWithPath: storeURL.path + "-wal")
        let shmURL = URL(fileURLWithPath: storeURL.path + "-shm")

        if fileManager.fileExists(atPath: walURL.path) {
            print("✅ Fichier WAL (Write-Ahead Log) trouvé")
        }

        if fileManager.fileExists(atPath: shmURL.path) {
            print("✅ Fichier SHM (Shared Memory) trouvé")
        }
    }

    /// Creates a backup of the current database
    static func createBackup() -> URL? {
        print("💾 Création d'une sauvegarde de la base de données...")

        let fileManager = FileManager.default
        let storeURL = getStoreURL()

        guard fileManager.fileExists(atPath: storeURL.path) else {
            print("❌ Impossible de créer une sauvegarde - fichier non trouvé")
            return nil
        }

        let backupDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Resume-ATS Backups")

        do {
            try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())

            let backupURL = backupDir.appendingPathComponent("database_backup_\(timestamp).store")

            try fileManager.copyItem(at: storeURL, to: backupURL)
            print("✅ Sauvegarde créée: \(backupURL.lastPathComponent)")
            return backupURL

        } catch {
            print("❌ Erreur lors de la création de la sauvegarde: \(error)")
            return nil
        }
    }

    /// Attempts to delete corrupted database and start fresh
    static func resetDatabase(backup: Bool = true) {
        print("🔄 Réinitialisation de la base de données...")

        if backup {
            if let backupURL = createBackup() {
                print("📦 Sauvegarde effectuée: \(backupURL.path)")
            }
        }

        let fileManager = FileManager.default
        let storeURL = getStoreURL()

        let filesToDelete = [
            storeURL.path,
            storeURL.path + "-wal",
            storeURL.path + "-shm",
        ]

        for filePath in filesToDelete {
            do {
                if fileManager.fileExists(atPath: filePath) {
                    try fileManager.removeItem(atPath: filePath)
                    print("✅ Supprimé: \(URL(fileURLWithPath: filePath).lastPathComponent)")
                }
            } catch {
                print("⚠️  Impossible de supprimer \(filePath): \(error)")
            }
        }

        print("✅ Base de données réinitialisée")
        print("   Une nouvelle base sera créée au prochain démarrage")
    }

    /// Gets the URL where SwiftData stores the database
    static func getStoreURL() -> URL {
        let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return appSupportURL.appendingPathComponent("default.store")
    }

    /// Checks database integrity
    static func checkIntegrity() -> Bool {
        print("🔍 Vérification de l'intégrité de la base de données...")

        let fileManager = FileManager.default
        let storeURL = getStoreURL()

        guard fileManager.fileExists(atPath: storeURL.path) else {
            print("⚠️  Fichier de base non trouvé")
            return false
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: storeURL.path)

            if let fileSize = attributes[FileAttributeKey.size] as? Int {
                if fileSize == 0 {
                    print("❌ Base de données vide (0 bytes)")
                    return false
                }

                if fileSize < 1024 {
                    print("⚠️  Base de données très petite (\(fileSize) bytes)")
                }

                print("✅ Fichier trouvé et non vide (\(formatBytes(fileSize)))")
                return true
            }
        } catch {
            print("❌ Erreur lors de la vérification: \(error)")
            return false
        }

        return true
    }

    /// Formats bytes into human-readable format
    private static func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Logs all database information
    static func logDatabaseInfo() {
        print("")
        print("╔════════════════════════════════════════════════════════════╗")
        print("║           📊 INFORMATIONS DE LA BASE DE DONNÉES          ║")
        print("╚════════════════════════════════════════════════════════════╝")
        print("")

        let storeURL = getStoreURL()
        let fileManager = FileManager.default

        print("📁 Emplacements des fichiers:")
        print("   Store: \(storeURL.path)")
        print("   WAL:   \(storeURL.path)-wal")
        print("   SHM:   \(storeURL.path)-shm")
        print("")

        print("📋 État des fichiers:")
        let files = [
            ("Store", storeURL.path),
            ("WAL", storeURL.path + "-wal"),
            ("SHM", storeURL.path + "-shm"),
        ]

        for (name, path) in files {
            if fileManager.fileExists(atPath: path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: path)
                    if let size = attributes[FileAttributeKey.size] as? Int {
                        print("   ✅ \(name): \(formatBytes(size))")
                    }
                } catch {
                    print("   ⚠️  \(name): Impossible de lire les propriétés")
                }
            } else {
                print("   ❌ \(name): Non trouvé")
            }
        }

        print("")
        _ = checkIntegrity()
        print("")
    }
}
