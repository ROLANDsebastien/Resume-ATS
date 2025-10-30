//
//  DatabaseVersioningService.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 28/09/2025.
//

import Foundation
import SwiftData

/// Service pour gérer les versions de la base de données
/// Crée des backups automatiques et permet de restaurer des versions antérieures
class DatabaseVersioningService {
    static let shared = DatabaseVersioningService()

    private let fileManager = FileManager.default
    private let versionsDirectoryName = "ResumeATS_DBVersions"
    private let maxVersions = 20  // Garder les 20 dernières versions
    private let backupInterval: TimeInterval = 3600  // Backup chaque heure

    private var lastBackupTime: Date?
    private var cachedDatabasePath: URL?

    private var versionsDirectory: URL? {
        guard
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            return nil
        }
        // Les backups vont dans le même dossier que la BD
        return appSupport.appendingPathComponent(versionsDirectoryName)
    }

    /// Obtient le chemin réel de la base de données SwiftData
    /// SwiftData stocke la BD directement dans: ~/Library/Application Support/default.store
    private var databasePath: URL? {
        // Si nous l'avons déjà en cache, le retourner
        if let cached = cachedDatabasePath, fileManager.fileExists(atPath: cached.path) {
            return cached
        }

        guard
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            return nil
        }

        // SwiftData crée la BD directement dans Application Support
        let defaultStorePath = appSupport.appendingPathComponent("default.store")

        // Vérifier si le chemin existe
        if fileManager.fileExists(atPath: defaultStorePath.path) {
            self.cachedDatabasePath = defaultStorePath
            return defaultStorePath
        }

        // Si le chemin par défaut n'existe pas, chercher tout fichier .store dans Application Support
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: appSupport, includingPropertiesForKeys: nil)

            // Chercher le premier fichier .store (qui n'est pas un backup)
            for fileURL in contents {
                if fileURL.pathExtension == "store"
                    && !fileURL.lastPathComponent.hasPrefix("backup_")
                {
                    self.cachedDatabasePath = fileURL
                    return fileURL
                }
            }
        } catch {
            print("⚠️  Versioning: Erreur lors de la recherche de la BD: \(error)")
        }

        // En dernier recours, retourner le chemin par défaut
        return defaultStorePath
    }

    private init() {}

    /// Crée un backup de la base de données actuelle
    func createBackup(reason: String = "Scheduled backup") -> URL? {
        guard let versionsDir = versionsDirectory,
            let dbPath = databasePath
        else {
            print("❌ Versioning: Impossible d'accéder aux répertoires")
            return nil
        }

        // Créer le répertoire de versions s'il n'existe pas
        do {
            try fileManager.createDirectory(at: versionsDir, withIntermediateDirectories: true)
        } catch {
            print("❌ Versioning: Erreur création répertoire: \(error)")
            return nil
        }

        // Vérifier que la BD existe
        guard fileManager.fileExists(atPath: dbPath.path) else {
            print("⚠️  Versioning: BD non trouvée à: \(dbPath.path)")
            print("   Raison: \(reason)")
            print("   La BD sera disponible après la première sauvegarde avec données")
            return nil
        }

        // Créer un nom unique pour cette version
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = dateFormatter.string(from: Date())
        let versionName = "backup_\(timestamp).store"
        let versionPath = versionsDir.appendingPathComponent(versionName)

        do {
            // Copier la BD avec un verrou pour éviter les accès concurrents
            try fileManager.copyItem(at: dbPath, to: versionPath)
            print("✅ Versioning: Backup créé: \(versionName)")
            print("   Raison: \(reason)")

            // Nettoyer les vieilles versions
            cleanupOldVersions()

            lastBackupTime = Date()
            return versionPath
        } catch {
            print("❌ Versioning: Erreur lors du backup: \(error)")
            return nil
        }
    }

    /// Retourne la liste des versions disponibles
    func listAvailableVersions() -> [DatabaseVersion] {
        guard let versionsDir = versionsDirectory else {
            print("⚠️  Versioning: Impossible d'accéder au répertoire des versions")
            return []
        }

        // Créer le répertoire s'il n'existe pas
        if !fileManager.fileExists(atPath: versionsDir.path) {
            do {
                try fileManager.createDirectory(at: versionsDir, withIntermediateDirectories: true)
                print("ℹ️  Versioning: Répertoire des versions créé")
            } catch {
                print("❌ Versioning: Erreur création répertoire: \(error)")
                return []
            }
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: versionsDir, includingPropertiesForKeys: [.contentModificationDateKey])

            var versions: [DatabaseVersion] = []

            for fileURL in contents
            where fileURL.lastPathComponent.hasPrefix("backup_") && fileURL.pathExtension == "store"
            {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                    let fileSize = attributes[.size] as? Int,
                    let modDate = attributes[.modificationDate] as? Date
                {

                    let filename = fileURL.lastPathComponent
                    versions.append(
                        DatabaseVersion(
                            name: filename,
                            path: fileURL,
                            dateCreated: modDate,
                            fileSize: fileSize
                        ))
                }
            }

            // Trier par date (plus récente en premier)
            return versions.sorted { $0.dateCreated > $1.dateCreated }
        } catch {
            print("❌ Versioning: Erreur lors de la lecture des versions: \(error)")
            return []
        }
    }

    /// Restaure une version spécifique de la BD
    func restoreVersion(_ version: DatabaseVersion) throws {
        guard let dbPath = databasePath else {
            throw NSError(
                domain: "DatabaseVersioningService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Impossible d'accéder au chemin de la BD"]
            )
        }

        // Créer un backup de l'état actuel avant restauration
        _ = createBackup(reason: "Backup avant restauration")

        // Supprimer la BD actuelle
        if fileManager.fileExists(atPath: dbPath.path) {
            try fileManager.removeItem(at: dbPath)
            print("✅ Versioning: Ancienne BD supprimée")
        }

        // Restaurer la version
        try fileManager.copyItem(at: version.path, to: dbPath)
        print("✅ Versioning: BD restaurée depuis: \(version.name)")
        print("   Date: \(version.dateCreated.formatted(date: .abbreviated, time: .standard))")
    }

    /// Crée un backup si assez de temps s'est écoulé
    func createBackupIfNeeded() {
        let now = Date()

        if let lastBackup = lastBackupTime {
            // Vérifier si assez de temps s'est écoulé
            if now.timeIntervalSince(lastBackup) < backupInterval {
                return
            }
        }

        _ = createBackup(reason: "Auto-backup selon l'intervalle")
    }

    /// Nettoie les vieilles versions au-delà de la limite
    private func cleanupOldVersions() {
        let versions = listAvailableVersions()

        if versions.count > maxVersions {
            let versionsToDelete = Array(versions[maxVersions...])

            for version in versionsToDelete {
                do {
                    try fileManager.removeItem(at: version.path)
                    print("🗑️  Versioning: Ancienne version supprimée: \(version.name)")
                } catch {
                    print("⚠️  Versioning: Erreur suppression version: \(version.name) - \(error)")
                }
            }
        }
    }

    /// Obtient la taille totale des backups
    func getTotalBackupSize() -> Int {
        return listAvailableVersions().reduce(0) { $0 + $1.fileSize }
    }

    /// Supprime tous les backups (utiliser avec prudence)
    func deleteAllBackups() throws {
        let versions = listAvailableVersions()

        for version in versions {
            try fileManager.removeItem(at: version.path)
            print("🗑️  Versioning: Version supprimée: \(version.name)")
        }
    }
}

/// Représente une version de la BD
struct DatabaseVersion: Identifiable, Hashable {
    let id: String
    let name: String
    let path: URL
    let dateCreated: Date
    let fileSize: Int

    init(name: String, path: URL, dateCreated: Date, fileSize: Int) {
        self.name = name
        self.path = path
        self.dateCreated = dateCreated
        self.fileSize = fileSize
        self.id = path.absoluteString
    }

    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DatabaseVersion, rhs: DatabaseVersion) -> Bool {
        lhs.id == rhs.id
    }
}
