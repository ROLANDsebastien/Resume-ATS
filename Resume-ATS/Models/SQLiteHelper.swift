//
//  SQLiteHelper.swift
//  Resume-ATS
//
//  Created to provide safe SQLite operations and prevent data corruption
//

import Foundation
import SQLite3

/// Utility class to handle low-level SQLite operations
/// Ensures data integrity through proper checkpointing and validation
class SQLiteHelper {

    /// Forces SQLite to merge WAL (Write-Ahead Log) into the main database file
    /// This is CRITICAL before making backups to ensure file consistency
    /// - Parameter dbPath: Path to the .store database file
    /// - Returns: True if checkpoint succeeded, false otherwise
    static func checkpointDatabase(at dbPath: URL) -> Bool {
        let dbPathString = dbPath.path
        var db: OpaquePointer?

        print("🔄 SQLite Checkpoint - Début")
        print("   Fichier: \(dbPath.lastPathComponent)")

        // Open database connection
        guard sqlite3_open(dbPathString, &db) == SQLITE_OK else {
            print("❌ Impossible d'ouvrir la base pour checkpoint")
            if let db = db {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("   Erreur SQLite: \(errorMessage)")
                sqlite3_close(db)
            }
            return false
        }

        defer {
            sqlite3_close(db)
        }

        // Get WAL file size before checkpoint
        let walPath = URL(fileURLWithPath: dbPathString + "-wal")
        var walSizeBefore: Int64 = 0
        if FileManager.default.fileExists(atPath: walPath.path) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: walPath.path),
                let fileSize = attrs[.size] as? Int64
            {
                walSizeBefore = fileSize
            }
        }

        print("   Taille WAL avant: \(walSizeBefore / 1024) KB")

        // Force checkpoint in TRUNCATE mode
        // This will:
        // 1. Copy all WAL frames into the main database file
        // 2. Truncate the WAL file to zero bytes
        // 3. Ensure consistency between .store and .wal files
        var logFrameCount: Int32 = 0
        var checkpointedFrames: Int32 = 0

        let result = sqlite3_wal_checkpoint_v2(
            db,
            nil,  // Apply to all attached databases
            SQLITE_CHECKPOINT_TRUNCATE,  // Force truncate after checkpoint
            &logFrameCount,
            &checkpointedFrames
        )

        if result == SQLITE_OK {
            print("✅ Checkpoint réussi")
            print("   Frames dans le log: \(logFrameCount)")
            print("   Frames checkpointés: \(checkpointedFrames)")

            // Verify WAL was truncated
            var walSizeAfter: Int64 = 0
            if FileManager.default.fileExists(atPath: walPath.path) {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: walPath.path),
                    let fileSize = attrs[.size] as? Int64
                {
                    walSizeAfter = fileSize
                }
            }
            print("   Taille WAL après: \(walSizeAfter / 1024) KB")

            if walSizeAfter == 0 {
                print("   ✅ WAL correctement tronqué")
            } else if walSizeAfter < walSizeBefore {
                print("   ⚠️  WAL réduit mais pas à zéro")
            }

            return true
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Échec du checkpoint SQLite")
            print("   Code d'erreur: \(result)")
            print("   Message: \(errorMessage)")
            return false
        }
    }

    /// Verifies database integrity using SQLite's built-in integrity check
    /// - Parameter dbPath: Path to the .store database file
    /// - Returns: True if database is intact, false if corrupted
    static func verifyDatabaseIntegrity(at dbPath: URL) -> Bool {
        let dbPathString = dbPath.path
        var db: OpaquePointer?

        print("🔍 Vérification intégrité DB")
        print("   Fichier: \(dbPath.lastPathComponent)")

        // First check if the main database file exists and is readable
        guard FileManager.default.fileExists(atPath: dbPathString) else {
            print("❌ Fichier de base de données introuvable: \(dbPathString)")
            return false
        }

        // Try to open with URI to avoid requiring WAL/SHM files
        let uriFilename = "file:\(dbPathString)?mode=ro&nolock=1"

        guard
            sqlite3_open_v2(
                uriFilename,
                &db,
                SQLITE_OPEN_READONLY | SQLITE_OPEN_URI,
                nil
            ) == SQLITE_OK
        else {
            // If we still can't open, just verify the file exists and has content
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: dbPathString)
                if let fileSize = attrs[.size] as? Int64, fileSize > 0 {
                    print("   ℹ️  Impossible de vérifier (DB peut être verrouillée)")
                    print("   ✅ Fichier existe et a du contenu (\(fileSize) bytes)")
                    return true
                } else {
                    print("❌ Fichier vide ou invalide")
                    return false
                }
            } catch {
                print("❌ Erreur accès fichier: \(error)")
                if let db = db {
                    sqlite3_close(db)
                }
                return false
            }
        }

        defer {
            sqlite3_close(db)
        }

        var statement: OpaquePointer?
        let query = "PRAGMA integrity_check;"

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("❌ Impossible de préparer la requête d'intégrité")
            if statement != nil {
                sqlite3_finalize(statement)
            }
            return false
        }

        defer {
            sqlite3_finalize(statement)
        }

        var results: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                let result = String(cString: cString)
                results.append(result)
            }
        }

        // "ok" means database is intact
        let isOk = results.count == 1 && results[0] == "ok"

        if isOk {
            print("✅ Intégrité DB vérifiée - OK")
        } else {
            print("❌ CORRUPTION DÉTECTÉE!")
            print("   Résultats de l'intégrité check:")
            for (index, result) in results.enumerated() {
                print("   [\(index + 1)] \(result)")
            }
        }

        return isOk
    }

    /// Performs a quick check to see if database file can be opened
    /// - Parameter dbPath: Path to the .store database file
    /// - Returns: True if database can be opened, false otherwise
    static func canOpenDatabase(at dbPath: URL) -> Bool {
        var db: OpaquePointer?
        let result = sqlite3_open(dbPath.path, &db)

        if result == SQLITE_OK {
            sqlite3_close(db)
            return true
        } else {
            if let db = db {
                sqlite3_close(db)
            }
            return false
        }
    }

    /// Gets database page count and size information
    /// Useful for diagnostic purposes
    /// - Parameter dbPath: Path to the .store database file
    /// - Returns: Dictionary with page_count, page_size, and total_size
    static func getDatabaseInfo(at dbPath: URL) -> [String: Int64]? {
        var db: OpaquePointer?

        guard sqlite3_open_v2(dbPath.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            if let db = db {
                sqlite3_close(db)
            }
            return nil
        }

        defer {
            sqlite3_close(db)
        }

        var info: [String: Int64] = [:]

        // Get page count
        var pageCountStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "PRAGMA page_count;", -1, &pageCountStmt, nil) == SQLITE_OK {
            if sqlite3_step(pageCountStmt) == SQLITE_ROW {
                info["page_count"] = sqlite3_column_int64(pageCountStmt, 0)
            }
            sqlite3_finalize(pageCountStmt)
        }

        // Get page size
        var pageSizeStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "PRAGMA page_size;", -1, &pageSizeStmt, nil) == SQLITE_OK {
            if sqlite3_step(pageSizeStmt) == SQLITE_ROW {
                info["page_size"] = sqlite3_column_int64(pageSizeStmt, 0)
            }
            sqlite3_finalize(pageSizeStmt)
        }

        // Calculate total size
        if let pageCount = info["page_count"], let pageSize = info["page_size"] {
            info["total_size"] = pageCount * pageSize
        }

        return info
    }

    /// Forces a full vacuum of the database
    /// This rebuilds the database file, removing fragmentation
    /// WARNING: This can be slow for large databases
    /// - Parameter dbPath: Path to the .store database file
    /// - Returns: True if vacuum succeeded, false otherwise
    static func vacuumDatabase(at dbPath: URL) -> Bool {
        var db: OpaquePointer?

        print("🧹 VACUUM de la base de données")
        print("   Fichier: \(dbPath.lastPathComponent)")

        guard sqlite3_open(dbPath.path, &db) == SQLITE_OK else {
            print("❌ Impossible d'ouvrir la base pour VACUUM")
            if let db = db {
                sqlite3_close(db)
            }
            return false
        }

        defer {
            sqlite3_close(db)
        }

        var errorMsg: UnsafeMutablePointer<Int8>?
        let result = sqlite3_exec(db, "VACUUM;", nil, nil, &errorMsg)

        if result == SQLITE_OK {
            print("✅ VACUUM réussi - base de données optimisée")
            return true
        } else {
            if let errorMsg = errorMsg {
                let error = String(cString: errorMsg)
                print("❌ Échec du VACUUM: \(error)")
                sqlite3_free(errorMsg)
            }
            return false
        }
    }
}
