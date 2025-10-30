import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var windowObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Restaurer la position et la taille de la fenêtre au démarrage
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let window = NSApplication.shared.windows.first else { return }

            let windowX = UserDefaults.standard.double(forKey: "windowX")
            let windowY = UserDefaults.standard.double(forKey: "windowY")
            let windowWidth = UserDefaults.standard.double(forKey: "windowWidth")
            let windowHeight = UserDefaults.standard.double(forKey: "windowHeight")

            print("🪟 AppDelegate - Restauration au démarrage:")
            print("   X: \(windowX), Y: \(windowY), Width: \(windowWidth), Height: \(windowHeight)")

            // Vérifier que les valeurs sont valides (restaurées d'une session précédente)
            if windowX > 100 && windowY > 100 && windowWidth > 300 && windowHeight > 200 {
                let frame = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
                print("   ✅ Restauration position + taille: \(frame)")
                window.setFrame(frame, display: true)
            } else {
                print("   ℹ️  Pas de sauvegarde valide, utilisation des valeurs par défaut")
            }

            // Définir comme délégué pour observer les changements
            window.delegate = self

            // Aussi ajouter un observateur pour la notification de fermeture de fenêtre
            self.windowObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { _ in
                AppDelegate.saveWindowFrame(window)
            }
        }
    }

    static func saveWindowFrame(_ window: NSWindow) {
        let frame = window.frame

        print("🪟 AppDelegate - Sauvegarde de la fenêtre:")
        print("   Frame: \(frame)")
        print("   Origin: (\(frame.origin.x), \(frame.origin.y))")
        print("   Size: \(frame.size.width) x \(frame.size.height)")

        // Ignorer les frames invalides (0,0 ou très petits)
        if frame.origin.x > 50 && frame.origin.y > 50 && frame.size.width > 300
            && frame.size.height > 200
        {
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

    func applicationWillTerminate(_ aNotification: Notification) {
        if let window = NSApplication.shared.windows.first {
            AppDelegate.saveWindowFrame(window)
        }

        // Nettoyer l'observateur
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
