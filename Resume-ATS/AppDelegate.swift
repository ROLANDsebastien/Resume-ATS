import SwiftData
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    static var sharedModelContainer: ModelContainer?

    private var lastSaveTime: Date = Date()
    private let minimumSaveInterval: TimeInterval = 30

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }

        let windowX = UserDefaults.standard.double(forKey: "windowX")
        let windowY = UserDefaults.standard.double(forKey: "windowY")
        let windowWidth = UserDefaults.standard.double(forKey: "windowWidth")
        let windowHeight = UserDefaults.standard.double(forKey: "windowHeight")

        print("🪟 AppDelegate - Restauration au démarrage:")
        print("   X: \(windowX), Y: \(windowY), Width: \(windowWidth), Height: \(windowHeight)")

        if windowWidth > 300 && windowHeight > 200 {
            let frame = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
            print("   ✅ Restauration position + taille: \(frame)")
            window.setFrame(frame, display: true)
        } else {
            print("   ℹ️  Pas de sauvegarde valide, utilisation des valeurs par défaut")
        }

        window.delegate = self
    }

    static func saveWindowFrame(_ window: NSWindow) {
        let frame = window.frame

        print("🪟 AppDelegate - Sauvegarde de la fenêtre:")
        print("   Frame: \(frame)")
        print("   Origin: (\(frame.origin.x), \(frame.origin.y))")
        print("   Size: \(frame.size.width) x \(frame.size.height)")

        if frame.size.width > 300 && frame.size.height > 200 {
            UserDefaults.standard.set(frame.origin.x, forKey: "windowX")
            UserDefaults.standard.set(frame.origin.y, forKey: "windowY")
            UserDefaults.standard.set(frame.size.width, forKey: "windowWidth")
            UserDefaults.standard.set(frame.size.height, forKey: "windowHeight")
            UserDefaults.standard.synchronize()
            print("   ✅ Sauvegardé dans UserDefaults")
        } else {
            print("   ⚠️  Frame invalide, pas de sauvegarde")
        }
    }

    func windowDidMove(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            AppDelegate.saveWindowFrame(window)
        }
    }

    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            AppDelegate.saveWindowFrame(window)
        }
    }

    // NOUVEAU: Sauvegarder quand l'application devient inactive (cmd+h, switch app, etc.)
    func applicationWillResignActive(_ notification: Notification) {
        print("")
        print("═══════════════════════════════════════════════════════════")
        print("⏸️  APPLICATION VA DEVENIR INACTIVE")
        print("═══════════════════════════════════════════════════════════")

        // Vérifier l'intervalle minimum pour éviter trop de sauvegardes
        let timeSinceLastSave = Date().timeIntervalSince(lastSaveTime)
        if timeSinceLastSave < minimumSaveInterval {
            print("⏱️  Sauvegarde récente (\(Int(timeSinceLastSave))s) - ignorée")
            print("═══════════════════════════════════════════════════════════")
            print("")
            return
        }

        performCriticalSave(reason: "App resign active")
        print("═══════════════════════════════════════════════════════════")
        print("")
    }

    // NOUVEAU: Sauvegarder quand l'application va être cachée
    func applicationWillHide(_ notification: Notification) {
        print("")
        print("═══════════════════════════════════════════════════════════")
        print("👁️  APPLICATION VA ÊTRE CACHÉE")
        print("═══════════════════════════════════════════════════════════")

        // Vérifier l'intervalle minimum
        let timeSinceLastSave = Date().timeIntervalSince(lastSaveTime)
        if timeSinceLastSave < minimumSaveInterval {
            print("⏱️  Sauvegarde récente (\(Int(timeSinceLastSave))s) - ignorée")
            print("═══════════════════════════════════════════════════════════")
            print("")
            return
        }

        performCriticalSave(reason: "App will hide")
        print("═══════════════════════════════════════════════════════════")
        print("")
    }

    // NOUVEAU: Fonction commune de sauvegarde critique
    private func performCriticalSave(reason: String) {
        guard let container = AppDelegate.sharedModelContainer else {
            print("ℹ️  ModelContainer pas encore disponible (normal pendant l'initialisation)")
            return
        }

        let context = ModelContext(container)

        // Sauvegarder le contexte
        if context.hasChanges {
            do {
                try context.save()
                print("   ✅ Contexte sauvegardé (\(reason))")
                lastSaveTime = Date()

                // Attendre la synchronisation
                Thread.sleep(forTimeInterval: 0.3)

                // Forcer un checkpoint SQLite
                if let dbPath = getDatabasePath() {
                    _ = SQLiteHelper.checkpointDatabase(at: dbPath)
                }
            } catch {
                print("   ❌ ERREUR: Impossible de sauvegarder!")
                print("   \(error)")
            }
        } else {
            print("   ℹ️  Pas de changements à sauvegarder")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("")
        print("═══════════════════════════════════════════════════════════")
        print("🛑 APPLICATION VA SE TERMINER")
        print("═══════════════════════════════════════════════════════════")

        // Save window frame
        if let window = NSApplication.shared.windows.first {
            AppDelegate.saveWindowFrame(window)
        }

        // CRITICAL: Save and backup database before terminating
        if let container = AppDelegate.sharedModelContainer {
            print("")
            print("💾 Sauvegarde finale CRITIQUE de la base de données...")

            let context = ModelContext(container)

            // ÉTAPE 1: Save any pending changes
            if context.hasChanges {
                do {
                    try context.save()
                    print("   ✅ Changements sauvegardés")

                    // Attendre que le système de fichiers synchronise
                    Thread.sleep(forTimeInterval: 0.5)
                } catch {
                    print("   ❌ ERREUR CRITIQUE: Impossible de sauvegarder!")
                    print("   Erreur: \(error)")
                    // Continuer quand même pour tenter le backup
                }
            } else {
                print("   ℹ️  Aucun changement en attente")
            }

            // ÉTAPE 2: Forcer un checkpoint SQLite pour merger WAL
            if let dbPath = getDatabasePath() {
                print("")
                print("🔄 Checkpoint SQLite forcé avant fermeture...")
                if SQLiteHelper.checkpointDatabase(at: dbPath) {
                    print("   ✅ Checkpoint réussi - WAL mergé dans le fichier principal")
                    Thread.sleep(forTimeInterval: 0.3)
                } else {
                    print("   ⚠️  Checkpoint échoué - WAL peut ne pas être mergé")
                }
            }

            // ÉTAPE 3: Create final backup before exit (SYNCHRONE)
            print("")
            print("📦 Création backup final SYNCHRONE avant fermeture...")

            let semaphore = DispatchSemaphore(value: 0)
            var backupSuccess = false

            DispatchQueue.global(qos: .userInitiated).async {
                if let backupURL = DatabaseBackupService.shared.createBackup(
                    reason: "App termination",
                    modelContext: context
                ) {
                    print("   ✅ Backup final créé: \(backupURL.lastPathComponent)")
                    backupSuccess = true
                } else {
                    print("   ❌ Échec création backup final")
                }
                semaphore.signal()
            }

            // Attendre que le backup soit terminé (timeout de 30 secondes)
            let timeout = DispatchTime.now() + .seconds(30)
            if semaphore.wait(timeout: timeout) == .timedOut {
                print("   ⚠️  TIMEOUT: Backup trop long, fermeture forcée")
            } else if backupSuccess {
                print("   ✅ Backup final terminé avec succès")
            } else {
                print("   ⚠️  Backup final échoué")
            }
        }

        print("═══════════════════════════════════════════════════════════")
        print("👋 Fermeture de l'application")
        print("")
    }

    // Helper pour obtenir le chemin de la base de données
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
        let dbPath = appSupport.appendingPathComponent(bundleID).appendingPathComponent(
            "default.store")

        if FileManager.default.fileExists(atPath: dbPath.path) {
            return dbPath
        }

        let fallbackPath = appSupport.appendingPathComponent("default.store")
        if FileManager.default.fileExists(atPath: fallbackPath.path) {
            return fallbackPath
        }

        return nil
    }
}
