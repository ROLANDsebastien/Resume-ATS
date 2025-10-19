//
//  CVsView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CVsView: View {
    @Binding var selectedSection: String?
    @Environment(\.modelContext) private var modelContext
    @Query private var cvDocuments: [CVDocument]
    @State private var showingFileImporter = false
    @State private var selectedDocument: CVDocument?
    @State private var showingQuickLook = false
    var language: String

    var body: some View {
        List {
            Section {
                Text(language == "fr" ? "Gestion des CVs" : "CV Management")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 40) {
                    DashboardTile(
                        title: language == "fr" ? "Importer CV" : "Import CV",
                        subtitle: language == "fr"
                            ? "Ajouter un CV PDF" : "Add a CV PDF",
                        systemImage: "plus"
                    ) {
                        showingFileImporter = true
                    }

                    DashboardTile(
                        title: language == "fr" ? "Exporter Tous" : "Export All",
                        subtitle: language == "fr"
                            ? "Exporter tous les CVs" : "Export all CVs",
                        systemImage: "square.and.arrow.up"
                    ) {
                        exportAllCVs()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            if !cvDocuments.isEmpty {
                Section(
                    header: Text(language == "fr" ? "CVs" : "CVs").font(.title2)
                        .fontWeight(.semibold).padding(.top, 20)
                ) {
                    ForEach(cvDocuments.sorted(by: { $0.dateCreated > $1.dateCreated })) { document in
                        CVRow(
                            document: document,
                            onPreview: { previewCV(document) },
                            onExport: { exportCV(document) },
                            onDelete: {
                                modelContext.delete(document)
                            },
                            language: language
                        )
                        .listRowSeparator(.hidden)
                    }
                }
            } else {
                Section {
                    Text(language == "fr" ? "Aucun CV trouvé." : "No CVs found.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .listStyle(.plain)

        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importCV(from: url)
                }
            case .failure(let error):
                print("Error selecting file: \(error)")
            }
        }
        .dropDestination(for: URL.self) { items, location in
            for item in items {
                importCV(from: item)
            }
            return true
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

    private func importCV(from url: URL) {
        let accessGranted = url.startAccessingSecurityScopedResource()
        if accessGranted {
            do {
                let bookmark = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil, relativeTo: nil)
                let name = url.deletingPathExtension().lastPathComponent
                let newDocument = CVDocument(name: name, pdfBookmark: bookmark)
                modelContext.insert(newDocument)
            } catch {
                print("Error creating bookmark: \(error)")
            }
            url.stopAccessingSecurityScopedResource()
        }
    }

    private func previewCV(_ document: CVDocument) {
        guard let bookmark = document.pdfBookmark else { return }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmark, options: .withSecurityScope,
                bookmarkDataIsStale: &isStale)
            let accessGranted = url.startAccessingSecurityScopedResource()
            if accessGranted {
                NSWorkspace.shared.open(url)
                url.stopAccessingSecurityScopedResource()
            }
        } catch {
            print("Error resolving bookmark: \(error)")
        }
    }

    private func exportCV(_ document: CVDocument) {
        guard let bookmark = document.pdfBookmark else { return }
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "\(document.name).pdf"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    var isStale = false
                    let pdfURL = try URL(
                        resolvingBookmarkData: bookmark, options: .withSecurityScope,
                        bookmarkDataIsStale: &isStale)
                    let accessGranted = pdfURL.startAccessingSecurityScopedResource()
                    if accessGranted {
                        try FileManager.default.copyItem(at: pdfURL, to: url)
                        pdfURL.stopAccessingSecurityScopedResource()
                    }
                } catch {
                    print("Error exporting CV: \(error)")
                }
            }
        }
    }

    private func exportAllCVs() {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = language == "fr" ? "CVs" : "CVs"
        savePanel.prompt = language == "fr" ? "Créer Dossier" : "Create Folder"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let fileManager = FileManager.default
                do {
                    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                    for document in cvDocuments {
                        if let bookmark = document.pdfBookmark {
                            do {
                                var isStale = false
                                let pdfURL = try URL(
                                    resolvingBookmarkData: bookmark, options: .withSecurityScope,
                                    bookmarkDataIsStale: &isStale)
                                let accessGranted = pdfURL.startAccessingSecurityScopedResource()
                                if accessGranted {
                                    let destURL = url.appendingPathComponent("\(document.name).pdf")
                                    try fileManager.copyItem(at: pdfURL, to: destURL)
                                    pdfURL.stopAccessingSecurityScopedResource()
                                }
                            } catch {
                                print("Error copying CV: \(error)")
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        NSWorkspace.shared.open(url)
                    }
                } catch {
                    print("Error creating directory: \(error)")
                }
            }
        }
    }
}

struct CVRow: View {
    var document: CVDocument
    var onPreview: () -> Void
    var onExport: () -> Void
    var onDelete: () -> Void
    var language: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(document.name)
                    .font(.headline)
                Text(
                    "\(language == "fr" ? "Créé le" : "Created on"): \(document.dateCreated.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .background(.regularMaterial)
        .cornerRadius(8)
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label(language == "fr" ? "Supprimer" : "Delete", systemImage: "trash")
            }
            Button(action: onExport) {
                Label(language == "fr" ? "Exporter" : "Export", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
            Button(action: onPreview) {
                Label(language == "fr" ? "Prévisualiser" : "Preview", systemImage: "eye")
            }
            .tint(.green)
        }
    }
}



#Preview {
    CVsView(selectedSection: .constant(nil), language: "fr")
        .modelContainer(for: [Profile.self, Application.self, CoverLetter.self, CVDocument.self], inMemory: true)
}