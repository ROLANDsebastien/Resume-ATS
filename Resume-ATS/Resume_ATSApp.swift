import SwiftData
import SwiftUI

@main
struct Resume_ATSApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Profile.self,
            Application.self,
            CoverLetter.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("colorScheme") private var colorScheme: Int = 2  // 0=light, 1=dark, 2=system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme == 0 ? .light : (colorScheme == 1 ? .dark : nil))
        }
        .modelContainer(sharedModelContainer)
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
