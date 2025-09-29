//
//  ContentView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ApplicationsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Suivi des Candidatures")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    DashboardTile(
                        title: "Nouvelle Candidature",
                        subtitle: "Ajouter une nouvelle candidature",
                        systemImage: "plus"
                    ) {
                        // Action to add new application
                    }

                    DashboardTile(
                        title: "Candidatures en Cours",
                        subtitle: "Voir les candidatures actives",
                        systemImage: "briefcase"
                    ) {
                        // Action to view active applications
                    }

                    DashboardTile(
                        title: "Candidatures Archivée",
                        subtitle: "Historique des candidatures",
                        systemImage: "archivebox"
                    ) {
                        // Action to view archived applications
                    }
                }
                .padding(.horizontal)
            }
        }

    }
}

struct TemplatesView: View {
    @Binding var selectedSection: String?
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @State private var selectedProfile: Profile?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Modèles de CV")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // Profile selector
                VStack(alignment: .leading) {
                    Text("Sélectionner un profil:")
                        .font(.headline)
                    Picker("Profil", selection: $selectedProfile) {
                        Text("Choisir un profil").tag(nil as Profile?)
                        ForEach(profiles) { profile in
                            Text(profile.name).tag(profile as Profile?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 300)
                }
                .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    DashboardTile(
                        title: "Modèle ATS",
                        subtitle: "Optimisé pour les filtres ATS",
                        systemImage: "doc",
                        action: {
                            guard let profile = selectedProfile else { return }
                            PDFService.generateATSResumePDF(for: profile) { pdfURL in
                                if let pdfURL = pdfURL {
                                    DispatchQueue.main.async {
                                        NSWorkspace.shared.open(pdfURL)
                                    }
                                }
                            }
                        },
                        isEnabled: selectedProfile != nil
                    )

                    DashboardTile(
                        title: "Modèle Moderne",
                        subtitle: "Design contemporain",
                        systemImage: "doc.fill"
                    ) {
                        // Action to select modern template
                    }

                    DashboardTile(
                        title: "Modèle Créatif",
                        subtitle: "Pour postes créatifs",
                        systemImage: "paintbrush"
                    ) {
                        // Action to select creative template
                    }
                }
                .padding(.horizontal)
            }
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

}

struct ContentView: View {
    @State private var selectedSection: String? = "Dashboard"

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                NavigationLink(value: "Dashboard") {
                    Label("Dashboard", systemImage: "house")
                }
                NavigationLink(value: "Profile") {
                    Label("Profile", systemImage: "person")
                }
                NavigationLink(value: "Candidatures") {
                    Label("Candidatures", systemImage: "briefcase")
                }
                NavigationLink(value: "Lettres") {
                    Label("Lettres de Motivation", systemImage: "doc.text")
                }
                NavigationLink(value: "Templates") {
                    Label("Templates", systemImage: "doc")
                }
                NavigationLink(value: "Statistiques") {
                    Label("Statistiques", systemImage: "chart.bar")
                }
                NavigationLink(value: "Settings") {
                    Label("Réglages", systemImage: "gear")
                }
            }
            .navigationTitle("Sections")
        } detail: {
            switch selectedSection {
            case "Dashboard":
                DashboardView(selectedSection: $selectedSection)
            case "Profile":
                ProfileView(selectedSection: $selectedSection)
            case "Candidatures":
                CandidaturesView(selectedSection: $selectedSection)
            case "Lettres":
                CoverLettersView(selectedSection: $selectedSection)
            case "Templates":
                TemplatesView(selectedSection: $selectedSection)
            case "Statistiques":
                StatistiquesView(selectedSection: $selectedSection)
            case "Settings":
                SettingsView(selectedSection: $selectedSection)
            default:
                Text("Select a section")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Profile.self, inMemory: true)
}
