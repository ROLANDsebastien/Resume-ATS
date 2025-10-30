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
    private let minFileSize: Int = 8192  // Minimum 8KB pour une BD valide

    private var lastBackupTime: Date?
    private var cachedDatabasePath: URL?
    private var lastVerifiedDatabasePath: URL?

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
    /// Recherche le fichier .store dans les emplacements standard
    private var databasePath: URL? {
        // Si nous l'avons déjà en cache et qu'il existe toujours, le retourner
        if let cached = cachedDatabasePath, fileManager.fileExists(atPath: cached.path) {
            return cached
        }

        guard
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            print("❌ Versioning: Impossible d'accéder à Application Support")
            return nil
        }

        // Chercher tous les fichiers .store possibles
        var possiblePaths: [URL] = []

        // 1. Chemin avec bundle identifier (plus probable)
        let bundleID = "com.sebastienroland.Resume-ATS"
        let bundlePath = appSupport.appendingPathComponent(bundleID).appendingPathComponent(
            "default.store")
        possiblePaths.append(bundlePath)

        // 2. Chemin direct dans Application Support
        let directPath = appSupport.appendingPathComponent("default.store")
        possiblePaths.append(directPath)

        // 3. Chercher tous les fichiers .store dans Application Support
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: appSupport, includingPropertiesForKeys: nil)

            for fileURL in contents {
                if fileURL.pathExtension == "store"
                    && !fileURL.lastPathComponent.hasPrefix("backup_")
                {
                    possiblePaths.append(fileURL)
                }
            }

            // Aussi vérifier les sous-répertoires
            for fileURL in contents {
                if fileURL.hasDirectoryPath {
                    do {
                        let subContents = try fileManager.contentsOfDirectory(
                            at: fileURL, includingPropertiesForKeys: nil)
                        for subFile in subContents {
                            if subFile.pathExtension == "store"
                                && !subFile.lastPathComponent.hasPrefix("backup_")
                            {
                                possiblePaths.append(subFile)
                            }
                        }
                    } catch {
                        // Ignorer les erreurs de lecture de sous-répertoires
                    }
                }
            }
        } catch {
            print("⚠️  Versioning: Erreur lors de la recherche de la BD: \(error)")
        }

        // Vérifier chaque chemin possible et retourner le premier valide
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path.path) {
                // Vérifier que la BD n'est pas vide
                if let attributes = try? fileManager.attributesOfItem(atPath: path.path),
                    let fileSize = attributes[.size] as? Int,
                    fileSize > 0
                {
                    print("✅ Versioning: BD trouvée à: \(path.path) (\(fileSize) bytes)")
                    self.cachedDatabasePath = path
                    return path
                }
            }
        }

        print("⚠️  Versioning: BD non trouvée dans les emplacements standard")
        print("   Emplacements cherchés:")
        for path in possiblePaths {
            print("   - \(path.path)")
        }

        // Retourner le premier chemin possible pour les créations ultérieures
        return possiblePaths.first
    }

    /// Vérifie que la BD a vraiment du contenu
    private func isDatabaseValid(_ path: URL) -> Bool {
        guard fileManager.fileExists(atPath: path.path) else {
            return false
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: path.path)
            if let fileSize = attributes[.size] as? Int {
                // Une BD vide ou très petite n'est pas valide
                return fileSize > minFileSize
            }
        } catch {
            print("⚠️  Versioning: Erreur vérification taille BD: \(error)")
        }

        return false
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

        // Vérifier que la BD existe ET a du contenu
        guard fileManager.fileExists(atPath: dbPath.path) else {
            print("⚠️  Versioning: BD non trouvée à: \(dbPath.path)")
            print("   Raison: \(reason)")
            print("   La BD sera disponible après la première sauvegarde avec données")
            return nil
        }

        // Vérifier que la BD n'est pas vide
        guard isDatabaseValid(dbPath) else {
            print("⚠️  Versioning: BD trouvée mais vide ou trop petite")
            print("   Raison: \(reason)")
            print("   Path: \(dbPath.path)")
            return nil
        }

        // Créer un nom unique pour cette version
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = dateFormatter.string(from: Date())
        let versionName = "backup_\(timestamp).store"
        let versionPath = versionsDir.appendingPathComponent(versionName)

        do {
            // Copier la BD
            try fileManager.copyItem(at: dbPath, to: versionPath)

            // Vérifier que le backup a bien été créé et n'est pas vide
            if !isDatabaseValid(versionPath) {
                print("❌ Versioning: Backup créé mais vide ou invalide!")
                try? fileManager.removeItem(at: versionPath)
                return nil
            }

            print("✅ Versioning: Backup créé avec succès: \(versionName)")
            print("   Raison: \(reason)")

            if let attributes = try? fileManager.attributesOfItem(atPath: versionPath.path),
                let fileSize = attributes[.size] as? Int
            {
                print("   Taille: \(fileSize) bytes")
            }

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
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            for fileURL in contents
            where fileURL.lastPathComponent.hasPrefix("backup_") && fileURL.pathExtension == "store"
            {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                    let fileSize = attributes[.size] as? Int
                {
                    // Vérifier que le backup n'est pas vide
                    if fileSize > minFileSize {
                        let filename = fileURL.lastPathComponent

                        // Extraire la date ISO8601 du nom du fichier
                        // Format: backup_YYYY-MM-DDTHH:MM:SS.sssZ.store
                        var dateCreated = Date()

                        // Essayer de parser la date depuis le nom du fichier
                        if let startIndex = filename.range(of: "backup_")?.upperBound,
                            let endIndex = filename.range(of: ".store")?.lowerBound
                        {
                            let dateString = String(filename[startIndex..<endIndex])
                            if let parsedDate = dateFormatter.date(from: dateString) {
                                dateCreated = parsedDate
                            }
                        }

                        versions.append(
                            DatabaseVersion(
                                name: filename,
                                path: fileURL,
                                dateCreated: dateCreated,
                                fileSize: fileSize
                            ))
                    } else {
                        print(
                            "⚠️  Versioning: Backup ignoré (trop petit): \(fileURL.lastPathComponent)"
                        )
                    }
                }
            }

            // Trier par date (plus récente en premier) - en utilisant la date du nom du fichier
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

        // Vérifier que la version à restaurer est valide
        guard isDatabaseValid(version.path) else {
            throw NSError(
                domain: "DatabaseVersioningService",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "La version à restaurer est vide ou corrompue"
                ]
            )
        }

        print("🔄 Versioning: Début de la restauration...")
        print("   Version: \(version.name)")

        // Créer un backup de l'état actuel avant restauration
        if isDatabaseValid(dbPath) {
            _ = createBackup(reason: "Backup avant restauration")
        }

        // Supprimer la BD actuelle
        if fileManager.fileExists(atPath: dbPath.path) {
            try fileManager.removeItem(at: dbPath)
            print("✅ Versioning: Ancienne BD supprimée")
        }

        // Créer le répertoire si nécessaire
        let dbDirectory = dbPath.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: dbDirectory.path) {
            try fileManager.createDirectory(
                at: dbDirectory, withIntermediateDirectories: true)
        }

        // Restaurer la version
        try fileManager.copyItem(at: version.path, to: dbPath)
        print("✅ Versioning: BD restaurée avec succès!")
        print("   Version: \(version.name)")
        print("   Date: \(version.dateCreated.formatted(date: .abbreviated, time: .standard))")

        // Invalider le cache pour forcer une recherche lors du prochain accès
        cachedDatabasePath = nil
        lastVerifiedDatabasePath = nil
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

    /// Force la recherche du chemin de la BD (utile après restauration)
    func invalidateDatabasePathCache() {
        cachedDatabasePath = nil
        lastVerifiedDatabasePath = nil
        print("🔄 Versioning: Cache du chemin de la BD invalidé")
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
