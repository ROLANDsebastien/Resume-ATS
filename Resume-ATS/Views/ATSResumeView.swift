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
    var isForPDF: Bool = false

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 20) {
                // Header with name and contact
                VStack(alignment: .leading, spacing: 5) {
                     Text(fullName)
                         .font(.title)
                         .fontWeight(.bold)
                         .foregroundColor(.black)

                    contactInfo
                }

                // Professional Summary
                 if !profile.summary.isEmpty {
                     SectionView(title: "Professional Summary") {
                         Text(profile.summary)
                             .font(.body)
                             .lineSpacing(4)
                             .foregroundColor(.black)
                     }
                 }

                // Professional Experience
                if !profile.experiences.isEmpty {
                    SectionView(title: "Professional Experience") {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(profile.experiences) { experience in
                                VStack(alignment: .leading, spacing: 5) {
                                     HStack {
                                         Text(experience.company)
                                             .font(.headline)
                                             .foregroundColor(.black)
                                         Spacer()
                                         Text(
                                             dateRange(
                                                 start: experience.startDate, end: experience.endDate
                                             )
                                         )
                                         .font(.subheadline)
                                         .foregroundColor(.black)
                                     }
                                    Text(experience.details)
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
                            ForEach(profile.educations) { education in
                                VStack(alignment: .leading, spacing: 5) {
                                     HStack {
                                         Text("\(education.institution) - \(education.degree)")
                                             .font(.headline)
                                             .foregroundColor(.black)
                                         Spacer()
                                         Text(
                                             dateRange(
                                                 start: education.startDate, end: education.endDate)
                                         )
                                         .font(.subheadline)
                                         .foregroundColor(.black)
                                     }
                                     if !education.details.isEmpty {
                                         Text(education.details)
                                             .font(.body)
                                             .lineSpacing(4)
                                             .foregroundColor(.black)
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
                            ForEach(profile.references) { reference in
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
            .background(Color.white)

        if isForPDF {
            content
        } else {
            ScrollView {
                content
            }
        }
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
                    .foregroundColor(.black)
            }
            if let phone = profile.phone {
                Text("Phone: \(phone)")
                    .foregroundColor(.black)
            }
            if let location = profile.location {
                Text("Location: \(location)")
                    .foregroundColor(.black)
            }
            if let github = profile.github {
                Text("GitHub: \(github)")
                    .foregroundColor(.black)
            }
            if let gitlab = profile.gitlab {
                Text("GitLab: \(gitlab)")
                    .foregroundColor(.black)
            }
            if let linkedin = profile.linkedin {
                Text("LinkedIn: \(linkedin)")
                    .foregroundColor(.black)
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
                Experience(company: "Tech Corp", startDate: Date(), details: "Developed apps")
            ], skills: ["Swift", "iOS"]), isForPDF: false)
}
