//
//  CoverLettersView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import SwiftData
import SwiftUI

struct CoverLettersView: View {
    @Binding var selectedSection: String?
    @Environment(\.modelContext) private var modelContext
    @Query private var coverLetters: [CoverLetter]
    @Query private var profiles: [Profile]
    var language: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(
                        language == "fr"
                            ? "Gestion des Lettres de Motivation" : "Cover Letters Management"
                    )
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                        NavigationLink(destination: AddCoverLetterView(language: language)) {
                            VStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                                Text(language == "fr" ? "Nouvelle Lettre" : "New Letter")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(
                                    language == "fr"
                                        ? "Créer une nouvelle lettre de motivation"
                                        : "Create a new cover letter"
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    if !coverLetters.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(language == "fr" ? "Lettres de Motivation" : "Cover Letters")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            List {
                                ForEach(coverLetters) { coverLetter in
                                    NavigationLink(
                                        destination: EditCoverLetterView(
                                            coverLetter: coverLetter, language: language)
                                    ) {
                                        CoverLetterRow(
                                            coverLetter: coverLetter,
                                            onDelete: {
                                                modelContext.delete(coverLetter)
                                            },
                                            language: language
                                        )
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: min(CGFloat(coverLetters.count) * 80, 400))  // Adjust height as needed
                        }
                    } else {
                        Text(
                            language == "fr"
                                ? "Aucune lettre de motivation trouvée." : "No cover letters found."
                        )
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }
                .padding(.horizontal)
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
}

struct CoverLetterRow: View {
    var coverLetter: CoverLetter
    var onDelete: () -> Void
    var language: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(coverLetter.title)
                    .font(.headline)
                Text(
                    "\(language == "fr" ? "Créée le" : "Created on"): \(coverLetter.creationDate.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
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

            Button(action: {
                PDFService.generateCoverLetterPDF(for: coverLetter) { pdfURL in
                    if let pdfURL = pdfURL {
                        DispatchQueue.main.async {
                            NSWorkspace.shared.open(pdfURL)
                        }
                    }
                }
            }) {
                Label(language == "fr" ? "Exporter" : "Export", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }
}

struct AddCoverLetterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [Profile]
    var language: String

    @State private var title = ""
    @State private var contentAttributedString = NSAttributedString()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(language == "fr" ? "Nouvelle Lettre de Motivation" : "New Cover Letter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Form {
                    TextField(language == "fr" ? "Titre" : "Title", text: $title)
                    RichTextEditorWithToolbar(attributedString: $contentAttributedString)
                        .frame(minHeight: 400)
                }
                .frame(minWidth: 600, minHeight: 500)

                HStack {
                    Spacer()
                    Button(language == "fr" ? "Ajouter" : "Add") {
                        let newCoverLetter = CoverLetter(
                            title: title,
                            content: contentAttributedString.rtf(
                                from: NSRange(location: 0, length: contentAttributedString.length))
                                ?? Data()
                        )
                        modelContext.insert(newCoverLetter)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(language == "fr" ? "Nouvelle Lettre" : "New Letter")
    }
}

struct EditCoverLetterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [Profile]
    var coverLetter: CoverLetter
    var language: String

    @State private var title: String
    @State private var contentAttributedString: NSAttributedString

    init(coverLetter: CoverLetter, language: String) {
        self.coverLetter = coverLetter
        self.language = language
        _title = State(initialValue: coverLetter.title)
        _contentAttributedString = State(initialValue: coverLetter.contentAttributedString)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(language == "fr" ? "Modifier Lettre de Motivation" : "Edit Cover Letter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Form {
                    TextField(language == "fr" ? "Titre" : "Title", text: $title)
                    RichTextEditorWithToolbar(attributedString: $contentAttributedString)
                        .frame(minHeight: 400)
                }
                .frame(minWidth: 600, minHeight: 500)

                HStack {
                    Spacer()
                    Button(language == "fr" ? "Sauvegarder" : "Save") {
                        coverLetter.title = title
                        coverLetter.contentAttributedString = contentAttributedString
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(language == "fr" ? "Modifier Lettre" : "Edit Letter")
    }
}

#Preview {
    NavigationStack {
        CoverLettersView(selectedSection: .constant(nil), language: "fr")
    }
    .modelContainer(for: [Profile.self, Application.self, CoverLetter.self], inMemory: true)
}
