import SwiftData
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // Keep reference to ModelContainer for saving on termination
    static var sharedModelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Restaurer la position et la taille de la fenêtre au démarrage
        guard let window = NSApplication.shared.windows.first else { return }

        let windowX = UserDefaults.standard.double(forKey: "windowX")
        let windowY = UserDefaults.standard.double(forKey: "windowY")
        let windowWidth = UserDefaults.standard.double(forKey: "windowWidth")
        let windowHeight = UserDefaults.standard.double(forKey: "windowHeight")

        print("🪟 AppDelegate - Restauration au démarrage:")
        print("   X: \(windowX), Y: \(windowY), Width: \(windowWidth), Height: \(windowHeight)")

        // Vérifier que les valeurs sont valides (restaurées d'une session précédente)
        if windowWidth > 300 && windowHeight > 200 {
            let frame = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
            print("   ✅ Restauration position + taille: \(frame)")
            window.setFrame(frame, display: true)
        } else {
            print("   ℹ️  Pas de sauvegarde valide, utilisation des valeurs par défaut")
        }

        // Définir comme délégué pour observer les changements
        window.delegate = self
    }

    static func saveWindowFrame(_ window: NSWindow) {
        let frame = window.frame

        print("🪟 AppDelegate - Sauvegarde de la fenêtre:")
        print("   Frame: \(frame)")
        print("   Origin: (\(frame.origin.x), \(frame.origin.y))")
        print("   Size: \(frame.size.width) x \(frame.size.height)")

        // Ignorer les frames invalides (très petits)
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
            print("💾 Sauvegarde finale de la base de données...")

            let context = ModelContext(container)

            // Save any pending changes
            if context.hasChanges {
                do {
                    try context.save()
                    print("   ✅ Changements sauvegardés")
                } catch {
                    print("   ❌ Erreur sauvegarde: \(error)")
                }
            } else {
                print("   ℹ️  Aucun changement en attente")
            }

            // Create final backup before exit
            print("")
            print("📦 Création backup final avant fermeture...")
            _ = DatabaseBackupService.shared.createBackup(
                reason: "App termination",
                modelContext: context
            )
        }

        print("═══════════════════════════════════════════════════════════")
        print("👋 Fermeture de l'application")
        print("")
    }
}
