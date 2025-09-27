import SwiftData
import SwiftUI

// No additional import needed for RoundedImageView as it's in the same module

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
            // Header with photo, name, and contact
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    if let first = profile.firstName, let last = profile.lastName {
                        Text("\(first) \(last)")
                            .font(.custom("Arial", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    Text(profile.name)
                        .font(.custom("Arial", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    if profile.showPhotoInPDF, let photoData = profile.photo {
                        RoundedImageView(
                            imageData: photoData,
                            size: CGSize(width: 100, height: 100),
                            cornerRadius: 10
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                    }
                }
                Spacer()
                contactInfo
            }

            // Professional Summary
            if !profile.summary.isEmpty {
                SectionView(title: "Professional Summary") {
                    Text(profile.summary)
                        .font(.custom("Arial", size: 11))
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
                                        .font(.custom("Arial", size: 12))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(
                                        dateRange(
                                            start: experience.startDate, end: experience.endDate
                                        )
                                    )
                                    .font(.custom("Arial", size: 10))
                                    .foregroundColor(.black)
                                }
                                Text(experience.details)
                                    .font(.custom("Arial", size: 11))
                                    .lineSpacing(4)
                                    .foregroundColor(.black)
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
                                        .font(.custom("Arial", size: 12))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(
                                        dateRange(
                                            start: education.startDate, end: education.endDate)
                                    )
                                    .font(.custom("Arial", size: 10))
                                    .foregroundColor(.black)
                                }
                                if !education.details.isEmpty {
                                    Text(education.details)
                                        .font(.custom("Arial", size: 11))
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
                                .font(.custom("Arial", size: 12))
                                .foregroundColor(.black)
                                Text("Email: \(reference.email) | Phone: \(reference.phone)")
                                    .font(.custom("Arial", size: 11))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
            }

            // Skills
            if !profile.skills.isEmpty {
                SectionView(title: "Skills") {
                    Text(profile.skills.joined(separator: ", "))
                        .font(.custom("Arial", size: 11))
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .frame(maxWidth: 595, minHeight: 842, alignment: .top)  // A4 size, align to top
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
        .font(.custom("Arial", size: 10))
    }

    private func dateRange(start: Date, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yyyy"

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
                .font(.custom("Arial", size: 14))
                .fontWeight(.bold)
                .foregroundColor(.black)
            content
        }
    }
}

#Preview {
    ATSResumeView(
        profile: Profile(
            name: "John Doe", firstName: "John", lastName: "Doe", email: "john@example.com",
            showPhotoInPDF: true, summary: "Experienced developer",
            experiences: [
                Experience(company: "Tech Corp", startDate: Date(), details: "Developed apps")
            ], skills: ["Swift", "iOS"]), isForPDF: false)
}
