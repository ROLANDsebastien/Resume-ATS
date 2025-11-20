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
    @AppStorage("pendingRestoreBackupPath") private var pendingRestoreBackupPath: String = ""

    @StateObject private var saveManager = SaveManager.shared

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                ContentView()
                    .preferredColorScheme(
                        colorScheme == 0 ? .light : (colorScheme == 1 ? .dark : nil)
                    )
                    .modelContainer(container)
                    .onAppear {
                        saveManager.configure(with: container)

                        saveManager.backupCallback = { reason in
                            return DatabaseBackupService.shared.createBackup(reason: reason)
                        }

                        saveManager.startAutoSave()
                    }
                    .onDisappear {
                        saveManager.stopAutoSave()
                    }
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
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
    }

    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        guard let container = sharedModelContainer else { return }

        switch newPhase {
        case .background:
            print("")
            print("═══════════════════════════════════════════════════════════")
            print("📱 APPLICATION MOVED TO BACKGROUND")
            print("═══════════════════════════════════════════════════════════")

            saveManager.stopAutoSave()

            _ = saveManager.forceSave(
                from: container,
                reason: "App moving to background",
                shouldBackup: true
            )

        case .inactive:
            print("📱 Application inactive (transition)")
            _ = saveManager.forceSave(
                from: container,
                reason: "App becoming inactive"
            )

        case .active:
            print("")
            print("═══════════════════════════════════════════════════════════")
            print("📱 APPLICATION ACTIVATED")
            print("═══════════════════════════════════════════════════════════")

            saveManager.startAutoSave()

            verifyDatabaseIntegrity()

            verifyDataPresence(container: container)

        @unknown default:
            print("⚠️  Unknown phase: \(newPhase)")
        }
    }

    private func verifyDataPresence(container: ModelContainer) {
        print("🔍 Verifying data presence...")

        let context = ModelContext(container)

        do {
            let profileDescriptor = FetchDescriptor<Profile>()
            let profiles = try context.fetch(profileDescriptor)

            let appDescriptor = FetchDescriptor<Application>()
            let applications = try context.fetch(appDescriptor)

            let letterDescriptor = FetchDescriptor<CoverLetter>()
            let coverLetters = try context.fetch(letterDescriptor)

            print("   • Profiles: \(profiles.count)")
            print("   • Applications: \(applications.count)")
            print("   • Cover Letters: \(coverLetters.count)")

            if profiles.isEmpty && applications.isEmpty && coverLetters.isEmpty {
                print("   ⚠️  ALERT: All data is empty!")
                print("   This may indicate data loss")

                DispatchQueue.main.async {
                    self.databaseLoadError =
                        "No data detected. Restore from backup in Settings."
                }
            } else {
                print("   ✅ Data present and accessible")
            }
        } catch {
            print("   ❌ Error verifying data: \(error)")
        }
    }

    private func initializeModelContainer() {
        print("")
        print("============================================================")
        print("🚀 APPLICATION STARTUP")
        print("============================================================")

        if !pendingRestoreBackupPath.isEmpty {
            print("🔄 Pending restore detected: \(pendingRestoreBackupPath)")
            performPreStartupRestore(backupPath: pendingRestoreBackupPath)
            pendingRestoreBackupPath = ""
        }

        do {
            let schema = Schema([
                Profile.self,
                Application.self,
                CoverLetter.self,
                CVDocument.self
            ])

            let config = ModelConfiguration(
                "ResumeATS",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .none
            )

            sharedModelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )

            print("✅ ModelContainer initialized successfully")
            print("   Location: Application Support/com.sebastienroland.Resume-ATS")
            verifyDataPresence(container: sharedModelContainer!)

        } catch {
            databaseLoadError = "Failed to initialize database: \(error.localizedDescription)"
            print("❌ Failed to initialize ModelContainer: \(error)")
        }

        print("============================================================")
        print("")
    }

    private func performPreStartupRestore(backupPath: String) {
        print("")
        print("═══════════════════════════════════════════════════════════")
        print("🔄 PRE-STARTUP RESTORE (ModelContainer not yet initialized)")
        print("═══════════════════════════════════════════════════════════")

        let backupURL = URL(fileURLWithPath: backupPath)

        guard FileManager.default.fileExists(atPath: backupPath) else {
            print("❌ Backup file not found: \(backupPath)")
            return
        }

        do {
            try DatabaseBackupService.shared.restoreFromBackup(backupURL: backupURL)
            print("✅ Restore completed successfully")
        } catch {
            print("❌ Restore failed: \(error.localizedDescription)")
            databaseLoadError = "Restore failed: \(error.localizedDescription)"
        }

        print("═══════════════════════════════════════════════════════════")
        print("")
    }

    private func verifyDatabaseIntegrity() {
        print("🔍 Verifying database integrity...")

        if let dbPath = getDatabasePath() {
            if FileManager.default.fileExists(atPath: dbPath.path) {
                print("   ✅ Database file exists")

                if FileManager.default.isReadableFile(atPath: dbPath.path) {
                    print("   ✅ Database file is readable")
                } else {
                    print("   ❌ Database file is NOT readable")
                }

                if let attributes = try? FileManager.default.attributesOfItem(atPath: dbPath.path),
                    let fileSize = attributes[.size] as? Int
                {
                    let sizeInMB = Double(fileSize) / (1024 * 1024)
                    print("   📊 Database size: \(String(format: "%.2f", sizeInMB)) MB")

                    if fileSize == 0 {
                        print("   ⚠️  WARNING: Database file is empty!")
                    }
                }
            } else {
                print("   ⚠️  Database file does not exist")
            }
        } else {
            print("   ⚠️  Could not find database path")
        }
    }

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
        let dbPath = appSupport.appendingPathComponent(bundleID)
            .appendingPathComponent("ResumeATS.store")

        return dbPath
    }
}
