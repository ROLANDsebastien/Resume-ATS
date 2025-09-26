import SwiftData
import SwiftUI

// MARK: - Main Profile View
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    @State private var selectedProfile: Profile?
    @State private var newProfileName: String = ""

    var body: some View {
        ZStack {
            Color.darkBackground.edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Profil")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top)

                // Profile Selector
                profileSelector
                    .padding()

                if let profile = selectedProfile {
                    ScrollView {
                        VStack(spacing: 20) {
                            StyledSection(title: "Résumé") {
                                TextEditor(
                                    text: Binding(
                                        get: { profile.summary }, set: { profile.summary = $0 })
                                )
                                .modifier(StyledTextEditorModifier())
                            }

                            StyledSection(title: "Expériences") {
                                ForEach(profile.experiences.indices, id: \.self) { index in
                                    ExperienceForm(experience: profile.experiences[index]) {
                                        updatedExperience in
                                        profile.experiences[index] = updatedExperience
                                    }
                                    .padding(.bottom, 10)
                                    Button(action: { profile.experiences.remove(at: index) }) {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    if index < profile.experiences.count - 1 {
                                        Divider().background(Color.gray)
                                    }
                                }
                                StyledButton(
                                    title: "Ajouter une expérience", systemImage: "plus",
                                    action: {
                                        profile.experiences.append(
                                            Experience(
                                                company: "", startDate: Date(), description: ""))
                                    })
                            }

                            StyledSection(title: "Formations") {
                                ForEach(profile.educations.indices, id: \.self) { index in
                                    EducationForm(education: profile.educations[index]) {
                                        updatedEducation in
                                        profile.educations[index] = updatedEducation
                                    }
                                    .padding(.bottom, 10)
                                    Button(action: { profile.educations.remove(at: index) }) {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    if index < profile.educations.count - 1 {
                                        Divider().background(Color.gray)
                                    }
                                }
                                StyledButton(
                                    title: "Ajouter une formation", systemImage: "plus",
                                    action: {
                                        profile.educations.append(
                                            Education(
                                                institution: "", degree: "", startDate: Date(),
                                                description: ""))
                                    })
                            }

                            StyledSection(title: "Références") {
                                ForEach(profile.references.indices, id: \.self) { index in
                                    ReferenceForm(reference: profile.references[index]) {
                                        updatedReference in
                                        profile.references[index] = updatedReference
                                    }
                                    .padding(.bottom, 10)
                                    Button(action: { profile.references.remove(at: index) }) {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    if index < profile.references.count - 1 {
                                        Divider().background(Color.gray)
                                    }
                                }
                                StyledButton(
                                    title: "Ajouter une référence", systemImage: "plus",
                                    action: {
                                        profile.references.append(
                                            Reference(
                                                name: "", position: "", company: "", email: "",
                                                phone: ""))
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
                                        Button(action: { profile.skills.remove(at: index) }) {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                StyledButton(
                                    title: "Ajouter une compétence", systemImage: "plus",
                                    action: {
                                        profile.skills.append("")
                                    })
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("Veuillez sélectionner ou créer un profil.")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Profil")
    }

    private var profileSelector: some View {
        VStack(alignment: .leading) {
            if selectedProfile == nil {
                HStack {
                    TextField("Nom du nouveau profil", text: $newProfileName)
                        .textFieldStyle(StyledTextField())
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
    fileprivate static let darkBackground = Color(red: 24 / 255, green: 24 / 255, blue: 38 / 255)
    fileprivate static let sectionBackground = Color(red: 44 / 255, green: 44 / 255, blue: 60 / 255)
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
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.accentColor)
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
            .foregroundColor(.white)
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
            .foregroundColor(.white)
    }
}

private struct StyledTextEditorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .cornerRadius(8)
            .foregroundColor(.white)
            .frame(minHeight: 100)
    }
}

private struct StyledPickerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(Color.sectionBackground)
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

// MARK: - Form Views (to be restyled)
struct ExperienceForm: View {
    var experience: Experience
    var onUpdate: (Experience) -> Void

    @State private var company: String
    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var description: String

    init(experience: Experience, onUpdate: @escaping (Experience) -> Void) {
        self.experience = experience
        self.onUpdate = onUpdate
        _company = State(initialValue: experience.company)
        _startDate = State(initialValue: experience.startDate)
        _endDate = State(initialValue: experience.endDate)
        _description = State(initialValue: experience.description)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Entreprise", text: $company)
            DatePicker("Date de début", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .colorScheme(.dark)
            DatePicker(
                "Date de fin",
                selection: Binding(get: { endDate ?? Date() }, set: { endDate = $0 }),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .colorScheme(.dark)
            TextEditor(text: $description)
                .modifier(StyledTextEditorModifier())
        }
        .textFieldStyle(StyledTextField())
        .onChange(of: company) { updateExperience() }
        .onChange(of: startDate) { updateExperience() }
        .onChange(of: endDate) { updateExperience() }
        .onChange(of: description) { updateExperience() }
    }

    private func updateExperience() {
        let updated = Experience(
            company: company, startDate: startDate, endDate: endDate, description: description)
        onUpdate(updated)
    }
}

struct EducationForm: View {
    var education: Education
    var onUpdate: (Education) -> Void

    @State private var institution: String
    @State private var degree: String
    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var description: String

    init(education: Education, onUpdate: @escaping (Education) -> Void) {
        self.education = education
        self.onUpdate = onUpdate
        _institution = State(initialValue: education.institution)
        _degree = State(initialValue: education.degree)
        _startDate = State(initialValue: education.startDate)
        _endDate = State(initialValue: education.endDate)
        _description = State(initialValue: education.description)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Institution", text: $institution)
            TextField("Diplôme", text: $degree)
            DatePicker("Date de début", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .colorScheme(.dark)
            DatePicker(
                "Date de fin",
                selection: Binding(get: { endDate ?? Date() }, set: { endDate = $0 }),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            TextEditor(text: $description)
                .modifier(StyledTextEditorModifier())
        }
        .textFieldStyle(StyledTextField())
        .onChange(of: institution) { updateEducation() }
        .onChange(of: degree) { updateEducation() }
        .onChange(of: startDate) { updateEducation() }
        .onChange(of: endDate) { updateEducation() }
        .onChange(of: description) { updateEducation() }
    }

    private func updateEducation() {
        let updated = Education(
            institution: institution, degree: degree, startDate: startDate, endDate: endDate,
            description: description)
        onUpdate(updated)
    }
}

struct ReferenceForm: View {
    var reference: Reference
    var onUpdate: (Reference) -> Void

    @State private var name: String
    @State private var position: String
    @State private var company: String
    @State private var email: String
    @State private var phone: String

    init(reference: Reference, onUpdate: @escaping (Reference) -> Void) {
        self.reference = reference
        self.onUpdate = onUpdate
        _name = State(initialValue: reference.name)
        _position = State(initialValue: reference.position)
        _company = State(initialValue: reference.company)
        _email = State(initialValue: reference.email)
        _phone = State(initialValue: reference.phone)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Nom", text: $name)
            TextField("Poste", text: $position)
            TextField("Entreprise", text: $company)
            TextField("Email", text: $email)
            TextField("Téléphone", text: $phone)
        }
        .textFieldStyle(StyledTextField())
        .onChange(of: name) { updateReference() }
        .onChange(of: position) { updateReference() }
        .onChange(of: company) { updateReference() }
        .onChange(of: email) { updateReference() }
        .onChange(of: phone) { updateReference() }
    }

    private func updateReference() {
        let updated = Reference(
            name: name, position: position, company: company, email: email, phone: phone)
        onUpdate(updated)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .modelContainer(for: Profile.self, inMemory: true)
}
