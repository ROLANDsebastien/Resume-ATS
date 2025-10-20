import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Binding var selectedSection: String?
    @Environment(\.colorScheme) private var systemColorScheme
    @AppStorage("colorScheme") private var colorScheme: Int = 2  // 0: Light, 1: Dark, 2: System
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("appLanguage") private var appLanguage: String = "fr"
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @Query private var applications: [Application]
    @Query private var coverLetters: [CoverLetter]
    @Query private var cvDocuments: [CVDocument]

    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingClearDataConfirmation = false



    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(appLanguage == "fr" ? "Réglages" : "Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top)

                // Apparence Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.accentColor)
                        Text(appLanguage == "fr" ? "Apparence" : "Appearance")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(appLanguage == "fr" ? "Thème" : "Theme")
                                    .foregroundColor(.primary)
                                Text(
                                    appLanguage == "fr"
                                        ? "Mode clair ou sombre" : "Light or dark mode"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Menu {
                                Button(
                                    appLanguage == "fr" ? "Clair" : "Light",
                                    action: { colorScheme = 0 })
                                Button(
                                    appLanguage == "fr" ? "Sombre" : "Dark",
                                    action: { colorScheme = 1 })
                                Button(
                                    appLanguage == "fr" ? "Système" : "System",
                                    action: { colorScheme = 2 })
                            } label: {
                                HStack {
                                    Text(
                                        colorScheme == 0
                                            ? (appLanguage == "fr" ? "Clair" : "Light")
                                            : (colorScheme == 1
                                                ? (appLanguage == "fr" ? "Sombre" : "Dark")
                                                : (appLanguage == "fr" ? "Système" : "System")))
                                    Image(systemName: "gear")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text(appLanguage == "fr" ? "Langue de l'app" : "App Language")
                                    .foregroundColor(.primary)
                                Text(
                                    appLanguage == "fr"
                                        ? "Langue de l'interface de l'app"
                                        : "Language of the app interface"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Menu {
                                Button("Français", action: { appLanguage = "fr" })
                                Button("English", action: { appLanguage = "en" })
                            } label: {
                                HStack {
                                    Text(appLanguage == "fr" ? "Français" : "English")
                                    Image(systemName: "globe")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                }

                // Préférences Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.accentColor)
                        Text(appLanguage == "fr" ? "Préférences" : "Preferences")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(appLanguage == "fr" ? "Sauvegarde automatique" : "Auto Save")
                                    .foregroundColor(.primary)
                                Text(
                                    appLanguage == "fr"
                                        ? "Sauvegarder automatiquement les modifications"
                                        : "Automatically save changes"
                                )
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
                    .background(.regularMaterial)
                    .cornerRadius(10)
                }

                // Sauvegarde et Restauration Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .foregroundColor(.accentColor)
                        Text(
                            appLanguage == "fr"
                                ? "Sauvegarde et Restauration" : "Backup and Restore"
                        )
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(appLanguage == "fr" ? "Exporter les données" : "Export Data")
                                    .foregroundColor(.primary)
                                Text(
                                    appLanguage == "fr"
                                        ? "Sauvegarder profils, candidatures, CVs et documents joints"
                                        : "Backup profiles, applications, CVs and attached documents"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(appLanguage == "fr" ? "Exporter" : "Export") {
                                exportProfiles()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text(appLanguage == "fr" ? "Importer les données" : "Import Data")
                                    .foregroundColor(.primary)
                                Text(
                                    appLanguage == "fr"
                                        ? "Restaurer profils, candidatures, CVs et documents joints"
                                        : "Restore profiles, applications, CVs and attached documents"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(appLanguage == "fr" ? "Importer" : "Import") {
                                importProfiles()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text(
                                    appLanguage == "fr"
                                        ? "Effacer toutes les données" : "Clear All Data"
                                )
                                .foregroundColor(.red)
                                Text(
                                    appLanguage == "fr"
                                        ? "Supprimer définitivement tous les profils, candidatures et CVs"
                                        : "Permanently delete all profiles, applications and CVs"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(appLanguage == "fr" ? "Effacer" : "Clear") {
                                showingClearDataConfirmation = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .alert(
            appLanguage == "fr" ? "Export réussi" : "Export Successful",
            isPresented: $showingExportSuccess
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                appLanguage == "fr"
                    ? "Les profils ont été exportés avec succès."
                    : "Profiles have been exported successfully.")
        }
        .alert(
            appLanguage == "fr" ? "Import réussi" : "Import Successful",
            isPresented: $showingImportSuccess
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                appLanguage == "fr"
                    ? "Les profils ont été importés avec succès."
                    : "Profiles have been imported successfully.")
        }
        .alert(appLanguage == "fr" ? "Erreur" : "Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert(
            appLanguage == "fr" ? "Confirmer la suppression" : "Confirm Deletion",
            isPresented: $showingClearDataConfirmation
        ) {
            Button(appLanguage == "fr" ? "Annuler" : "Cancel", role: .cancel) {}
            Button(
                appLanguage == "fr" ? "Effacer définitivement" : "Delete Permanently",
                role: .destructive
            ) {
                clearAllData()
            }
        } message: {
            Text(
                appLanguage == "fr"
                    ? "Cette action supprimera définitivement tous les profils, candidatures, CVs et documents joints. Cette action est irréversible."
                    : "This action will permanently delete all profiles, applications, CVs and attached documents. This action is irreversible."
            )
        }
        .navigationTitle("Resume-ATS")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { selectedSection = "Dashboard" }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }

    private func exportProfiles() {
        guard
            let zipURL = DataService.exportProfiles(
                profiles, coverLetters: coverLetters, applications: applications, cvDocuments: cvDocuments)
        else {
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