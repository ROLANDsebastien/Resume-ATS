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
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    if let first = profile.firstName, let last = profile.lastName {
                        Text("\(first) \(last)")
                            .font(.custom("Arial", size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    Text(profile.name)
                        .font(.custom("Arial", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    contactInfo
                }
                Spacer()
                if profile.showPhotoInPDF, let photoData = profile.photo {
                    RoundedImageView(
                        imageData: photoData,
                        size: CGSize(width: 120, height: 120),
                        cornerRadius: 10
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                }
            }

            // Professional Summary
            if !profile.summaryString.isEmpty {
                SectionView(title: "Professional Summary") {
                    Text(AttributedString(profile.normalizedSummaryAttributedString))
                        .lineSpacing(4)
                        .foregroundColor(.black)
                }
            }

            // Professional Experience
            if profile.showExperiences && !profile.experiences.filter({ $0.isVisible }).isEmpty {
                SectionView(title: "Professional Experience") {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(profile.experiences.filter({ $0.isVisible })) { experience in
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
                                Text(AttributedString(experience.normalizedDetailsAttributedString))
                                    .lineSpacing(4)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
            }

            // Education
            if profile.showEducations && !profile.educations.filter({ $0.isVisible }).isEmpty {
                SectionView(title: "Education") {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(profile.educations.filter({ $0.isVisible })) { education in
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
                                if !education.detailsString.isEmpty {
                                    Text(AttributedString(education.normalizedDetailsAttributedString))
                                    .lineSpacing(4)
                                    .foregroundColor(.black)
                                }
                            }
                        }
                    }
                }
            }

            // References
            if profile.showReferences && !profile.references.filter({ $0.isVisible }).isEmpty {
                SectionView(title: "References") {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(profile.references.filter({ $0.isVisible })) { reference in
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
            if profile.showSkills && !profile.skills.isEmpty {
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
                HStack(spacing: 0) {
                    Text("Email:")
                        .font(.custom("Arial", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(" \(email)")
                        .font(.custom("Arial", size: 10))
                        .foregroundColor(.black)
                }
            }
            if let phone = profile.phone {
                HStack(spacing: 0) {
                    Text("Phone:")
                        .font(.custom("Arial", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(" \(phone)")
                        .font(.custom("Arial", size: 10))
                        .foregroundColor(.black)
                }
            }
            if let location = profile.location {
                HStack(spacing: 0) {
                    Text("Location:")
                        .font(.custom("Arial", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(" \(location)")
                        .font(.custom("Arial", size: 10))
                        .foregroundColor(.black)
                }
                .padding(.bottom, 5)
            }
            if let github = profile.github, let url = URL(string: github) {
                let displayValue = url.host != nil ? "\(url.host!)\(url.path)" : github
                HStack(spacing: 0) {
                    Text("GitHub:")
                        .font(.custom("Arial", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(" \(displayValue)")
                        .font(.custom("Arial", size: 10))
                        .foregroundColor(.black)
                }
            }
            if let gitlab = profile.gitlab, let url = URL(string: gitlab) {
                let displayValue = url.host != nil ? "\(url.host!)\(url.path)" : gitlab
                HStack(spacing: 0) {
                    Text("GitLab:")
                        .font(.custom("Arial", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(" \(displayValue)")
                        .font(.custom("Arial", size: 10))
                        .foregroundColor(.black)
                }
            }
            if let linkedin = profile.linkedin, let url = URL(string: linkedin) {
                let displayValue = url.host != nil ? "\(url.host!)\(url.path)" : linkedin
                HStack(spacing: 0) {
                    Text("LinkedIn:")
                        .font(.custom("Arial", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(" \(displayValue)")
                        .font(.custom("Arial", size: 10))
                        .foregroundColor(.black)
                }
            }
            if let website = profile.website, let url = URL(string: website) {
                let displayValue = url.host != nil ? "\(url.host!)\(url.path)" : website
                HStack(spacing: 0) {
                    Text("Website:")
                        .font(.custom("Arial", size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(" \(displayValue)")
                        .font(.custom("Arial", size: 10))
                        .foregroundColor(.black)
                }
            }
        }
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
            showPhotoInPDF: true, summary: NSAttributedString(string: "Experienced developer").rtf(from: NSRange(location: 0, length: 21)) ?? Data(),
            experiences: [
                Experience(company: "Tech Corp", startDate: Date(), details: NSAttributedString(string: "Developed apps").rtf(from: NSRange(location: 0, length: 14)) ?? Data())
            ], skills: ["Swift", "iOS"]), isForPDF: false)
}
