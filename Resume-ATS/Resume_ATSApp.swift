import Combine
import SwiftData
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var modelContainer: ModelContainer?
    var autoSaveTimer: Timer?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func windowWillClose(_ notification: Notification) {
        saveData()
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        autoSaveTimer?.invalidate()
        saveData()
    }

    private func saveData() {
        guard let container = modelContainer else { return }

        do {
            print("💾 Sauvegarde des données avant fermeture...")
            let context = ModelContext(container)
            try context.save()
            print("✅ Données sauvegardées avec succès")
        } catch {
            print("❌ Erreur lors de la sauvegarde: \(error)")
        }
    }
}

@main
struct Resume_ATSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var sharedModelContainer: ModelContainer?
    @State private var isInitialized = false
    @AppStorage("colorScheme") private var colorScheme: Int = 2

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                ContentView()
                    .preferredColorScheme(
                        colorScheme == 0 ? .light : (colorScheme == 1 ? .dark : nil)
                    )
                    .onAppear {
                        startAutoSave()
                    }
                    .onReceive(
                        Timer.publish(every: 30, on: .main, in: .common).autoconnect(),
                        perform: { _ in
                            autoSaveData()
                        }
                    )
                    .modelContainer(container)
            } else {
                ProgressView("Initialisation...")
                    .onAppear {
                        if !isInitialized {
                            isInitialized = true
                            initializeModelContainer()
                        }
                    }
            }
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quitter") {
                    autoSaveData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }

    private func initializeModelContainer() {
        print("")
        print("============================================================")
        print("🚀 DÉMARRAGE DE L'APPLICATION")
        print("============================================================")
        DatabaseRepair.logDatabaseInfo()

        let schema = Schema([
            Profile.self,
            Application.self,
            CoverLetter.self,
            CVDocument.self,
            Experience.self,
            Education.self,
            Reference.self,
            SkillGroup.self,
            Certification.self,
            Language.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer créé avec succès")
            print("")

            // Store container in AppDelegate for termination handling
            appDelegate.modelContainer = container

            // DEBUG: Vérifier les données existantes
            do {
                let context = ModelContext(container)

                // Fetch Profiles
                let profileDescriptor = FetchDescriptor<Profile>()
                let profiles = try context.fetch(profileDescriptor)
                print("📊 DONNÉES CHARGÉES:")
                print("   • Profils: \(profiles.count)")
                for profile in profiles {
                    print("     - '\(profile.name)'")
                    print("       • Expériences: \(profile.experiences.count)")
                    print("       • Formations: \(profile.educations.count)")
                    print("       • Références: \(profile.references.count)")
                    print("       • Compétences: \(profile.skills.count)")
                    print("       • Certifications: \(profile.certifications.count)")
                    print("       • Langues: \(profile.languages.count)")
                }

                // Fetch Applications
                let appDescriptor = FetchDescriptor<Application>()
                let applications = try context.fetch(appDescriptor)
                print("   • Candidatures: \(applications.count)")

                // Fetch CoverLetters
                let letterDescriptor = FetchDescriptor<CoverLetter>()
                let letters = try context.fetch(letterDescriptor)
                print("   • Lettres de motivation: \(letters.count)")

                // Fetch CVDocuments
                let cvDescriptor = FetchDescriptor<CVDocument>()
                let cvs = try context.fetch(cvDescriptor)
                print("   • Documents CV: \(cvs.count)")

                print("")
                if profiles.isEmpty {
                    print("⚠️  ATTENTION: Aucun profil trouvé!")
                    print("    Créez un nouveau profil pour commencer.")
                } else {
                    print("✅ Les données sont correctement chargées!")
                }

            } catch {
                print("❌ Erreur lors de la lecture des données: \(error)")
                print("   Type: \(type(of: error))")
                if error is DecodingError {
                    print("   C'est une erreur de décodage - problème de compatibilité")
                }
            }

            print("")
            sharedModelContainer = container

        } catch {
            print("")
            print("╔════════════════════════════════════════════════════════════╗")
            print("║          ❌ ERREUR CRITIQUE - BASE DE DONNÉES            ║")
            print("╚════════════════════════════════════════════════════════════╝")
            print("")
            print("Description: \(error.localizedDescription)")
            print("Type d'erreur: \(type(of: error))")
            print("")
            print("⚠️  IMPORTANT: Vos données n'ont PAS été supprimées")
            print("   Elles sont toujours sauvegardées sur votre ordinateur")
            print("")
            print("Fichier de la base de données:")
            print("~/Library/Containers/com.sebastienroland.Resume-AT/")
            print("  Data/Library/Application Support/default.store")
            print("")
            print("Solutions:")
            print("1. Redémarrez l'application")
            print("2. Vérifiez l'espace disque disponible")
            print("3. Exportez vos données via Settings si possible")
            print("4. Contactez le support avec ce message d'erreur")
            print("")

            // Analyse détaillée de l'erreur
            if let decodingError = error as? DecodingError {
                print("🔍 ANALYSE: Erreur de décodage détectée")
                print("   Cela peut indiquer une incompatibilité de schéma")
                print("   avec les données anciennes.")
                print("")
                switch decodingError {
                case .dataCorrupted(let context):
                    print("   • Données corrompues à: \(context.codingPath)")
                    print("   • Description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("   • Clé manquante: '\(key)'")
                    print("   • Contexte: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   • Type incompatible: \(type)")
                    print("   • À: \(context.codingPath)")
                    print("   • Description: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   • Valeur manquante pour: \(type)")
                    print("   • À: \(context.codingPath)")
                @unknown default:
                    print("   • Erreur de décodage inconnue")
                }
            }

            print("")
            fatalError("Unable to initialize SwiftData ModelContainer")
        }
    }

    private func startAutoSave() {
        appDelegate.autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            autoSaveData()
        }
    }

    private func autoSaveData() {
        guard let container = sharedModelContainer else { return }

        do {
            let context = ModelContext(container)
            try context.save()
            print("✅ Auto-save réussi à \(Date().formatted(date: .abbreviated, time: .standard))")
        } catch {
            print("⚠️  Erreur lors de l'auto-save: \(error)")
        }
    }
}
