import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Profile View
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    @State private var selectedProfile: Profile?
    @State private var newProfileName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Profil")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top)

                profileSelector

                if let profile = selectedProfile {
                    VStack(spacing: 20) {
                        StyledSection(title: "Informations Personnelles") {
                            PersonalInfoForm(profile: profile)
                        }

                        StyledSection(title: "Résumé") {
                             RichTextEditorWithToolbar(attributedString: Binding(
                                 get: { profile.summaryAttributedString },
                                 set: { profile.summaryAttributedString = $0 }
                             ))
                         }

                        StyledSection(title: "Expériences") {
                            ForEach(profile.experiences) { experience in
                                ExperienceForm(experience: experience)
                                    .padding(.bottom, 10)
                                 Button(action: {
                                     DispatchQueue.main.async {
                                         if let index = profile.experiences.firstIndex(where: {
                                             $0.id == experience.id
                                         }) {
                                             profile.experiences.remove(at: index)
                                         }
                                     }
                                 }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                if experience.id != profile.experiences.last?.id {
                                    Divider().background(Color.secondary)
                                }
                            }
                             StyledButton(
                                 title: "Ajouter une expérience", systemImage: "plus",
                                 action: {
                                     DispatchQueue.main.async {
                                         profile.experiences.append(
                                             Experience(
                                                 company: "", startDate: Date(), details: Data()))
                                     }
                                 })
                        }

                        StyledSection(title: "Formations") {
                            ForEach(profile.educations) { education in
                                EducationForm(education: education)
                                    .padding(.bottom, 10)
                                 Button(action: {
                                     DispatchQueue.main.async {
                                         if let index = profile.educations.firstIndex(where: {
                                             $0.id == education.id
                                         }) {
                                             profile.educations.remove(at: index)
                                         }
                                     }
                                 }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                if education.id != profile.educations.last?.id {
                                    Divider().background(Color.secondary)
                                }
                            }
                             StyledButton(
                                 title: "Ajouter une formation", systemImage: "plus",
                                 action: {
                                     DispatchQueue.main.async {
                                         profile.educations.append(
                                             Education(
                                                 institution: "", degree: "", startDate: Date(),
                                                 details: Data()))
                                     }
                                 })
                        }

                        StyledSection(title: "Références") {
                            ForEach(profile.references) { reference in
                                ReferenceForm(reference: reference)
                                    .padding(.bottom, 10)
                                 Button(action: {
                                     DispatchQueue.main.async {
                                         if let index = profile.references.firstIndex(where: {
                                             $0.id == reference.id
                                         }) {
                                             profile.references.remove(at: index)
                                         }
                                     }
                                 }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                if reference.id != profile.references.last?.id {
                                    Divider().background(Color.secondary)
                                }
                            }
                             StyledButton(
                                 title: "Ajouter une référence", systemImage: "plus",
                                 action: {
                                     DispatchQueue.main.async {
                                         profile.references.append(
                                             Reference(
                                                 name: "", position: "", company: "", email: "",
                                                 phone: ""))
                                     }
                                 })
                        }

                        StyledSection(title: "Compétences") {
                             ForEach(profile.skills.indices, id: \.self) { index in
                                 HStack {
                                     TextField(
                                         "Compétence",
                                         text: Binding(
                                             get: { profile.skills[index] },
                                             set: { profile.skills[index] = $0 })
                                     )
                                     .textFieldStyle(StyledTextField())
                                     Button(action: { DispatchQueue.main.async { profile.skills.remove(at: index) } }) {
                                         Image(systemName: "trash.fill")
                                             .foregroundColor(.red)
                                     }
                                     .buttonStyle(.plain)
                                 }
                             }
                             StyledButton(
                                 title: "Ajouter une compétence", systemImage: "plus",
                                 action: {
                                     DispatchQueue.main.async { profile.skills.append("") }
                                 })
                         }
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("Veuillez sélectionner ou créer un profil.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Resume-ATS")
    }

    private var profileSelector: some View {
        VStack(alignment: .leading) {
            if selectedProfile == nil {
                HStack {
                    TextField("Nom du nouveau profil", text: $newProfileName)
                        .textFieldStyle(StyledTextField())
                        .foregroundColor(.primary)
                    StyledButton(title: "Créer", action: createProfile)
                }
            }

            Picker("Profil", selection: $selectedProfile) {
                Text("Nouveau Profil").tag(nil as Profile?)
                ForEach(profiles) { profile in
                    Text(profile.name).tag(profile as Profile?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .modifier(StyledPickerModifier())
        }
    }

    private func createProfile() {
        if !newProfileName.isEmpty {
            let newProfile = Profile(name: newProfileName)
            modelContext.insert(newProfile)
            selectedProfile = newProfile
            newProfileName = ""
        }
    }
}

// MARK: - Reusable Styled Components
extension Color {
    fileprivate static var darkBackground: Color {
        Color.gray.opacity(0.1)
    }

    fileprivate static var sectionBackground: Color {
        Color.gray.opacity(0.1)
    }
}

private struct StyledSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))))
            }
        }
        .padding()
        .background(Color.sectionBackground)
        .cornerRadius(10)
    }
}

private struct StyledButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.accentColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

private struct StyledTextField: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(Color.darkBackground)
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}

private struct StyledTextEditorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .cornerRadius(8)
            .foregroundColor(.primary)
            .frame(minHeight: 100)
    }
}

private struct StyledPickerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(Color.sectionBackground)
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}

// MARK: - Form Views (to be restyled)
struct ExperienceForm: View {
    @Bindable var experience: Experience

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Entreprise", text: $experience.company)
                .foregroundColor(.primary)
            HStack {
                DatePicker(
                    "Date de début", selection: $experience.startDate, displayedComponents: .date
                )
                .datePickerStyle(.compact)
                Spacer()
                DatePicker(
                    "Date de fin",
                    selection: Binding(
                        get: { experience.endDate ?? Date() }, set: { experience.endDate = $0 }),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
            RichTextEditorWithToolbar(attributedString: Binding(
                get: { experience.detailsAttributedString },
                set: { experience.detailsAttributedString = $0 }
            ))
        }
        .textFieldStyle(StyledTextField())
    }
}

struct EducationForm: View {
    @Bindable var education: Education

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Institution", text: $education.institution)
                .foregroundColor(.primary)
            TextField("Diplôme", text: $education.degree)
                .foregroundColor(.primary)
            HStack {
                DatePicker(
                    "Date de début", selection: $education.startDate, displayedComponents: .date
                )
                .datePickerStyle(.compact)
                Spacer()
                DatePicker(
                    "Date de fin",
                    selection: Binding(
                        get: { education.endDate ?? Date() }, set: { education.endDate = $0 }),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
            RichTextEditorWithToolbar(attributedString: Binding(
                get: { education.detailsAttributedString },
                set: { education.detailsAttributedString = $0 }
            ))
        }
        .textFieldStyle(StyledTextField())
    }
}

struct ReferenceForm: View {
    @Bindable var reference: Reference

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Nom", text: $reference.name)
                .foregroundColor(.primary)
            TextField("Poste", text: $reference.position)
                .foregroundColor(.primary)
            TextField("Entreprise", text: $reference.company)
            TextField("Email", text: $reference.email)
                .foregroundColor(.primary)
            TextField("Téléphone", text: $reference.phone)
                .foregroundColor(.primary)
        }
        .textFieldStyle(StyledTextField())
    }
}

struct PersonalInfoForm: View {
    @Bindable var profile: Profile
    @State private var tempPhotoData: Data?
    @State private var showCropView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Photo section
            if let photoData = profile.photo, let nsImage = NSImage(data: photoData) {
                VStack(spacing: 8) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .clipped()
                    Button(action: {
                        profile.photo = nil
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Supprimer")
                        }
                        .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 8) {
                    Button("Sélectionner une photo") {
                        selectPhoto()
                    }
                    .buttonStyle(.bordered)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 100, height: 100)
                        Text("Glissez une photo ici")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onDrop(of: [.image], isTargeted: nil) { providers in
                        for provider in providers {
                            provider.loadDataRepresentation(forTypeIdentifier: "public.image") {
                                data, error in
                                if let data = data {
                                    DispatchQueue.main.async {
                                        tempPhotoData = data
                                        showCropView = true
                                    }
                                }
                            }
                        }
                        return true
                    }
                }
            }

            Toggle("Afficher la photo dans le PDF", isOn: $profile.showPhotoInPDF)
                .toggleStyle(.switch)

            TextField(
                "Prénom",
                text: Binding(
                    get: { profile.firstName ?? "" },
                    set: { profile.firstName = $0.isEmpty ? nil : $0 }))
            TextField(
                "Nom",
                text: Binding(
                    get: { profile.lastName ?? "" },
                    set: { profile.lastName = $0.isEmpty ? nil : $0 }))
            TextField(
                "Email",
                text: Binding(
                    get: { profile.email ?? "" }, set: { profile.email = $0.isEmpty ? nil : $0 }))
            TextField(
                "Téléphone",
                text: Binding(
                    get: { profile.phone ?? "" }, set: { profile.phone = $0.isEmpty ? nil : $0 }))
            TextField(
                "Localisation",
                text: Binding(
                    get: { profile.location ?? "" },
                    set: { profile.location = $0.isEmpty ? nil : $0 }))
            TextField(
                "GitHub",
                text: Binding(
                    get: { profile.github ?? "" }, set: { profile.github = $0.isEmpty ? nil : $0 }))
            TextField(
                "GitLab",
                text: Binding(
                    get: { profile.gitlab ?? "" }, set: { profile.gitlab = $0.isEmpty ? nil : $0 }))
            TextField(
                "LinkedIn",
                text: Binding(
                    get: { profile.linkedin ?? "" },
                    set: { profile.linkedin = $0.isEmpty ? nil : $0 }))
            TextField(
                "Site Web",
                text: Binding(
                    get: { profile.website ?? "" },
                    set: { profile.website = $0.isEmpty ? nil : $0 }))
        }
        .textFieldStyle(StyledTextField())
        .sheet(isPresented: $showCropView) {
            PhotoCropView(croppedData: $tempPhotoData)
                .onDisappear {
                    if let croppedData = tempPhotoData {
                        profile.photo = croppedData
                    }
                    tempPhotoData = nil
                }
        }
    }

    private func selectPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                tempPhotoData = data
                showCropView = true
            } catch {
                print("Error loading image: \(error)")
            }
        }
    }
}

// MARK: - Rich Text Editor
struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedString: NSAttributedString
    @Binding var selectedRange: NSRange

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.usesRuler = false
        textView.usesInspectorBar = false
        textView.delegate = context.coordinator
        textView.textColor = NSColor.labelColor
        textView.drawsBackground = false
        textView.backgroundColor = NSColor.clear

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = NSColor.clear

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            textView.textColor = NSColor.labelColor
            let mutableString = NSMutableAttributedString(attributedString: attributedString)
            mutableString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: mutableString.length))
            if textView.attributedString() != mutableString {
                textView.textStorage?.setAttributedString(mutableString)
            }
            let clampedRange = NSRange(location: min(selectedRange.location, mutableString.length), length: min(selectedRange.length, mutableString.length - min(selectedRange.location, mutableString.length)))
            if textView.selectedRange() != clampedRange {
                textView.setSelectedRange(clampedRange)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                let newString = textView.attributedString()
                DispatchQueue.main.async {
                    self.parent.attributedString = newString
                }
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                let newRange = textView.selectedRange()
                DispatchQueue.main.async {
                    self.parent.selectedRange = newRange
                }
            }
        }
    }
}

struct RichTextToolbar: View {
    @Binding var attributedString: NSAttributedString
    @Binding var selectedRange: NSRange

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { toggleBold() }) {
                Image(systemName: "bold")
            }
            .buttonStyle(.bordered)

            Button(action: { toggleItalic() }) {
                Image(systemName: "italic")
            }
            .buttonStyle(.bordered)

            Button(action: { insertBullet() }) {
                Image(systemName: "list.bullet")
            }
            .buttonStyle(.bordered)

            Button(action: { insertLineBreak() }) {
                Image(systemName: "arrow.right.to.line")
            }
            .buttonStyle(.bordered)
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }

    private func toggleBold() {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fontManager = NSFontManager.shared
        let validRange = NSRange(location: min(selectedRange.location, attributedString.length), length: min(selectedRange.length, attributedString.length - min(selectedRange.location, attributedString.length)))
        if validRange.length > 0 {
            mutableString.enumerateAttribute(.font, in: validRange, options: []) { value, range, _ in
                if let font = value as? NSFont {
                    let newFont = fontManager.convert(font, toHaveTrait: .boldFontMask)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            }
        } else {
            // Apply to current position or whole text if no selection
            let range = validRange.length > 0 ? validRange : NSRange(location: 0, length: mutableString.length)
            mutableString.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
                if let font = value as? NSFont {
                    let newFont = fontManager.convert(font, toHaveTrait: .boldFontMask)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func toggleItalic() {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fontManager = NSFontManager.shared
        let validRange = NSRange(location: min(selectedRange.location, attributedString.length), length: min(selectedRange.length, attributedString.length - min(selectedRange.location, attributedString.length)))
        if validRange.length > 0 {
            mutableString.enumerateAttribute(.font, in: validRange, options: []) { value, range, _ in
                if let font = value as? NSFont {
                    let newFont = fontManager.convert(font, toHaveTrait: .italicFontMask)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            }
        } else {
            let range = NSRange(location: 0, length: mutableString.length)
            mutableString.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
                if let font = value as? NSFont {
                    let newFont = fontManager.convert(font, toHaveTrait: .italicFontMask)
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func insertBullet() {
        let bullet = "• "
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let location = min(selectedRange.location, attributedString.length)
        mutableString.insert(NSAttributedString(string: bullet), at: location)
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func insertLineBreak() {
        let lineBreak = "\n"
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let location = min(selectedRange.location, attributedString.length)
        mutableString.insert(NSAttributedString(string: lineBreak), at: location)
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }
}

struct RichTextEditorWithToolbar: View {
    @Binding var attributedString: NSAttributedString

    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)

    var body: some View {
        VStack(spacing: 0) {
            RichTextToolbar(attributedString: $attributedString, selectedRange: $selectedRange)
            RichTextEditor(attributedString: $attributedString, selectedRange: $selectedRange)
                .frame(minHeight: 100)
                .background(Color.darkBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .modelContainer(for: Profile.self, inMemory: true)
}
