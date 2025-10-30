//
//  DatabaseRecoveryView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 28/09/2025.
//

import SwiftUI

struct DatabaseRecoveryView: View {
    @State private var availableVersions: [DatabaseVersion] = []
    @State private var isLoading = false
    @State private var selectedVersion: DatabaseVersion?
    @State private var showingConfirmation = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var successMessage: String?
    @State private var showingSuccess = false
    @State private var showDiagnostics = false
    @Environment(\.dismiss) private var dismiss

    var language: String

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text(language == "fr" ? "Restaurer la Base de Données" : "Restore Database")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(
                    language == "fr"
                        ? "Sélectionnez une version antérieure à restaurer"
                        : "Select a previous version to restore"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.controlBackgroundColor))
            .border(Color.gray.opacity(0.2), width: 1)

            if isLoading {
                VStack {
                    ProgressView()
                    Text(language == "fr" ? "Chargement des versions..." : "Loading versions...")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if availableVersions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text(
                        language == "fr"
                            ? "Aucune version disponible"
                            : "No versions available"
                    )
                    .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            language == "fr"
                                ? "Cela peut signifier:"
                                : "This could mean:"
                        )
                        .font(.caption)
                        .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                language == "fr"
                                    ? "• Aucune donnée n'a encore été sauvegardée"
                                    : "• No data has been saved yet"
                            )
                            .font(.caption)

                            Text(
                                language == "fr"
                                    ? "• Tous les backups ont été supprimés"
                                    : "• All backups have been deleted"
                            )
                            .font(.caption)

                            Text(
                                language == "fr"
                                    ? "• Les backups sont vides ou corrompus"
                                    : "• Backups are empty or corrupted"
                            )
                            .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(4)

                    Text(
                        language == "fr"
                            ? "L'application créera des versions de secours lors de la prochaine utilisation avec des données."
                            : "The application will create backup versions when data is saved."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                    Button(action: { showDiagnostics = true }) {
                        Label(
                            language == "fr" ? "Afficher les infos" : "Show Info",
                            systemImage: "info.circle"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(availableVersions, selection: $selectedVersion) { version in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(
                                    version.dateCreated.formatted(
                                        date: .abbreviated, time: .omitted)
                                )
                                .font(.body)
                                .fontWeight(.medium)

                                Text(version.dateCreated.formatted(date: .omitted, time: .standard))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(version.fileSizeFormatted)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if version == selectedVersion {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .tag(version)
                }
                .listStyle(.inset)
            }

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text(language == "fr" ? "Fermer" : "Close")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                if !availableVersions.isEmpty {
                    Button(action: {
                        if selectedVersion != nil {
                            showingConfirmation = true
                        }
                    }) {
                        Text(language == "fr" ? "Restaurer" : "Restore")
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedVersion == nil)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .border(Color.gray.opacity(0.2), width: 1)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            loadVersions()
        }
        .alert(
            language == "fr" ? "Confirmer la restauration" : "Confirm Restoration",
            isPresented: $showingConfirmation
        ) {
            Button(language == "fr" ? "Annuler" : "Cancel", role: .cancel) {}
            Button(language == "fr" ? "Restaurer" : "Restore", role: .destructive) {
                restoreSelectedVersion()
            }
        } message: {
            Text(
                language == "fr"
                    ? "Êtes-vous sûr de vouloir restaurer cette version ? Un backup de la version actuelle sera créé."
                    : "Are you sure you want to restore this version? A backup of the current version will be created."
            )
        }
        .alert(
            language == "fr" ? "Erreur" : "Error",
            isPresented: $showingError
        ) {
            Button(language == "fr" ? "OK" : "OK") {}
        } message: {
            Text(
                errorMessage
                    ?? (language == "fr" ? "Une erreur s'est produite" : "An error occurred"))
        }
        .alert(
            language == "fr" ? "Succès" : "Success",
            isPresented: $showingSuccess
        ) {
            Button(language == "fr" ? "OK" : "OK") {
                dismiss()
            }
        } message: {
            Text(
                successMessage
                    ?? (language == "fr"
                        ? "Base de données restaurée avec succès"
                        : "Database restored successfully"))
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView(language: language)
        }
    }

    private func loadVersions() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let versions = DatabaseVersioningService.shared.listAvailableVersions()
            DispatchQueue.main.async {
                self.availableVersions = versions
                if !versions.isEmpty {
                    self.selectedVersion = versions.first
                }
                isLoading = false
            }
        }
    }

    private func restoreSelectedVersion() {
        guard let version = selectedVersion else { return }

        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try DatabaseVersioningService.shared.restoreVersion(version)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.successMessage =
                        language == "fr"
                        ? "Base de données restaurée avec succès. L'application va se redémarrer..."
                        : "Database restored successfully. The application will restart..."
                    self.showingSuccess = true

                    // Redémarrer l'application après un délai
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        NSApplication.shared.terminate(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}

struct DiagnosticsView: View {
    let language: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language == "fr" ? "Informations de Diagnostic" : "Diagnostic Information")
                    .font(.headline)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text(language == "fr" ? "Chemin des données:" : "Data Path:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("~/Library/Application Support/com.sebastienroland.Resume-ATS/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Text(language == "fr" ? "Chemin des backups:" : "Backup Path:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("~/Library/Application Support/ResumeATS_DBVersions/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Divider()

                    Text(language == "fr" ? "Points importants:" : "Important Notes:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            language == "fr"
                                ? "• Les backups ne sont créés que si la BD contient des données"
                                : "• Backups are only created if the database contains data"
                        )
                        .font(.caption)

                        Text(
                            language == "fr"
                                ? "• Les backups vides ou corrompus sont automatiquement ignorés"
                                : "• Empty or corrupted backups are automatically ignored"
                        )
                        .font(.caption)

                        Text(
                            language == "fr"
                                ? "• Maximum 20 versions sont conservées"
                                : "• Maximum 20 versions are kept"
                        )
                        .font(.caption)

                        Text(
                            language == "fr"
                                ? "• Un backup est créé toutes les heures et avant arrière-plan"
                                : "• A backup is created every hour and before background"
                        )
                        .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Spacer()

            Button(language == "fr" ? "Fermer" : "Close") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct DatabaseRecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        DatabaseRecoveryView(language: "fr")
    }
}
