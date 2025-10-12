import SwiftData
import SwiftUI

//
//  ATSResumeView.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

// MARK: - Attributed Text View for PDF
struct AttributedTextView: NSViewRepresentable {
    let attributedString: NSAttributedString
    let fontSize: CGFloat

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textColor = .black
        textView.font = NSFont.systemFont(ofSize: fontSize)
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        // Ensure all text is black and has proper font size
        mutableString.addAttribute(
            .foregroundColor, value: NSColor.black,
            range: NSRange(location: 0, length: mutableString.length))
        mutableString.enumerateAttribute(
            .font, in: NSRange(location: 0, length: mutableString.length), options: []
        ) { value, range, _ in
            if let currentFont = value as? NSFont {
                let descriptor = currentFont.fontDescriptor
                let traits = descriptor.symbolicTraits
                let newDescriptor = NSFontDescriptor(name: "Arial", size: fontSize)
                    .withSymbolicTraits(traits)
                if let newFont = NSFont(descriptor: newDescriptor, size: fontSize) {
                    mutableString.addAttribute(.font, value: newFont, range: range)
                }
            } else {
                mutableString.addAttribute(
                    .font,
                    value: NSFont(name: "Arial", size: fontSize)
                        ?? NSFont.systemFont(ofSize: fontSize), range: range)
            }
        }
        nsView.textStorage?.setAttributedString(mutableString)
    }
}

struct ATSResumeView: View {
    var profile: Profile
    var language: String = "fr"
    var isForPDF: Bool = false

    private func localizedTitle(for key: String) -> String {
        let enDict: [String: String] = [
            "professional_summary": "Professional Summary",
            "professional_experience": "Experiences",
            "education": "Education",
            "references": "References",
            "skills": "Skills",
            "certifications": "Certifications",
            "languages": "Languages",
            "email_prefix": "Email:",
            "phone_prefix": "Phone:",
            "location_prefix": "Location:",
            "github_prefix": "GitHub:",
            "gitlab_prefix": "GitLab:",
            "linkedin_prefix": "LinkedIn:",
            "website_prefix": "Website:",
            "present": "Present",
        ]
        let frDict: [String: String] = [
            "professional_summary": "Résumé",
            "professional_experience": "Expériences",
            "education": "Formation",
            "references": "Références",
            "skills": "Compétences",
            "certifications": "Certifications",
            "languages": "Langues",
            "email_prefix": "Email :",
            "phone_prefix": "Téléphone :",
            "location_prefix": "Localisation :",
            "github_prefix": "GitHub :",
            "gitlab_prefix": "GitLab :",
            "linkedin_prefix": "LinkedIn :",
            "website_prefix": "Site Web :",
            "present": "Présent",
        ]
        let dict = language == "en" ? enDict : frDict
        return dict[key] ?? key
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
                    Text(localizedTitle(for: "email_prefix"))
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
                    Text(localizedTitle(for: "phone_prefix"))
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
                    Text(localizedTitle(for: "location_prefix"))
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
                    Text(localizedTitle(for: "github_prefix"))
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
                    Text(localizedTitle(for: "gitlab_prefix"))
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
                    Text(localizedTitle(for: "linkedin_prefix"))
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
                    Text(localizedTitle(for: "website_prefix"))
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yyyy"
        return formatter.string(from: date)
    }

    private func dateRange(start: Date, end: Date?) -> String {
        let startStr = formatDate(start)
        if let endDate = end {
            let endStr = formatDate(endDate)
            return "\(startStr) - \(endStr)"
        } else {
            return "\(startStr) - \(localizedTitle(for: "present"))"
        }
    }

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
                SectionView(title: localizedTitle(for: "professional_summary")) {
                    AttributedTextView(
                        attributedString: profile.normalizedSummaryAttributedString, fontSize: 11
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Professional Experience
            if profile.showExperiences && !profile.experiences.filter({ $0.isVisible }).isEmpty {
                SectionView(title: localizedTitle(for: "professional_experience")) {
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
                                if let position = experience.position, !position.isEmpty {
                                    Text(position)
                                        .font(.custom("Arial", size: 11))
                                        .foregroundColor(.black)
                                }
                                 AttributedTextView(attributedString: experience.normalizedDetailsAttributedString, fontSize: 11)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            // Education
            if profile.showEducations && !profile.educations.filter({ $0.isVisible }).isEmpty {
                SectionView(title: localizedTitle(for: "education")) {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(profile.educations.filter({ $0.isVisible })) { education in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(education.institution)
                                            .font(.custom("Arial", size: 12))
                                            .foregroundColor(.black)
                                        Text(education.degree)
                                            .font(.custom("Arial", size: 11))
                                            .foregroundColor(.black)
                                    }
                                    Spacer()
                                    Text(
                                        dateRange(
                                            start: education.startDate, end: education.endDate)
                                    )
                                    .font(.custom("Arial", size: 10))
                                    .foregroundColor(.black)
                                }
                                 if !education.detailsString.isEmpty {
                                     AttributedTextView(attributedString: education.normalizedDetailsAttributedString, fontSize: 11)
                                         .frame(maxWidth: .infinity, alignment: .leading)
                                 }
                            }
                        }
                    }
                }
            }

            // References
            if profile.showReferences && !profile.references.filter({ $0.isVisible }).isEmpty {
                SectionView(title: localizedTitle(for: "references")) {
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
                SectionView(title: localizedTitle(for: "skills")) {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(profile.skills) { skillGroup in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(skillGroup.title)
                                    .font(.custom("Arial", size: 12))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                Text(skillGroup.skills.joined(separator: ", "))
                                    .font(.custom("Arial", size: 11))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
            }

            // Certifications
            if profile.showCertifications
                && !profile.certifications.filter({ $0.isVisible }).isEmpty
            {
                SectionView(title: localizedTitle(for: "certifications")) {
                    VStack(alignment: .leading, spacing: 10) {
                        let visibleCertifications = profile.certifications.filter { $0.isVisible }
                        ForEach(Array(visibleCertifications.enumerated()), id: \.element.id) {
                            index, certification in
                            VStack(alignment: .leading, spacing: 3) {
                                // Nom et date sur la même ligne
                                HStack {
                                    Text(certification.name)
                                        .font(.custom("Arial", size: 11))
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    Spacer()
                                    if let date = certification.date {
                                        Text(formatDate(date))
                                            .font(.custom("Arial", size: 10))
                                            .foregroundColor(.black)
                                    }
                                }

                                // Numéro de certification en dessous
                                if let number = certification.certificationNumber, !number.isEmpty {
                                    Text("ID: \(number)")
                                        .font(.custom("Arial", size: 10))
                                        .foregroundColor(.black)
                                }

                                // Lien web en dessous
                                if let webLink = certification.webLink, !webLink.isEmpty {
                                    Text(webLink)
                                        .font(.custom("Arial", size: 10))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                }
            }

            // Languages
            if profile.showLanguages && !profile.languages.filter({ $0.isVisible }).isEmpty {
                SectionView(title: localizedTitle(for: "languages")) {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(profile.languages.filter({ $0.isVisible })) { language in
                            HStack {
                                Text(language.name)
                                    .font(.custom("Arial", size: 11))
                                    .foregroundColor(.black)
                                if let level = language.level, !level.isEmpty {
                                    Text(" - ")
                                        .font(.custom("Arial", size: 11))
                                        .foregroundColor(.black)
                                    Text(level)
                                        .font(.custom("Arial", size: 11))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: 595, minHeight: 842, alignment: .top)  // A4 size, align to top
        .background(Color.white)

        return isForPDF ? AnyView(content) : AnyView(ScrollView { content })
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
            name: "John Doe", language: "en", firstName: "John", lastName: "Doe",
            email: "john@example.com",
            showPhotoInPDF: true,
            summary: NSAttributedString(string: "Experienced developer").rtf(
                from: NSRange(location: 0, length: 21)) ?? Data(),
            experiences: [
                Experience(
                    company: "Tech Corp", position: nil, startDate: Date(),
                    details: NSAttributedString(string: "Developed apps").rtf(
                        from: NSRange(location: 0, length: 14)) ?? Data())
            ],
            skills: [SkillGroup(title: "Programming Languages", skills: ["Swift", "iOS"])],
            certifications: [
                Certification(
                    name: "Coolest Developer Alive", date: Date(), certificationNumber: "12345",
                    webLink: "https://example.com/cert")
            ],
            languages: [Language(name: "English", level: "Native")]
        ), language: "en", isForPDF: false)
}
