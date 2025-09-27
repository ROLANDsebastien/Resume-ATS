//
//  CandidaturesView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import SwiftData
import SwiftUI

struct CandidaturesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var applications: [Application]
    @State private var showingAddApplication = false
    @State private var selectedStatus: Application.Status? = nil

    var filteredApplications: [Application] {
        if let status = selectedStatus {
            return applications.filter { $0.status == status }
        } else {
            return applications
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Gestion des Candidatures")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // Status filter
                VStack(alignment: .leading) {
                    Text("Filtrer par statut:")
                        .font(.headline)
                    Picker("Statut", selection: $selectedStatus) {
                        Text("Toutes").tag(nil as Application.Status?)
                        ForEach(Application.Status.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status as Application.Status?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    DashboardTile(
                        title: "Nouvelle Candidature",
                        subtitle: "Ajouter une nouvelle candidature",
                        systemImage: "plus"
                    ) {
                        showingAddApplication = true
                    }

                    DashboardTile(
                        title: "Candidatures en Cours",
                        subtitle: "Voir les candidatures actives",
                        systemImage: "briefcase"
                    ) {
                        selectedStatus = .applied
                    }

                    DashboardTile(
                        title: "Entretiens",
                        subtitle: "Candidatures en entretien",
                        systemImage: "person.2"
                    ) {
                        selectedStatus = .interviewing
                    }

                    DashboardTile(
                        title: "Candidatures Archivée",
                        subtitle: "Historique des candidatures",
                        systemImage: "archivebox"
                    ) {
                        selectedStatus = .rejected
                    }
                }
                .padding(.horizontal)

                // List of applications
                if !filteredApplications.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Candidatures")
                            .font(.title2)
                            .fontWeight(.semibold)
                        ForEach(filteredApplications) { application in
                            ApplicationRow(application: application)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("Aucune candidature trouvée.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .sheet(isPresented: $showingAddApplication) {
            AddApplicationView()
        }
    }
}

struct ApplicationRow: View {
    var application: Application

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(application.position) chez \(application.company)")
                    .font(.headline)
                Text("Statut: \(application.status.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Date: \(application.dateApplied.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            // Could add edit/delete buttons
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AddApplicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var company = ""
    @State private var position = ""
    @State private var dateApplied = Date()
    @State private var status: Application.Status = .applied
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Nouvelle Candidature")
                .font(.title)
                .fontWeight(.bold)

            Form {
                TextField("Entreprise", text: $company)
                TextField("Poste", text: $position)
                DatePicker("Date de candidature", selection: $dateApplied, displayedComponents: .date)
                Picker("Statut", selection: $status) {
                    ForEach(Application.Status.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                TextField("Notes", text: $notes)
            }
            .frame(minWidth: 400, minHeight: 200)

            HStack {
                Button("Annuler") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Ajouter") {
                    let newApplication = Application(
                        company: company,
                        position: position,
                        dateApplied: dateApplied,
                        status: status,
                        notes: notes
                    )
                    modelContext.insert(newApplication)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(company.isEmpty || position.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(minWidth: 450, minHeight: 350)
    }
}

#Preview {
    CandidaturesView()
        .modelContainer(for: [Profile.self, Application.self], inMemory: true)
}