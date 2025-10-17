//
//  ContentView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct TemplatesView: View {
    @Binding var selectedSection: String?
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @State private var selectedProfile: Profile?
    var language: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(language == "fr" ? "Modèles de CV" : "CV Templates")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                 // Profile selector
                 VStack(alignment: .leading) {
                     Text(language == "fr" ? "Sélectionner un profil:" : "Select a profile:")
                         .font(.headline)
                     Picker(language == "fr" ? "Profil" : "Profile", selection: $selectedProfile) {
                         Text(language == "fr" ? "Choisir un profil" : "Choose a profile").tag(
                             nil as Profile?)
                         ForEach(profiles) { profile in
                             Text(profile.name).tag(profile as Profile?)
                         }
                     }
                     .pickerStyle(MenuPickerStyle())
                     .frame(maxWidth: 300)
                 }
                 .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 40), GridItem(.flexible(), spacing: 40), GridItem(.flexible())], spacing: 60) {
                    DashboardTile(
                        title: language == "fr" ? "Modèle ATS" : "ATS Template",
                        subtitle: language == "fr"
                            ? "Optimisé pour les filtres ATS" : "Optimized for ATS filters",
                        systemImage: "doc",
                        action: {
                            guard let profile = selectedProfile else { return }
                            PDFService.generateATSResumePDFWithPagination(for: profile) { pdfURL in
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
                        title: language == "fr" ? "Modèle Moderne" : "Modern Template",
                        subtitle: language == "fr" ? "Design contemporain" : "Contemporary design",
                        systemImage: "doc.fill"
                    ) {
                        // Action to select modern template
                    }

                    DashboardTile(
                        title: language == "fr" ? "Modèle Créatif" : "Creative Template",
                        subtitle: language == "fr"
                            ? "Pour postes créatifs" : "For creative positions",
                        systemImage: "paintbrush"
                    ) {
                        // Action to select creative template
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(.regularMaterial)
        .navigationTitle("Resume-ATS")
        .environment(\.locale, Locale(identifier: selectedProfile?.language ?? "fr"))
        .environment(\.locale, Locale(identifier: "fr"))
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
    @AppStorage("appLanguage") private var appLanguage: String = "fr"
    @State private var sidebarWidth: CGFloat = 200

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                Section {
                    Button(action: {
                        sidebarWidth = sidebarWidth == 0 ? 200 : 0
                    }) {
                        Image(systemName: "sidebar.left")
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                NavigationLink(value: "Dashboard") {
                    Label(appLanguage == "fr" ? "Dashboard" : "Dashboard", systemImage: "house")
                }
                NavigationLink(value: "Profile") {
                    Label(appLanguage == "fr" ? "Profil" : "Profile", systemImage: "person")
                }
                NavigationLink(value: "Candidatures") {
                    Label(
                        appLanguage == "fr" ? "Candidatures" : "Applications",
                        systemImage: "briefcase")
                }
                NavigationLink(value: "Lettres") {
                    Label(
                        appLanguage == "fr" ? "Lettres de Motivation" : "Cover Letters",
                        systemImage: "doc.text")
                }
                NavigationLink(value: "Templates") {
                    Label(appLanguage == "fr" ? "Templates" : "Templates", systemImage: "doc")
                }
                NavigationLink(value: "Statistiques") {
                    Label(
                        appLanguage == "fr" ? "Statistiques" : "Statistics",
                        systemImage: "chart.bar")
                }
                NavigationLink(value: "Settings") {
                    Label(appLanguage == "fr" ? "Réglages" : "Settings", systemImage: "gear")
                }
            }
            .navigationTitle(appLanguage == "fr" ? "Sections" : "Sections")
            .navigationSplitViewColumnWidth(min: 0, ideal: sidebarWidth, max: .infinity)
        } detail: {
            switch selectedSection {
            case "Dashboard":
                DashboardView(selectedSection: $selectedSection, language: appLanguage)
            case "Profile":
                ProfileView(selectedSection: $selectedSection)
            case "Candidatures":
                CandidaturesView(selectedSection: $selectedSection, language: appLanguage)
            case "Lettres":
                CoverLettersView(selectedSection: $selectedSection, language: appLanguage)
            case "Templates":
                TemplatesView(selectedSection: $selectedSection, language: appLanguage)
            case "Statistiques":
                StatistiquesView(selectedSection: $selectedSection, language: appLanguage)
            case "Settings":
                SettingsView(selectedSection: $selectedSection)
            default:
                Text("Select a section")
            }
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.locale, Locale(identifier: appLanguage))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Profile.self, inMemory: true)
}
