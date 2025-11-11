//
//  ContentView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import Combine
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
        List {
            Section {
                VStack(spacing: 20) {
                    Text(language == "fr" ? "Modèles de CV" : "CV Templates")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    // Profile selector
                    VStack(alignment: .leading) {
                        Text(language == "fr" ? "Sélectionner un profil:" : "Select a profile:")
                            .font(.headline)
                        Picker(language == "fr" ? "Profil" : "Profile", selection: $selectedProfile)
                        {
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

                    VStack(spacing: 20) {
                        DashboardTile(
                            title: language == "fr" ? "Modèle ATS" : "ATS Template",
                            subtitle: language == "fr"
                                ? "Optimisé pour les filtres ATS" : "Optimized for ATS filters",
                            systemImage: "doc",
                            action: {
                                guard let profile = selectedProfile else { return }
                                PDFService.generateATSResumePDFWithPagination(for: profile) {
                                    pdfURL in
                                    if let pdfURL = pdfURL {
                                        DispatchQueue.main.async {
                                            NSWorkspace.shared.open(pdfURL)
                                        }
                                    }
                                }
                            },
                            isEnabled: selectedProfile != nil
                        )
                    }
                    .padding(.horizontal, 20)
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .navigationTitle("Resume-ATS")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { selectedSection = "Dashboard" }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .environment(\.locale, Locale(identifier: selectedProfile?.language ?? language))

    }

}

struct ContentView: View {
    @State private var selectedSection: String? = "Dashboard"
    @AppStorage("appLanguage") private var appLanguage: String = "fr"
    @AppStorage("autoSave") private var autoSave = true
    @Environment(\.modelContext) private var modelContext
    @State private var autoSaveTimer: Timer?
    @State private var lastSaveTime: Date?
    @State private var saveErrorCount = 0

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
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
                NavigationLink(value: "CVs") {
                    Label(appLanguage == "fr" ? "CVs" : "CVs", systemImage: "doc.fill")
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
            .frame(minWidth: 220)
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
            case "CVs":
                CVsView(selectedSection: $selectedSection, language: appLanguage)
            case "Statistiques":
                StatistiquesView(selectedSection: $selectedSection, language: appLanguage)
            case "Settings":
                SettingsView(selectedSection: $selectedSection)
            default:
                Text("Select a section")
            }
        }
        .navigationSplitViewStyle(.automatic)
        .environment(\.locale, Locale(identifier: appLanguage))
        .onAppear {
            if autoSave {
                startAutoSave()
            }
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
        }
        .onReceive(
            Timer.publish(every: 30, on: .main, in: .common).autoconnect(),
            perform: { _ in
                if autoSave {
                    autoSaveData()
                }
            }
        )
    }

    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            autoSaveData()
        }
    }

    private func autoSaveData() {
        do {
            // Check if there are changes before saving to avoid unnecessary operations
            if modelContext.hasChanges {
                try modelContext.save()
                lastSaveTime = Date()
                saveErrorCount = 0

                let timeString = Date().formatted(date: .abbreviated, time: .standard)
                print("✅ Sauvegarde réussie à \(timeString)")

                // Create a backup periodically
                DispatchQueue.global(qos: .background).async {
                    _ = DatabaseBackupService.shared.createBackup(reason: "Auto-save")
                }
            }
        } catch {
            saveErrorCount += 1
            print("⚠️  Erreur lors de la sauvegarde (tentative \(saveErrorCount)): \(error)")

            // Si trop d'erreurs consécutives, logger plus de détails
            if saveErrorCount >= 3 {
                print("🚨 ATTENTION: Multiples erreurs de sauvegarde détectées!")
                print(
                    "   Dernière tentative: \(Date().formatted(date: .abbreviated, time: .standard))"
                )
                print("   Erreur: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Profile.self, Application.self, CoverLetter.self, CVDocument.self], inMemory: true
        )
}
