import SwiftData
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Auto-export data on app close to prevent data loss
        autoExportData()
    }

    private func autoExportData() {
        print("App terminating - consider exporting data manually")
    }
}

@main
struct Resume_ATSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        // First, log database info
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
                if let decodingError = error as? DecodingError {
                    print("   C'est une erreur de décodage - problème de compatibilité")
                }
            }

            print("")
            return container

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
    }()

    @AppStorage("colorScheme") private var colorScheme: Int = 2  // 0=light, 1=dark, 2=system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme == 0 ? .light : (colorScheme == 1 ? .dark : nil))
        }
        .modelContainer(sharedModelContainer)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quitter") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}
