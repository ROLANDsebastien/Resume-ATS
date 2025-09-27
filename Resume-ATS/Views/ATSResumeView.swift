import SwiftData
import SwiftUI

//
//  ATSResumeView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

struct ATSResumeView: View {
    var profile: Profile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with name and contact
                VStack(alignment: .leading, spacing: 5) {
                    Text(fullName)
                        .font(.title)
                        .fontWeight(.bold)

                    contactInfo
                }

                // Professional Summary
                if !profile.summary.isEmpty {
                    SectionView(title: "Professional Summary") {
                        Text(profile.summary)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }

                // Professional Experience
                if !profile.experiences.isEmpty {
                    SectionView(title: "Professional Experience") {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(profile.experiences, id: \.self) { experience in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(experience.company)
                                            .font(.headline)
                                        Spacer()
                                        Text(
                                            dateRange(
                                                start: experience.startDate, end: experience.endDate
                                            )
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                    Text(experience.description)
                                        .font(.body)
                                        .lineSpacing(4)
                                }
                            }
                        }
                    }
                }

                // Education
                if !profile.educations.isEmpty {
                    SectionView(title: "Education") {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(profile.educations, id: \.self) { education in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text("\(education.institution) - \(education.degree)")
                                            .font(.headline)
                                        Spacer()
                                        Text(
                                            dateRange(
                                                start: education.startDate, end: education.endDate)
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                    if !education.description.isEmpty {
                                        Text(education.description)
                                            .font(.body)
                                            .lineSpacing(4)
                                    }
                                }
                            }
                        }
                    }
                }

                // References
                if !profile.references.isEmpty {
                    SectionView(title: "References") {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(profile.references, id: \.self) { reference in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(
                                        "\(reference.name) - \(reference.position) at \(reference.company)"
                                    )
                                    .font(.headline)
                                    Text("Email: \(reference.email) | Phone: \(reference.phone)")
                                        .font(.body)
                                }
                            }
                        }
                    }
                }

                // Skills
                if !profile.skills.isEmpty {
                    SectionView(title: "Skills") {
                        Text(profile.skills.joined(separator: ", "))
                            .font(.body)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 612)  // US Letter width equivalent
        }
        .background(Color.white)
    }

    private var fullName: String {
        let nameParts = [profile.firstName, profile.lastName].compactMap { $0 }
        return nameParts.isEmpty
            ? profile.name : "\(profile.name) (\(nameParts.joined(separator: " ")))"
    }

    private var contactInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let email = profile.email {
                Text("Email: \(email)")
            }
            if let phone = profile.phone {
                Text("Phone: \(phone)")
            }
            if let location = profile.location {
                Text("Location: \(location)")
            }
            if let github = profile.github {
                Text("GitHub: \(github)")
            }
            if let gitlab = profile.gitlab {
                Text("GitLab: \(gitlab)")
            }
            if let linkedin = profile.linkedin {
                Text("LinkedIn: \(linkedin)")
            }
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }

    private func dateRange(start: Date, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"

        let startStr = formatter.string(from: start)
        if let endDate = end {
            let endStr = formatter.string(from: endDate)
            return "\(startStr) - \(endStr)"
        } else {
            return "\(startStr) - Present"
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            content
        }
    }
}

#Preview {
    ATSResumeView(
        profile: Profile(
            name: "John Doe", firstName: "John", lastName: "Doe", email: "john@example.com",
            summary: "Experienced developer",
            experiences: [
                Experience(company: "Tech Corp", startDate: Date(), description: "Developed apps")
            ], skills: ["Swift", "iOS"]))
}
