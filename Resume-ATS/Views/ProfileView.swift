//
//  ProfileView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    @State private var selectedProfile: Profile?
    @State private var expandedSection: String? = nil
    @State private var newProfileName: String = ""

    var body: some View {
        VStack {
            // Profile selector
            VStack(alignment: .leading) {
                HStack {
                    Text("Select Profile:")
                    Picker("Profile", selection: $selectedProfile) {
                        Text("New Profile").tag(nil as Profile?)
                        ForEach(profiles) { profile in
                            Text(profile.name).tag(profile as Profile?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                if selectedProfile == nil {
                    HStack {
                        TextField("New Profile Name", text: $newProfileName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Create") {
                            if !newProfileName.isEmpty {
                                let newProfile = Profile(name: newProfileName)
                                modelContext.insert(newProfile)
                                selectedProfile = newProfile
                                newProfileName = ""
                            }
                        }
                    }
                }
            }
            .padding()

            if let profile = selectedProfile {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary Tile
                        SectionTile(title: "Summary", isExpanded: expandedSection == "summary") {
                            expandedSection = expandedSection == "summary" ? nil : "summary"
                        } expandedContent: {
                            TextEditor(
                                text: Binding(
                                    get: { profile.summary },
                                    set: { profile.summary = $0 }
                                )
                            )
                            .frame(height: 100)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Experiences Tile
                        SectionTile(
                            title: "Experiences", isExpanded: expandedSection == "experiences"
                        ) {
                            expandedSection =
                                expandedSection == "experiences" ? nil : "experiences"
                        } expandedContent: {
                            VStack {
                                ForEach(profile.experiences.indices, id: \.self) { index in
                                    HStack {
                                        ExperienceForm(experience: profile.experiences[index]) {
                                            updatedExperience in
                                            profile.experiences[index] = updatedExperience
                                        }
                                        Button(action: {
                                            profile.experiences.remove(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Divider()
                                }
                                Button(action: {
                                    profile.experiences.append(
                                        Experience(
                                            company: "", startDate: Date(), description: ""))
                                }) {
                                    Label("Add Experience", systemImage: "plus")
                                }
                            }
                        }

                        // Educations Tile
                        SectionTile(
                            title: "Educations", isExpanded: expandedSection == "educations"
                        ) {
                            expandedSection =
                                expandedSection == "educations" ? nil : "educations"
                        } expandedContent: {
                            VStack {
                                ForEach(profile.educations.indices, id: \.self) { index in
                                    HStack {
                                        EducationForm(education: profile.educations[index]) {
                                            updatedEducation in
                                            profile.educations[index] = updatedEducation
                                        }
                                        Button(action: {
                                            profile.educations.remove(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Divider()
                                }
                                Button(action: {
                                    profile.educations.append(
                                        Education(
                                            institution: "", degree: "", startDate: Date(),
                                            description: ""))
                                }) {
                                    Label("Add Education", systemImage: "plus")
                                }
                            }
                        }

                        // References Tile
                        SectionTile(
                            title: "References", isExpanded: expandedSection == "references"
                        ) {
                            expandedSection =
                                expandedSection == "references" ? nil : "references"
                        } expandedContent: {
                            VStack {
                                ForEach(profile.references.indices, id: \.self) { index in
                                    HStack {
                                        ReferenceForm(reference: profile.references[index]) {
                                            updatedReference in
                                            profile.references[index] = updatedReference
                                        }
                                        Button(action: {
                                            profile.references.remove(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Divider()
                                }
                                Button(action: {
                                    profile.references.append(
                                        Reference(
                                            name: "", position: "", company: "", email: "",
                                            phone: ""))
                                }) {
                                    Label("Add Reference", systemImage: "plus")
                                }
                            }
                        }

                        // Skills Tile
                        SectionTile(title: "Skills", isExpanded: expandedSection == "skills") {
                            expandedSection = expandedSection == "skills" ? nil : "skills"
                        } expandedContent: {
                            VStack {
                                ForEach(profile.skills.indices, id: \.self) { index in
                                    HStack {
                                        TextField(
                                            "Skill",
                                            text: Binding(
                                                get: { profile.skills[index] },
                                                set: { profile.skills[index] = $0 }
                                            ))
                                        Button(action: {
                                            profile.skills.remove(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                Button(action: {
                                    profile.skills.append("")
                                }) {
                                    Label("Add Skill", systemImage: "plus")
                                }
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            } else {
                Text("Select or create a profile to start editing.")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Profile")
    }
}

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
        VStack(alignment: .leading) {
            TextField("Company", text: $company)
                .onChange(of: company) { _ in updateExperience() }
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) { _ in updateExperience() }
            DatePicker(
                "End Date",
                selection: Binding(
                    get: { endDate ?? Date() },
                    set: {
                        endDate = $0
                        updateExperience()
                    }
                ), displayedComponents: .date)
            TextEditor(text: $description)
                .frame(height: 60)
                .onChange(of: description) { _ in updateExperience() }
        }
        .padding()
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
        VStack(alignment: .leading) {
            TextField("Institution", text: $institution)
                .onChange(of: institution) { _ in updateEducation() }
            TextField("Degree", text: $degree)
                .onChange(of: degree) { _ in updateEducation() }
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .onChange(of: startDate) { _ in updateEducation() }
            DatePicker(
                "End Date",
                selection: Binding(
                    get: { endDate ?? Date() },
                    set: {
                        endDate = $0
                        updateEducation()
                    }
                ), displayedComponents: .date)
            TextEditor(text: $description)
                .frame(height: 60)
                .onChange(of: description) { _ in updateEducation() }
        }
        .padding()
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
        VStack(alignment: .leading) {
            TextField("Name", text: $name)
                .onChange(of: name) { _ in updateReference() }
            TextField("Position", text: $position)
                .onChange(of: position) { _ in updateReference() }
            TextField("Company", text: $company)
                .onChange(of: company) { _ in updateReference() }
            TextField("Email", text: $email)
                .onChange(of: email) { _ in updateReference() }
            TextField("Phone", text: $phone)
                .onChange(of: phone) { _ in updateReference() }
        }
        .padding()
    }

    private func updateReference() {
        let updated = Reference(
            name: name, position: position, company: company, email: email, phone: phone)
        onUpdate(updated)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: Profile.self, inMemory: true)
}
