import Combine
import SwiftData
import SwiftUI

@main
struct Resume_ATSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var sharedModelContainer: ModelContainer?
    @State private var isInitialized = false
    @State private var showDatabaseRecovery = false
    @State private var databaseLoadError: String?
    @AppStorage("colorScheme") private var colorScheme: Int = 2
    @AppStorage("windowWidth") private var windowWidth: Double = 1200
    @AppStorage("windowHeight") private var windowHeight: Double = 800
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if showDatabaseRecovery {
                DatabaseRecoveryView(language: "fr")
            } else if let container = sharedModelContainer {
                ContentView()
                    .preferredColorScheme(
                        colorScheme == 0 ? .light : (colorScheme == 1 ? .dark : nil)
                    )
                    .modelContainer(container)
                    .onReceive(
                        Timer.publish(every: 3600, on: .main, in: .common).autoconnect(),
                        perform: { _ in
                            // Créer un backup automatique toutes les heures
                            // IMPORTANT: SwiftData sauvegarde automatiquement avant ce timer
                            print("⏰ Timer d'auto-backup déclenché (toutes les heures)")
                            DispatchQueue.global(qos: .background).asyncAfter(
                                deadline: .now() + 0.5
                            ) {
                                let _ = DatabaseVersioningService.shared.createBackup(
                                    reason: "Auto-backup (toutes les heures)")
                            }
                        }
                    )
            } else {
                VStack(spacing: 20) {
                    ProgressView("Initialisation...")

                    if let error = databaseLoadError {
                        VStack(spacing: 12) {
                            Text("Erreur de chargement de la base de données")
                                .font(.headline)
                                .foregroundColor(.red)

                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button(action: { showDatabaseRecovery = true }) {
                                Label(
                                    "Restaurer une version antérieure",
                                    systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .padding()
                .onAppear {
                    if !isInitialized {
                        isInitialized = true
                        initializeModelContainer()
                    }
                }
            }
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: windowWidth, height: windowHeight)
    }

    private func initializeModelContainer() {
        print("")
        print("============================================================")
        print("🚀 DÉMARRAGE DE L'APPLICATION")
        print("============================================================")

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

                // Fetch Applications
                let appDescriptor = FetchDescriptor<Application>()
                let applications = try context.fetch(appDescriptor)
                print("   • Candidatures: \(applications.count)")

                // Fetch CoverLetters
                let letterDescriptor = FetchDescriptor<CoverLetter>()
                let coverLetters = try context.fetch(letterDescriptor)
                print("   • Lettres de Motivation: \(coverLetters.count)")

                // Fetch CVDocuments
                let cvDescriptor = FetchDescriptor<CVDocument>()
                let cvDocuments = try context.fetch(cvDescriptor)
                print("   • Documents CV: \(cvDocuments.count)")

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
                    databaseLoadError =
                        "Erreur de compatibilité de la base de données. Vous pouvez restaurer une version antérieure ou continuer."
                } else {
                    databaseLoadError = error.localizedDescription
                }
            }

            print("")

            // Créer le premier backup après initialisation réussie
            // IMPORTANT: Attendre que SwiftData ait bien initialisé et sauvegardé les données
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
                print("📦 Création du backup initial après démarrage...")
                _ = DatabaseVersioningService.shared.createBackup(
                    reason: "Backup après démarrage réussi")
            }

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
            print("Localisation de la base de données:")
            print("~/Library/Application Support/com.sebastienroland.Resume-ATS/")
            print("  default.store")
            print("")
            print("Solutions:")
            print("1. Restaurez une version antérieure via l'écran de récupération")
            print("2. Redémarrez l'application")
            print("3. Vérifiez l'espace disque disponible")
            print("4. Exportez vos données via Settings si possible")
            print("")

            // Analyse détaillée de l'erreur
            if let decodingError = error as? DecodingError {
                print("🔍 ANALYSE: Erreur de décodage détectée")
                print("   Cela peut indiquer une incompatibilité de schéma")
                print("   avec les données anciennes.")
                print("")
                switch decodingError {
                case .dataCorrupted(_):
                    print("   • Les données semblent corrompues")
                case .keyNotFound(_, _):
                    print("   • Une clé attendue est manquante")
                case .typeMismatch(_, _):
                    print("   • Un type de données ne correspond pas")
                case .valueNotFound(_, _):
                    print("   • Une valeur attendue est manquante")
                @unknown default:
                    print("   • Erreur de décodage inconnue")
                }
            }

            print("")

            databaseLoadError =
                "Erreur lors de l'initialisation de la base de données: \(error.localizedDescription)"
        }
    }
}
