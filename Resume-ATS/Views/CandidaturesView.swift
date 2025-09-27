//
//  CandidaturesView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CandidaturesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var applications: [Application]
    @State private var showingAddApplication = false
    @State private var selectedStatus: Application.Status? = nil
    @State private var editingApplication: Application?
    @State private var showingDocumentsFor: Application?

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
                            ApplicationRow(
                                application: application,
                                onEdit: { editingApplication = application },
                                onDocuments: { showingDocumentsFor = application },
                                onDelete: {
                                    modelContext.delete(application)
                                }
                            )
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
        .sheet(item: $editingApplication) { application in
            EditApplicationView(application: application)
        }
        .sheet(item: $showingDocumentsFor) { application in
            DocumentsView(application: application)
        }
    }
}

struct ApplicationRow: View {
    var application: Application
    var onEdit: () -> Void
    var onDocuments: () -> Void
    var onDelete: () -> Void

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
            HStack(spacing: 10) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                Button(action: onDocuments) {
                    Image(systemName: "doc")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EditApplicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var application: Application

    @State private var company: String
    @State private var position: String
    @State private var dateApplied: Date
    @State private var status: Application.Status
    @State private var notes: String

    init(application: Application) {
        self.application = application
        _company = State(initialValue: application.company)
        _position = State(initialValue: application.position)
        _dateApplied = State(initialValue: application.dateApplied)
        _status = State(initialValue: application.status)
        _notes = State(initialValue: application.notes)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Modifier Candidature")
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
                Button("Sauvegarder") {
                    application.company = company
                    application.position = position
                    application.dateApplied = dateApplied
                    application.status = status
                    application.notes = notes
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

struct DocumentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var application: Application

    @State private var showingFileImporter = false

    private func resolveBookmark(_ bookmark: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
            return url
        } catch {
            print("Error resolving bookmark: \(error)")
            return nil
        }
    }

    private func openBookmark(_ bookmark: Data) {
        if let url = resolveBookmark(bookmark) {
            let accessGranted = url.startAccessingSecurityScopedResource()
            if accessGranted {
                NSWorkspace.shared.open(url)
                url.stopAccessingSecurityScopedResource()
            } else {
                print("Access not granted for opening")
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Documents pour \(application.position) chez \(application.company)")
                .font(.title)
                .fontWeight(.bold)

            List {
                ForEach(application.documentBookmarks ?? [], id: \.self) { bookmark in
                    HStack {
                        if let url = resolveBookmark(bookmark) {
                            Text(url.lastPathComponent)
                            Spacer()
                            Button("Voir") {
                                openBookmark(bookmark)
                            }
                            Button("Supprimer") {
                                if let index = application.documentBookmarks?.firstIndex(of: bookmark) {
                                    application.documentBookmarks?.remove(at: index)
                                }
                            }
                            .foregroundColor(.red)
                        } else {
                            Text("Document invalide")
                        }
                    }
                }
            }

            HStack {
                Button("Ajouter Document") {
                    showingFileImporter = true
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Button("Fermer") { dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    print("Selected URL: \(url)")
                    // Copy the file to app's documents directory
                    let accessGranted = url.startAccessingSecurityScopedResource()
                    print("Access granted: \(accessGranted)")
                    if accessGranted {
                        let fileManager = FileManager.default
                        if let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let destinationURL = documentsDir.appendingPathComponent(url.lastPathComponent)
                            print("Destination: \(destinationURL)")
                            do {
                                let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                                print("Bookmark created")
                                application.documentBookmarks = (application.documentBookmarks ?? []) + [bookmark]
                            } catch {
                                print("Error creating bookmark: \(error)")
                            }
                        }
                        url.stopAccessingSecurityScopedResource()
                    } else {
                        print("Access to file not granted")
                    }
                }
            case .failure(let error):
                print("Error selecting file: \(error)")
            }
        }
    }
}

#Preview {
    CandidaturesView()
        .modelContainer(for: [Profile.self, Application.self], inMemory: true)
}