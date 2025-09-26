import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @AppStorage("colorScheme") private var colorScheme: Int = 2  // 0: Light, 1: Dark, 2: System
    @AppStorage("autoSave") private var autoSave = true

    private var backgroundColor: Color {
        systemColorScheme == .dark
            ? Color(red: 24 / 255, green: 24 / 255, blue: 38 / 255)
            : Color(NSColor.windowBackgroundColor)
    }

    private var sectionBackground: Color {
        systemColorScheme == .dark
            ? Color(red: 44 / 255, green: 44 / 255, blue: 60 / 255)
            : Color(NSColor.controlBackgroundColor)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Réglages")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top)

                // Apparence Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.accentColor)
                        Text("Apparence")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Thème")
                                    .foregroundColor(.primary)
                                Text("Mode clair ou sombre")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Menu {
                                Button("Clair", action: { colorScheme = 0 })
                                Button("Sombre", action: { colorScheme = 1 })
                                Button("Système", action: { colorScheme = 2 })
                            } label: {
                                HStack {
                                    Text(
                                        colorScheme == 0
                                            ? "Clair" : (colorScheme == 1 ? "Sombre" : "Système"))
                                    Image(systemName: "gear")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(sectionBackground)
                    .cornerRadius(10)
                }

                // Préférences Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.accentColor)
                        Text("Préférences")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Sauvegarde automatique")
                                    .foregroundColor(.primary)
                                Text("Sauvegarder automatiquement les modifications")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $autoSave)
                                .labelsHidden()
                        }
                    }
                    .padding()
                    .background(sectionBackground)
                    .cornerRadius(10)
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
