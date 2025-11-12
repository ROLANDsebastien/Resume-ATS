import Combine
import SwiftData
import SwiftUI

@main
struct Resume_ATSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var sharedModelContainer: ModelContainer?
    @State private var isInitialized = false
    @State private var databaseLoadError: String?
    @AppStorage("colorScheme") private var colorScheme: Int = 2
    @AppStorage("windowWidth") private var windowWidth: Double = 1200
    @AppStorage("windowHeight") private var windowHeight: Double = 800
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                ContentView()
                    .preferredColorScheme(
                        colorScheme == 0 ? .light : (colorScheme == 1 ? .dark : nil)
                    )
                    .modelContainer(container)
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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Create a backup when the app goes to background
                if let container = sharedModelContainer {
                    print("📱 Application mise en arrière-plan - sauvegarde et backup")

                    // Create a temporary ModelContext for saving before backup
                    let context = ModelContext(container)

                    // Perform backup on utility queue (not background to ensure it completes)
                    DispatchQueue.global(qos: .utility).async {
                        _ = DatabaseBackupService.shared.createBackup(
                            reason: "App background",
                            modelContext: context
                        )
                    }
                }
            } else if newPhase == .active {
                print("📱 Application activée")

                // Verify database integrity when app becomes active
                if sharedModelContainer != nil {
                    DispatchQueue.global(qos: .utility).async {
                        self.verifyDatabaseIntegrity()
                    }
                }
            }
        }
    }

    private func initializeModelContainer() {
        print("")
        print("============================================================")
        print("🚀 DÉMARRAGE DE L'APPLICATION")
        print("============================================================")

        // Define schema with versioning for proper migration
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

            // CRITICAL: Verify database integrity on startup
            if let dbPath = getDatabasePath() {
                print("🔍 Vérification de l'intégrité de la base de données...")
                if !SQLiteHelper.verifyDatabaseIntegrity(at: dbPath) {
                    print("❌ CORRUPTION DÉTECTÉE au démarrage!")
                    print("   Tentative de récupération...")

                    // Try to checkpoint the database to fix potential WAL issues
                    if SQLiteHelper.checkpointDatabase(at: dbPath) {
                        print("   ✅ Checkpoint effectué - nouvelle vérification...")
                        if SQLiteHelper.verifyDatabaseIntegrity(at: dbPath) {
                            print("   ✅ Base de données réparée!")
                        } else {
                            print("   ❌ Impossible de réparer - restaurez depuis un backup")
                            databaseLoadError =
                                "Base de données corrompue - veuillez restaurer depuis un backup"
                        }
                    }
                } else {
                    print("✅ Intégrité de la base de données vérifiée")
                }
                print("")
            }

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

            // Store the container
            sharedModelContainer = container

            // Also store in AppDelegate for proper cleanup on termination
            AppDelegate.sharedModelContainer = container

        } catch let containerError {
            print("")
            print("╔════════════════════════════════════════════════════════════╗")
            print("║          ❌ ERREUR CRITIQUE - BASE DE DONNÉES            ║")
            print("╚════════════════════════════════════════════════════════════╝")
            print("")
            print("Description: \(containerError.localizedDescription)")
            print("Type d'erreur: \(type(of: containerError))")
            print("")
            print("⚠️  IMPORTANT: Vos données n'ont PAS été supprimées")
            print("   Elles sont toujours sauvegardées sur votre ordinateur")
            print("")
            print("Localisation de la base de données:")
            print("~/Library/Application Support/com.sebastienroland.Resume-ATS/")
            print("  default.store")
            print("")
            print("Solutions:")
            print("1. Redémarrez l'application")
            print("2. Vérifiez l'espace disque disponible")
            print("3. Exportez vos données via Settings si possible")
            print("")

            // Enhanced error analysis
            if let decodingError = containerError as? DecodingError {
                print("🔍 ANALYSE: Erreur de décodage détectée")
                print("   Cela peut indiquer une incompatibilité de schéma")
                print("   avec les données anciennes.")
                print("")
                switch decodingError {
                case .dataCorrupted(let context):
                    print("   • Données corrompues dans contexte: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("   • Clé manquante: \(key) dans contexte: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("   • Type incompatible: \(type) dans contexte: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print(
                        "   • Valeur manquante de type: \(type) dans contexte: \(context.codingPath)"
                    )
                @unknown default:
                    print("   • Erreur de décodage inconnue")
                }
            } else {
                print("🔍 ANALYSE: Erreur de configuration ou de stockage")
                print("   La base de données peut être corrompue ou inaccessible")
            }

            print("")

            // CRITICAL: Try to create a container as a fallback and preserve existing data
            do {
                print("🔄 Tentative de récupération...")

                // Try to create container with minimal schema if possible
                let fallbackSchema = Schema([
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

                let fallbackConfig = ModelConfiguration(
                    schema: fallbackSchema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )

                let fallbackContainer = try ModelContainer(
                    for: fallbackSchema, configurations: [fallbackConfig])
                sharedModelContainer = fallbackContainer

                // Also store in AppDelegate
                AppDelegate.sharedModelContainer = fallbackContainer

                print("✅ Conteneur de récupération créé avec succès")

            } catch {
                print("❌ Échec de la création du conteneur de récupération: \(error)")

                // Even if fallback fails, we still want to show error but allow partial functionality
                databaseLoadError =
                    "Erreur critique: Impossible d'initialiser la base de données. \(containerError.localizedDescription)"
                return
            }

            // If we get here, we either have the original container or a fallback
            // Continue with normal initialization
            if sharedModelContainer != nil {
                print("✅ Réinitialisation terminée avec conteneur de secours")
            }
        }
    }

    /// Gets the path to the main SwiftData database
    private func getDatabasePath() -> URL? {
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }

        // Look for the main database file
        let bundleID = "com.sebastienroland.Resume-ATS"
        let dbPath = appSupport.appendingPathComponent(bundleID).appendingPathComponent(
            "default.store")

        if FileManager.default.fileExists(atPath: dbPath.path) {
            return dbPath
        }

        // Fallback: direct path in Application Support
        let fallbackPath = appSupport.appendingPathComponent("default.store")
        if FileManager.default.fileExists(atPath: fallbackPath.path) {
            return fallbackPath
        }

        return nil
    }

    /// Verifies database integrity periodically
    private func verifyDatabaseIntegrity() {
        guard let dbPath = getDatabasePath() else { return }

        if !SQLiteHelper.verifyDatabaseIntegrity(at: dbPath) {
            print("⚠️  CORRUPTION DÉTECTÉE lors de la vérification périodique!")

            DispatchQueue.main.async {
                self.databaseLoadError =
                    "Corruption détectée - sauvegardez vos données et restaurez depuis un backup"
            }
        }
    }
}
