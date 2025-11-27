import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Binding var selectedSection: String?
    @Environment(\.colorScheme) private var systemColorScheme
    @AppStorage("colorScheme") private var colorScheme: Int = 2
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("appLanguage") private var appLanguage: String = "fr"
    @AppStorage("selectedAIModel") private var selectedAIModel: String = "gemini"
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
    @State private var availableBackups: [URL] = []
    @State private var selectedBackup: URL?
    @State private var showingRestoreConfirmation = false
    @State private var showingRestoreRequiresRestart = false
    @State private var showingDeleteBackupConfirmation = false
    @State private var backupToDelete: URL?
    @AppStorage("pendingRestoreBackupPath") private var pendingRestoreBackupPath: String = ""

    private var cardBackgroundColor: Color {
        systemColorScheme == .light
            ? Color(red: 0.95, green: 0.95, blue: 0.97)
            : Color(NSColor.controlBackgroundColor).opacity(0.5)
    }

    private var smallButtonBackgroundColor: Color {
        systemColorScheme == .light
            ? Color(red: 0.92, green: 0.92, blue: 0.94)
            : Color(NSColor.controlBackgroundColor).opacity(0.6)
    }

    private var sectionBackgroundColor: Color {
        systemColorScheme == .light
            ? Color(red: 0.96, green: 0.96, blue: 0.98)
            : Color(NSColor.controlBackgroundColor).opacity(0.3)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                appearanceSection
                preferencesSection
                dataSection
                backupsSection
                Spacer().frame(height: 20)
            }
            .padding()
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { selectedSection = "Dashboard" }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .onAppear {
            loadAvailableBackups()
        }
        // Alerts
        .alert(
            appLanguage == "fr" ? "Export réussi" : "Export Successful",
            isPresented: $showingExportSuccess
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                appLanguage == "fr"
                    ? "Les données ont été exportées avec succès."
                    : "Data has been exported successfully.")
        }
        .alert(
            appLanguage == "fr" ? "Import réussi" : "Import Successful",
            isPresented: $showingImportSuccess
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                appLanguage == "fr"
                    ? "Les données ont été importées avec succès."
                    : "Data has been imported successfully.")
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
                    ? "Cette action supprimera définitivement tous les profils, candidatures, CVs et documents. Cette action est irréversible."
                    : "This action will permanently delete all profiles, applications, CVs and documents. This action is irreversible."
            )
        }
        .alert(
            appLanguage == "fr" ? "Confirmer la restauration" : "Confirm Restore",
            isPresented: $showingRestoreConfirmation
        ) {
            Button(appLanguage == "fr" ? "Annuler" : "Cancel", role: .cancel) {}
            Button(appLanguage == "fr" ? "Restaurer" : "Restore", role: .destructive) {
                restoreSelectedBackup()
            }
        } message: {
            Text(
                appLanguage == "fr"
                    ? "Cette action va restaurer la sauvegarde sélectionnée. Vous devrez redémarrer l'application pour charger les données restaurées."
                    : "This action will restore the selected backup. You must restart the application to load the restored data."
            )
        }
        .alert(
            appLanguage == "fr" ? "Restauration programmée" : "Restore Scheduled",
            isPresented: $showingRestoreRequiresRestart
        ) {
            Button(
                appLanguage == "fr" ? "Redémarrer maintenant" : "Restart Now", role: .destructive
            ) {
                NSApplication.shared.terminate(nil)
            }
            Button(appLanguage == "fr" ? "Plus tard" : "Later", role: .cancel) {}
        } message: {
            Text(
                appLanguage == "fr"
                    ? "La restauration a été programmée pour le prochain démarrage de l'application. Veuillez redémarrer l'application pour restaurer la sauvegarde."
                    : "The restore has been scheduled for the next app startup. Please restart the application to restore the backup."
            )
        }
        .alert(
            appLanguage == "fr" ? "Confirmer la suppression" : "Confirm Delete Backup",
            isPresented: $showingDeleteBackupConfirmation
        ) {
            Button(appLanguage == "fr" ? "Annuler" : "Cancel", role: .cancel) {}
            Button(appLanguage == "fr" ? "Supprimer" : "Delete", role: .destructive) {
                deleteSelectedBackup()
            }
        } message: {
            Text(
                appLanguage == "fr"
                    ? "Cette action supprimera définitivement cette sauvegarde. Cette action est irréversible."
                    : "This action will permanently delete this backup. This action is irreversible."
            )
        }
    }

    // MARK: - View Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appLanguage == "fr" ? "Réglages" : "Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(
                appLanguage == "fr" ? "Personnalisez votre expérience" : "Customize your experience"
            )
            .font(.callout)
            .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appLanguage == "fr" ? "Apparence" : "Appearance")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                let themeSubtitle =
                    colorScheme == 0
                    ? (appLanguage == "fr" ? "Clair" : "Light")
                    : (colorScheme == 1
                        ? (appLanguage == "fr" ? "Sombre" : "Dark")
                        : (appLanguage == "fr" ? "Système" : "System"))

                SettingCard(
                    icon: "paintbrush",
                    title: appLanguage == "fr" ? "Thème" : "Theme", subtitle: themeSubtitle
                ) {
                    themeMenu
                }

                SettingCard(
                    icon: "globe",
                    title: appLanguage == "fr" ? "Langue" : "Language",
                    subtitle: appLanguage == "fr" ? "Français" : "English"
                ) {
                    languageMenu
                }
            }
        }
    }

    private var themeMenu: some View {
        let themeTitle =
            colorScheme == 0
            ? (appLanguage == "fr" ? "Clair" : "Light")
            : (colorScheme == 1
                ? (appLanguage == "fr" ? "Sombre" : "Dark")
                : (appLanguage == "fr" ? "Système" : "System"))

        return Menu {
            Button(
                action: { colorScheme = 0 },
                label: {
                    HStack {
                        Text(appLanguage == "fr" ? "Clair" : "Light")
                        if colorScheme == 0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            )
            Button(
                action: { colorScheme = 1 },
                label: {
                    HStack {
                        Text(appLanguage == "fr" ? "Sombre" : "Dark")
                        if colorScheme == 1 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            )
            Button(
                action: { colorScheme = 2 },
                label: {
                    HStack {
                        Text(appLanguage == "fr" ? "Système" : "System")
                        if colorScheme == 2 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            )
        } label: {
            Text(themeTitle)
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(smallButtonBackgroundColor)
                .cornerRadius(6)
        }
    }

    private var languageMenu: some View {
        let languageTitle = appLanguage == "fr" ? "Français" : "English"

        return Menu {
            Button(
                action: { appLanguage = "fr" },
                label: {
                    HStack {
                        Text("Français")
                        if appLanguage == "fr" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            )
            Button(
                action: { appLanguage = "en" },
                label: {
                    HStack {
                        Text("English")
                        if appLanguage == "en" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            )
        } label: {
            Text(languageTitle)
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(smallButtonBackgroundColor)
                .cornerRadius(6)
}
    }
    
    private var aiModelMenu: some View {
        let aiModelTitle = selectedAIModel == "gemini" 
            ? (appLanguage == "fr" ? "Google Gemini" : "Google Gemini")
            : (appLanguage == "fr" ? "Qwen Code" : "Qwen Code")

        return Menu {
            Button(
                action: { selectedAIModel = "gemini" },
                label: {
                    HStack {
                        Text("Google Gemini")
                        if selectedAIModel == "gemini" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            )
            Button(
                action: { selectedAIModel = "qwen" },
                label: {
                    HStack {
                        Text("Qwen Code")
                        if selectedAIModel == "qwen" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            )
        } label: {
            Text(aiModelTitle)
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(smallButtonBackgroundColor)
                .cornerRadius(6)
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appLanguage == "fr" ? "Préférences" : "Preferences")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            let autoSaveSubtitle =
                autoSave
                ? (appLanguage == "fr" ? "Activée" : "Enabled")
                : (appLanguage == "fr" ? "Désactivée" : "Disabled")

            SettingCard(
                icon: "checkmark.circle",
                title: appLanguage == "fr" ? "Sauvegarde automatique" : "Auto Save",
                subtitle: autoSaveSubtitle
            ) {
                Toggle("", isOn: $autoSave).labelsHidden().toggleStyle(.switch)
            }

            SettingCard(
                icon: "clock.badge.checkmark",
                title: appLanguage == "fr" ? "Sauvegarde horaire" : "Hourly Backup",
                subtitle: appLanguage == "fr" ? "Toutes les heures" : "Every hour"
            ) {
                Image(systemName: "checkmark").foregroundColor(.secondary)
            }
            
            let aiModelSubtitle = selectedAIModel == "gemini" 
                ? (appLanguage == "fr" ? "Google Gemini" : "Google Gemini")
                : (appLanguage == "fr" ? "Qwen Code" : "Qwen Code")
            
            SettingCard(
                icon: "brain",
                title: appLanguage == "fr" ? "Modèle IA" : "AI Model",
                subtitle: aiModelSubtitle
            ) {
                aiModelMenu
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appLanguage == "fr" ? "Données" : "Data")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: exportProfiles) {
                    SettingCard(
                        icon: "arrow.up.circle",
                        title: appLanguage == "fr" ? "Exporter" : "Export",
                        subtitle: appLanguage == "fr" ? "Tous les profils" : "All data"
                    ) {
                        EmptyView()
                    }
                }
                .buttonStyle(.plain)

                Button(action: importProfiles) {
                    SettingCard(
                        icon: "arrow.down.circle",
                        title: appLanguage == "fr" ? "Importer" : "Import",
                        subtitle: appLanguage == "fr" ? "Depuis un fichier" : "From file"
                    ) {
                        EmptyView()
                    }
                }
                .buttonStyle(.plain)
            }

            clearDataButton
        }
    }

    private var clearDataButton: some View {
        Button(action: { showingClearDataConfirmation = true }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.circle.fill").font(.system(size: 20))
                            .foregroundColor(.red)
                        Text(appLanguage == "fr" ? "Effacer toutes les données" : "Clear All Data")
                            .font(.callout).fontWeight(.medium).foregroundColor(.red)
                    }
                    Text(appLanguage == "fr" ? "Action irréversible" : "Irreversible action").font(
                        .caption
                    ).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.08))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var backupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(appLanguage == "fr" ? "Sauvegardes" : "Backups")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(availableBackups.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(smallButtonBackgroundColor)
                    .cornerRadius(6)
                Spacer()
                Button(action: createManualBackup) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(smallButtonBackgroundColor)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help(appLanguage == "fr" ? "Créer une sauvegarde" : "Create backup")
            }
            .padding(.horizontal)

            if availableBackups.isEmpty {
                emptyBackupsView
            } else {
                backupListView
            }
        }
    }

    private var emptyBackupsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark").font(.system(size: 32)).foregroundColor(
                .secondary)
            Text(appLanguage == "fr" ? "Aucune sauvegarde" : "No backups").font(.headline)
                .foregroundColor(.secondary)
            Text(
                appLanguage == "fr"
                    ? "Les sauvegardes apparaîtront ici" : "Backups will appear here"
            ).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(sectionBackgroundColor)
        .cornerRadius(10)
    }

    private var backupListView: some View {
        VStack(spacing: 8) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(availableBackups, id: \.self) { backup in
                        BackupItemView(
                            backup: backup,
                            isSelected: selectedBackup == backup,
                            onSelect: { selectedBackup = backup },
                            onDelete: {
                                backupToDelete = backup
                                showingDeleteBackupConfirmation = true
                            },
                            appLanguage: appLanguage
                        )
                    }
                }
            }
            .frame(maxHeight: 250)

            HStack(spacing: 10) {
                Button(action: loadAvailableBackups) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text(appLanguage == "fr" ? "Actualiser" : "Refresh")
                    }
                    .font(.callout)
                }
                .buttonStyle(.bordered)

                Spacer()

                if selectedBackup != nil {
                    Button(action: { showingRestoreConfirmation = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text(appLanguage == "fr" ? "Restaurer" : "Restore")
                        }
                        .font(.callout)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text(appLanguage == "fr" ? "Restaurer" : "Restore")
                        }
                        .font(.callout)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(true)
                }
            }
        }
        .padding()
        .background(sectionBackgroundColor)
        .cornerRadius(10)
    }

    // MARK: - Actions

    private func exportProfiles() {
        guard
            let zipURL = DataService.exportProfiles(
                profiles, coverLetters: coverLetters, applications: applications,
                cvDocuments: cvDocuments)
        else {
            errorMessage =
                appLanguage == "fr"
                ? "Erreur lors de l'exportation des données." : "Error exporting data."
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
                    if FileManager.default.fileExists(atPath: url.path) {
                        try FileManager.default.removeItem(at: url)
                    }
                    try FileManager.default.copyItem(at: zipURL, to: url)
                    try FileManager.default.removeItem(at: zipURL)
                    showingExportSuccess = true
                } catch {
                    errorMessage =
                        appLanguage == "fr"
                        ? "Erreur lors de la sauvegarde du fichier: \(error.localizedDescription)"
                        : "Error saving file: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func importProfiles() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.zip]
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    try DataService.importProfiles(from: url, context: modelContext)
                    showingImportSuccess = true
                } catch {
                    errorMessage =
                        appLanguage == "fr"
                        ? "Erreur lors de l'importation: \(error.localizedDescription)"
                        : "Error importing: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func clearAllData() {
        do {
            try DataService.clearAllData(context: modelContext)
            showingImportSuccess = true
        } catch {
            errorMessage =
                appLanguage == "fr"
                ? "Erreur lors de la suppression des données: \(error.localizedDescription)"
                : "Error deleting data: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func loadAvailableBackups() {
        availableBackups = DatabaseBackupService.shared.listBackups()
    }

    private func restoreSelectedBackup() {
        guard let backup = selectedBackup else { return }
        pendingRestoreBackupPath = backup.path
        DispatchQueue.main.async {
            showingRestoreRequiresRestart = true
        }
    }

    private func deleteSelectedBackup() {
        guard let backup = backupToDelete else { return }

        do {
            let fileManager = FileManager.default
            try fileManager.removeItem(at: backup)

            let walPath = URL(fileURLWithPath: backup.path + "-wal")
            let shmPath = URL(fileURLWithPath: backup.path + "-shm")

            if fileManager.fileExists(atPath: walPath.path) {
                try fileManager.removeItem(at: walPath)
            }

            if fileManager.fileExists(atPath: shmPath.path) {
                try fileManager.removeItem(at: shmPath)
            }

            if selectedBackup == backup {
                selectedBackup = nil
            }

            loadAvailableBackups()

            let alert = NSAlert()
            alert.messageText = appLanguage == "fr" ? "Supprimée" : "Deleted"
            alert.informativeText =
                appLanguage == "fr"
                ? "La sauvegarde a été supprimée avec succès."
                : "The backup has been deleted successfully."
            alert.runModal()
        } catch {
            errorMessage =
                appLanguage == "fr"
                ? "Erreur lors de la suppression: \(error.localizedDescription)"
                : "Error deleting backup: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func createManualBackup() {
        DispatchQueue.global(qos: .userInitiated).async {
            if DatabaseBackupService.shared.createBackup(
                reason: "Manual backup from settings", modelContext: modelContext) != nil
            {
                DispatchQueue.main.async {
                    loadAvailableBackups()
                    let alert = NSAlert()
                    alert.messageText = appLanguage == "fr" ? "Sauvegarde créée" : "Backup Created"
                    alert.informativeText =
                        appLanguage == "fr"
                        ? "La sauvegarde a été créée avec succès et ajoutée à la liste."
                        : "The backup has been created successfully and added to the list."
                    alert.runModal()
                }
            } else {
                DispatchQueue.main.async {
                    errorMessage =
                        appLanguage == "fr"
                        ? "Impossible de créer la sauvegarde. Une sauvegarde est peut-être déjà en cours."
                        : "Unable to create backup. A backup might already be in progress."
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Setting Card Component
struct SettingCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let content: Content

    init(
        icon: String, title: String, subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    @Environment(\.colorScheme) var colorScheme

    private var backgroundColor: Color {
        colorScheme == .light
            ? Color(red: 0.95, green: 0.95, blue: 0.97)
            : Color(NSColor.controlBackgroundColor).opacity(0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.callout).fontWeight(.semibold).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }

                Spacer()
                content
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Backup Item View
struct BackupItemView: View {
    let backup: URL
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let appLanguage: String

    @Environment(\.colorScheme) var colorScheme
    @State private var backupDate: Date?
    @State private var backupSize: Int = 0
    @State private var showingDeleteConfirmation = false

    private var backgroundColor: Color {
        colorScheme == .light
            ? Color(red: 0.96, green: 0.96, blue: 0.98)
            : Color(NSColor.controlBackgroundColor).opacity(0.3)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.deletingPathExtension().lastPathComponent)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        if let backupDate = backupDate {
                            Label(formatDate(backupDate), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if backupSize > 0 {
                            Label(formatBytes(backupSize), systemImage: "doc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help(appLanguage == "fr" ? "Supprimer cette sauvegarde" : "Delete this backup")
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .background(backgroundColor)
        .cornerRadius(8)
        .onAppear {
            loadBackupInfo()
        }
        .alert(
            appLanguage == "fr" ? "Confirmer la suppression" : "Confirm Deletion",
            isPresented: $showingDeleteConfirmation
        ) {
            Button(appLanguage == "fr" ? "Annuler" : "Cancel", role: .cancel) {}
            Button(appLanguage == "fr" ? "Supprimer" : "Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text(
                appLanguage == "fr"
                    ? "Êtes-vous sûr de vouloir supprimer cette sauvegarde ? Cette action est irréversible."
                    : "Are you sure you want to delete this backup? This action is irreversible."
            )
        }
    }

    private func loadBackupInfo() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: backup.path)
            backupSize = attributes[.size] as? Int ?? 0

            // Try to extract date from filename first (format: db_backup_YYYY-MM-DD_HHmmss)
            let filename = backup.deletingPathExtension().lastPathComponent
            if filename.contains("db_backup_") {
                if let dateString = filename.components(separatedBy: "db_backup_").last {
                    let cleanedDateString = dateString.replacingOccurrences(
                        of: "_CRITICAL", with: "")
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd_HHmmss"
                    if let parsedDate = formatter.date(from: cleanedDateString) {
                        backupDate = parsedDate
                        return
                    }
                }
            }

            // Fallback to file creation date if filename parsing fails
            backupDate = attributes[.creationDate] as? Date
        } catch {
            print("Error loading backup info: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(selectedSection: .constant(nil))
    }
}
