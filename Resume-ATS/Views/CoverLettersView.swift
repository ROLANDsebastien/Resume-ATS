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

                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 60) {
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
.background(.regularMaterial)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

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
        .background(.regularMaterial)
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
    @State private var showingAIGeneration = false

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
                    Button(language == "fr" ? "Générer avec AI" : "Generate with AI") {
                        showingAIGeneration = true
                    }
                    .buttonStyle(.bordered)
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
        .sheet(isPresented: $showingAIGeneration) {
            AIGenerationView(language: language, profiles: profiles) { generatedText in
                if let text = generatedText {
                    self.contentAttributedString = NSAttributedString(string: text)
                }
            }
        }
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
    @State private var showingAIGeneration = false

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
                    Button(language == "fr" ? "Générer avec AI" : "Generate with AI") {
                        showingAIGeneration = true
                    }
                    .buttonStyle(.bordered)
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
        .sheet(isPresented: $showingAIGeneration) {
            AIGenerationView(language: language, profiles: profiles) { generatedText in
                if let text = generatedText {
                    self.contentAttributedString = NSAttributedString(string: text)
                }
            }
        }
    }
}

struct AIGenerationView: View {
     @Environment(\.dismiss) private var dismiss
     @Environment(\.modelContext) private var modelContext
     var language: String
     var profiles: [Profile]
     var onGenerate: (String?) -> Void

     @State private var jobDescription = ""
     @State private var selectedProfile: Profile?
     @State private var additionalInstructions: String
     @State private var isGenerating = false
     @State private var generatingText: String?
     @State private var errorMessage: String?
     @State private var generatedText: String?
     @State private var editableText = ""
     @State private var company = ""
     @State private var position = ""

    init(language: String, profiles: [Profile], onGenerate: @escaping (String?) -> Void, additionalInstructions: String = "") {
        self.language = language
        self.profiles = profiles
        self.onGenerate = onGenerate
        _additionalInstructions = State(initialValue: additionalInstructions)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(language == "fr" ? "Générer Lettre avec AI" : "Generate Letter with AI")
                .font(.title)
                .fontWeight(.bold)

            Form {
                Section(header: Text(language == "fr" ? "Annonce de Poste" : "Job Posting")) {
                    TextEditor(text: $jobDescription)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.vertical, 5)
                }
                Section(header: Text(language == "fr" ? "Profil (optionnel)" : "Profile (optional)")) {
                    Picker(language == "fr" ? "Sélectionner un profil" : "Select a profile", selection: $selectedProfile) {
                        Text(language == "fr" ? "Aucun" : "None").tag(nil as Profile?)
                        ForEach(profiles) { profile in
                            Text(profile.name).tag(profile as Profile?)
                        }
                    }
                }
                Section(header: Text(language == "fr" ? "Instructions Supplémentaires (optionnel)" : "Additional Instructions (optional)")) {
                    TextEditor(text: $additionalInstructions)
                        .frame(minHeight: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.vertical, 5)
                }
            }
            .frame(minWidth: 400)

            if generatedText == nil {
                HStack {
                    Button(language == "fr" ? "Annuler" : "Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button(language == "fr" ? "Générer" : "Generate") {
                        isGenerating = true
                        generatingText = language == "fr" ? "Génération en cours..." : "Generating..."
                        AIService.generateCoverLetter(jobDescription: jobDescription, profile: selectedProfile, additionalInstructions: additionalInstructions) { result in
                            DispatchQueue.main.async {
                            if let result = result {
                                generatedText = result
                                editableText = result
                            } else {
                                    errorMessage = language == "fr" ? "Erreur lors de la génération" : "Generation failed"
                                }
                                isGenerating = false
                                generatingText = nil
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(jobDescription.isEmpty || isGenerating)
                }
            } else {
                VStack(spacing: 20) {
                    Text(language == "fr" ? "Lettre Générée" : "Generated Letter")
                        .font(.headline)
                    TextEditor(text: $editableText)
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.vertical, 5)

                    Form {
                        TextField(language == "fr" ? "Entreprise" : "Company", text: $company)
                            .textFieldStyle(.roundedBorder)
                        TextField(language == "fr" ? "Poste" : "Position", text: $position)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(minWidth: 300)

                    HStack {
                        Button(language == "fr" ? "Utiliser dans Lettre" : "Use in Letter") {
                            onGenerate(editableText)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                        Button(language == "fr" ? "Exporter en PDF" : "Export to PDF") {
                            let tempCoverLetter = CoverLetter(
                                title: language == "fr" ? "Lettre Générée" : "Generated Letter",
                                content: NSAttributedString(string: editableText).rtf(
                                    from: NSRange(location: 0, length: editableText.count)) ?? Data()
                            )
                            PDFService.generateCoverLetterPDF(for: tempCoverLetter) { pdfURL in
                                if let pdfURL = pdfURL {
                                    DispatchQueue.main.async {
                                        NSWorkspace.shared.open(pdfURL)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button(language == "fr" ? "Sauvegarder dans Candidature" : "Save to Application") {
                            let coverLetter = CoverLetter(
                                title: language == "fr" ? "Lettre pour \(company)" : "Letter for \(company)",
                                content: NSAttributedString(string: editableText).rtf(
                                    from: NSRange(location: 0, length: editableText.count)) ?? Data()
                            )
                            modelContext.insert(coverLetter)
                            let application = Application(
                                company: company,
                                position: position,
                                coverLetter: coverLetter
                            )
                            application.profile = selectedProfile
                            modelContext.insert(application)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .disabled(company.isEmpty || position.isEmpty)
                        Spacer()
                        Button(language == "fr" ? "Fermer" : "Close") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            if let text = generatingText {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(text)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .alert(isPresented: .constant(errorMessage != nil), content: {
            Alert(
                title: Text(language == "fr" ? "Erreur" : "Error"),
                message: Text(errorMessage ?? ""),
                dismissButton: .default(Text(language == "fr" ? "OK" : "OK")) {
                    errorMessage = nil
                }
            )
        })
    }
}

#Preview {
    NavigationStack {
        CoverLettersView(selectedSection: .constant(nil), language: "fr")
    }
    .modelContainer(for: [Profile.self, Application.self, CoverLetter.self], inMemory: true)
}
