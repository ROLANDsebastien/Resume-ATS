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
    @Binding var selectedSection: String?
    @Environment(\.modelContext) private var modelContext
    @Query private var applications: [Application]
    @State private var showingAddApplication = false
    @State private var selectedStatus: Application.Status? = nil
    @State private var editingApplication: Application?
    @State private var showingDocumentsFor: Application?
    var language: String

    var filteredApplications: [Application] {
        if let status = selectedStatus {
            return applications.filter { $0.status == status }
        } else {
            return applications
        }
    }

    var body: some View {
        List {
            Section {
                Text(language == "fr" ? "Gestion des Candidatures" : "Applications Management")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // Status filter
                HStack {
                    Spacer()
                    Text(language == "fr" ? "Filtrer par statut:" : "Filter by status:")
                        .font(.headline)
                    Picker(language == "fr" ? "Statut" : "Status", selection: $selectedStatus) {
                        Text(language == "fr" ? "Toutes" : "All").tag(nil as Application.Status?)
                        ForEach(Application.Status.allCases, id: \.self) { status in
                            Text(status.localizedString(language: language)).tag(status as Application.Status?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)
                .padding(.bottom, 20)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    DashboardTile(
                        title: language == "fr" ? "Nouvelle Candidature" : "New Application",
                        subtitle: language == "fr" ? "Ajouter une nouvelle candidature" : "Add a new application",
                        systemImage: "plus"
                    ) {
                        showingAddApplication = true
                    }

                    DashboardTile(
                        title: language == "fr" ? "Candidatures en Cours" : "Ongoing Applications",
                        subtitle: language == "fr" ? "Voir les candidatures actives" : "View active applications",
                        systemImage: "briefcase"
                    ) {
                        selectedStatus = .applied
                    }

                    DashboardTile(
                        title: language == "fr" ? "Entretiens" : "Interviews",
                        subtitle: language == "fr" ? "Candidatures en entretien" : "Applications in interview",
                        systemImage: "person.2"
                    ) {
                        selectedStatus = .interviewing
                    }

                    DashboardTile(
                        title: language == "fr" ? "Candidatures Archivée" : "Archived Applications",
                        subtitle: language == "fr" ? "Historique des candidatures" : "Applications history",
                        systemImage: "archivebox"
                    ) {
                        selectedStatus = .rejected
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            if !filteredApplications.isEmpty {
                Section(
                    header: Text(language == "fr" ? "Candidatures" : "Applications").font(.title2).fontWeight(.semibold).padding(
                        .top, 20)
                ) {
                    ForEach(filteredApplications) { application in
                        ApplicationRow(
                            application: application,
                            onEdit: { editingApplication = application },
                            onDocuments: { showingDocumentsFor = application },
                            onDelete: {
                                modelContext.delete(application)
                            },
                            language: language
                        )
                        .listRowSeparator(.hidden)
                    }
                }
            } else {
                Section {
                    Text(language == "fr" ? "Aucune candidature trouvée." : "No applications found.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .listStyle(.plain)
        .sheet(isPresented: $showingAddApplication) {
            AddApplicationView(language: language)
        }
        .sheet(item: $editingApplication) { application in
            EditApplicationView(application: application, language: language)
        }
        .sheet(item: $showingDocumentsFor) { application in
            DocumentsView(application: application, language: language)
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

struct ApplicationRow: View {
    var application: Application
    var onEdit: () -> Void
    var onDocuments: () -> Void
    var onDelete: () -> Void
    var language: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(application.position) chez \(application.company)")
                    .font(.headline)
                Text("\(language == "fr" ? "Statut" : "Status"): \(application.status.localizedString(language: language))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(
                    "\(language == "fr" ? "Date" : "Date"): \(application.dateApplied.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                if let coverLetter = application.coverLetter {
                    Text("\(language == "fr" ? "Lettre" : "Letter"): \(coverLetter.title)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label(language == "fr" ? "Supprimer" : "Delete", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label(language == "fr" ? "Editer" : "Edit", systemImage: "pencil")
            }
            .tint(.blue)
            Button(action: onDocuments) {
                Label(language == "fr" ? "Document" : "Document", systemImage: "doc")
            }
            .tint(.green)
        }
    }
}

struct EditApplicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var coverLetters: [CoverLetter]
    var application: Application
    var language: String

    @State private var company: String
    @State private var position: String
    @State private var dateApplied: Date
    @State private var status: Application.Status
    @State private var notes: String
    @State private var selectedCoverLetter: CoverLetter?

    init(application: Application, language: String) {
        self.application = application
        self.language = language
        _company = State(initialValue: application.company)
        _position = State(initialValue: application.position)
        _dateApplied = State(initialValue: application.dateApplied)
        _status = State(initialValue: application.status)
        _notes = State(initialValue: application.notes)
        _selectedCoverLetter = State(initialValue: application.coverLetter)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(language == "fr" ? "Modifier Candidature" : "Edit Application")
                .font(.title)
                .fontWeight(.bold)

            Form {
                TextField(language == "fr" ? "Entreprise" : "Company", text: $company)
                TextField(language == "fr" ? "Poste" : "Position", text: $position)
                DatePicker(
                    language == "fr" ? "Date de candidature" : "Application Date", selection: $dateApplied, displayedComponents: .date)
                Picker(language == "fr" ? "Statut" : "Status", selection: $status) {
                    ForEach(Application.Status.allCases, id: \.self) { status in
                        Text(status.localizedString(language: language)).tag(status)
                    }
                }
                TextField(language == "fr" ? "Notes" : "Notes", text: $notes)
                Picker(language == "fr" ? "Lettre de Motivation" : "Cover Letter", selection: $selectedCoverLetter) {
                    Text(language == "fr" ? "Aucune" : "None").tag(nil as CoverLetter?)
                    ForEach(coverLetters) { coverLetter in
                        Text(coverLetter.title).tag(coverLetter as CoverLetter?)
                    }
                }
            }
            .frame(minWidth: 400, minHeight: 200)

            HStack {
                Button(language == "fr" ? "Annuler" : "Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button(language == "fr" ? "Sauvegarder" : "Save") {
                    application.company = company
                    application.position = position
                    application.dateApplied = dateApplied
                    application.status = status
                    application.notes = notes
                    application.coverLetter = selectedCoverLetter
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
    @Query private var coverLetters: [CoverLetter]
    var language: String

    @State private var company = ""
    @State private var position = ""
    @State private var dateApplied = Date()
    @State private var status: Application.Status = .applied
    @State private var notes = ""
    @State private var selectedCoverLetter: CoverLetter? = nil

    init(language: String) {
        self.language = language
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(language == "fr" ? "Nouvelle Candidature" : "New Application")
                .font(.title)
                .fontWeight(.bold)

            Form {
                TextField(language == "fr" ? "Entreprise" : "Company", text: $company)
                TextField(language == "fr" ? "Poste" : "Position", text: $position)
                DatePicker(
                    language == "fr" ? "Date de candidature" : "Application Date", selection: $dateApplied, displayedComponents: .date)
                Picker(language == "fr" ? "Statut" : "Status", selection: $status) {
                    ForEach(Application.Status.allCases, id: \.self) { status in
                        Text(status.localizedString(language: language)).tag(status)
                    }
                }
                TextField(language == "fr" ? "Notes" : "Notes", text: $notes)
                Picker(language == "fr" ? "Lettre de Motivation" : "Cover Letter", selection: $selectedCoverLetter) {
                    Text(language == "fr" ? "Aucune" : "None").tag(nil as CoverLetter?)
                    ForEach(coverLetters) { coverLetter in
                        Text(coverLetter.title).tag(coverLetter as CoverLetter?)
                    }
                }
            }
            .frame(minWidth: 400, minHeight: 200)

            HStack {
                Button(language == "fr" ? "Annuler" : "Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button(language == "fr" ? "Ajouter" : "Add") {
                    let newApplication = Application(
                        company: company,
                        position: position,
                        dateApplied: dateApplied,
                        status: status,
                        notes: notes,
                        coverLetter: selectedCoverLetter
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
    var language: String

    init(application: Application, language: String) {
        self.application = application
        self.language = language
    }

    @State private var showingFileImporter = false

    private func resolveBookmark(_ bookmark: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmark, options: .withSecurityScope,
                bookmarkDataIsStale: &isStale)
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
            Text(language == "fr" ? "Documents pour \(application.position) chez \(application.company)" : "Documents for \(application.position) at \(application.company)")
                .font(.title)
                .fontWeight(.bold)

            List {
                if let coverLetter = application.coverLetter {
                    Section(header: Text(language == "fr" ? "Lettre de Motivation" : "Cover Letter")) {
                        HStack {
                            Text(coverLetter.title)
                            Spacer()
                            Button(language == "fr" ? "Voir" : "View") {
                                PDFService.generateCoverLetterPDF(for: coverLetter) { pdfURL in
                                    if let pdfURL = pdfURL {
                                        DispatchQueue.main.async {
                                            NSWorkspace.shared.open(pdfURL)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text(language == "fr" ? "Documents" : "Documents")) {
                    ForEach(application.documentBookmarks ?? [], id: \.self) { bookmark in
                        HStack {
                            if let url = resolveBookmark(bookmark) {
                                Text(url.lastPathComponent)
                                Spacer()
                                Button(language == "fr" ? "Voir" : "View") {
                                    openBookmark(bookmark)
                                }
                                Button(language == "fr" ? "Supprimer" : "Delete") {
                                    if let index = application.documentBookmarks?.firstIndex(
                                        of: bookmark)
                                    {
                                        application.documentBookmarks?.remove(at: index)
                                    }
                                }
                                .foregroundColor(.red)
                            } else {
                                Text(language == "fr" ? "Document invalide" : "Invalid document")
                            }
                        }
                    }
                }
            }

            HStack {
                Button(language == "fr" ? "Ajouter Document" : "Add Document") {
                    showingFileImporter = true
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Button(language == "fr" ? "Fermer" : "Close") { dismiss() }
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
                        if let documentsDir = fileManager.urls(
                            for: .documentDirectory, in: .userDomainMask
                        ).first {
                            let destinationURL = documentsDir.appendingPathComponent(
                                url.lastPathComponent)
                            print("Destination: \(destinationURL)")
                            do {
                                let bookmark = try url.bookmarkData(
                                    options: .withSecurityScope,
                                    includingResourceValuesForKeys: nil, relativeTo: nil)
                                print("Bookmark created")
                                application.documentBookmarks =
                                    (application.documentBookmarks ?? []) + [bookmark]
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
    CandidaturesView(selectedSection: .constant(nil), language: "fr")
        .modelContainer(for: [Profile.self, Application.self, CoverLetter.self], inMemory: true)
}
