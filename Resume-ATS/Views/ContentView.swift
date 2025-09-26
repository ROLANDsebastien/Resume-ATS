//
//  ContentView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftData
import SwiftUI

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
        .toolbarBackground(.hidden, for: .windowToolbar)
    }
}

struct TemplatesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Modèles de CV")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    DashboardTile(
                        title: "Modèle Classique",
                        subtitle: "CV traditionnel",
                        systemImage: "doc"
                    ) {
                        // Action to select classic template
                    }

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
        .toolbarBackground(.hidden, for: .windowToolbar)
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
                NavigationLink(value: "Applications") {
                    Label("Applications", systemImage: "briefcase")
                }
                NavigationLink(value: "Templates") {
                    Label("Templates", systemImage: "doc")
                }
                NavigationLink(value: "Settings") {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("Sections")
        } detail: {
            switch selectedSection {
            case "Dashboard":
                DashboardView(selectedSection: $selectedSection)
            case "Profile":
                ProfileView()
            case "Applications":
                ApplicationsView()
            case "Templates":
                TemplatesView()
            case "Settings":
                SettingsView()
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
