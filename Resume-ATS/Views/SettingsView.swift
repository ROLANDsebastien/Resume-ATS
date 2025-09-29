import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Binding var selectedSection: String?
    @Environment(\.colorScheme) private var systemColorScheme
    @AppStorage("colorScheme") private var colorScheme: Int = 2  // 0: Light, 1: Dark, 2: System
    @AppStorage("autoSave") private var autoSave = true
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @Query private var applications: [Application]

    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingClearDataConfirmation = false

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
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(sectionBackground)
                    .cornerRadius(10)
                }

                // Sauvegarde et Restauration Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("Sauvegarde et Restauration")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Exporter les données")
                                    .foregroundColor(.primary)
                                Text("Sauvegarder profils, candidatures et documents joints")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Exporter") {
                                exportProfiles()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Importer les données")
                                    .foregroundColor(.primary)
                                Text("Restaurer profils, candidatures et documents joints")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Importer") {
                                importProfiles()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Effacer toutes les données")
                                    .foregroundColor(.red)
                                Text("Supprimer définitivement tous les profils et candidatures")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Effacer") {
                                showingClearDataConfirmation = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
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
        .alert("Export réussi", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Les profils ont été exportés avec succès.")
        }
        .alert("Import réussi", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Les profils ont été importés avec succès.")
        }
        .alert("Erreur", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Confirmer la suppression", isPresented: $showingClearDataConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Effacer définitivement", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text(
                "Cette action supprimera définitivement tous les profils, candidatures et documents joints. Cette action est irréversible."
            )
        }
        .navigationTitle("Resume-ATS")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    selectedSection = "Dashboard"
                }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }

    private func exportProfiles() {
        guard let zipURL = DataService.exportProfiles(profiles, applications: applications) else {
            errorMessage = "Erreur lors de l'exportation des données."
            showingError = true
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.zip]
        savePanel.nameFieldStringValue =
            "ResumeATS_Backup_\(Date().formatted(.iso8601.dateSeparator(.dash)))"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    // Copier le fichier ZIP vers l'emplacement choisi
                    if FileManager.default.fileExists(atPath: url.path) {
                        try FileManager.default.removeItem(at: url)
                    }
                    try FileManager.default.copyItem(at: zipURL, to: url)

                    // Nettoyer le fichier temporaire
                    try FileManager.default.removeItem(at: zipURL)

                    showingExportSuccess = true
                } catch {
                    errorMessage =
                        "Erreur lors de la sauvegarde du fichier: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func importProfiles() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.zip]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    try DataService.importProfiles(from: url, context: modelContext)
                    showingImportSuccess = true
                } catch {
                    errorMessage = "Erreur lors de l'importation: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func clearAllData() {
        do {
            try DataService.clearAllData(context: modelContext)
            // Afficher un message de succès
            showingImportSuccess = true
        } catch {
            errorMessage =
                "Erreur lors de la suppression des données: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(selectedSection: .constant(nil))
    }
}
