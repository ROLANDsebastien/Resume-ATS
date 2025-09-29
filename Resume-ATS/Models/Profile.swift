//
//  Profile.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import Foundation
import SwiftData
import AppKit

@Model
final class Profile {
    var name: String
    var language: String = "fr"
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var location: String?
    var github: String?
    var gitlab: String?
    var linkedin: String?
    var website: String?
    var photo: Data?
    var showPhotoInPDF: Bool = false
    var summary: Data
    var showExperiences: Bool = true
    var showEducations: Bool = true
    var showReferences: Bool = true
    var showSkills: Bool = true
    @Relationship(deleteRule: .cascade) var experiences: [Experience]
    @Relationship(deleteRule: .cascade) var educations: [Education]
    @Relationship(deleteRule: .cascade) var references: [Reference]
     var skills: [String]

    init(
        name: String, language: String = "fr", firstName: String? = nil, lastName: String? = nil, email: String? = nil,
        phone: String? = nil, location: String? = nil, github: String? = nil, gitlab: String? = nil,
        linkedin: String? = nil, website: String? = nil, photo: Data? = nil, showPhotoInPDF: Bool = false, summary: Data = Data(),
        showExperiences: Bool = true, showEducations: Bool = true, showReferences: Bool = true, showSkills: Bool = true,
        experiences: [Experience] = [],
        educations: [Education] = [], references: [Reference] = [], skills: [String] = []
    ) {
        self.name = name
        self.language = language
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.location = location
        self.github = github
        self.gitlab = gitlab
        self.linkedin = linkedin
        self.website = website
        self.photo = photo
        self.showPhotoInPDF = showPhotoInPDF
        self.summary = summary
        self.showExperiences = showExperiences
        self.showEducations = showEducations
        self.showReferences = showReferences
        self.showSkills = showSkills
        self.experiences = experiences
        self.educations = educations
        self.references = references
        self.skills = skills
    }

    var summaryAttributedString: NSAttributedString {
        get {
            if summary.isEmpty {
                return NSAttributedString(string: "")
            }
            return NSAttributedString(rtf: summary, documentAttributes: nil) ?? NSAttributedString(string: "")
        }
        set {
            summary = newValue.rtf(from: NSRange(location: 0, length: newValue.length)) ?? Data()
        }
    }

    var summaryString: String {
        summaryAttributedString.string
    }

    var normalizedSummaryAttributedString: NSAttributedString {
        let attr = summaryAttributedString.mutableCopy() as! NSMutableAttributedString
        attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length), options: []) { value, range, _ in
            if let currentFont = value as? NSFont {
                let descriptor = currentFont.fontDescriptor
                let traits = descriptor.symbolicTraits
                let newDescriptor = NSFontDescriptor(name: "Arial", size: 11).withSymbolicTraits(traits)
                if let newFont = NSFont(descriptor: newDescriptor, size: 11) {
                    attr.addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        return attr
    }
}

@Model
final class Experience {
    var company: String
    var startDate: Date
    var endDate: Date?
    var details: Data
    var isVisible: Bool = true
    var profile: Profile?

    init(company: String, startDate: Date, endDate: Date? = nil, details: Data = Data(), isVisible: Bool = true) {
        self.company = company
        self.startDate = startDate
        self.endDate = endDate
        self.details = details
        self.isVisible = isVisible
    }

    var detailsAttributedString: NSAttributedString {
        get {
            if details.isEmpty {
                return NSAttributedString(string: "")
            }
            return NSAttributedString(rtf: details, documentAttributes: nil) ?? NSAttributedString(string: "")
        }
        set {
            details = newValue.rtf(from: NSRange(location: 0, length: newValue.length)) ?? Data()
        }
    }

    var detailsString: String {
        detailsAttributedString.string
    }

    var normalizedDetailsAttributedString: NSAttributedString {
        let attr = detailsAttributedString.mutableCopy() as! NSMutableAttributedString
        attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length), options: []) { value, range, _ in
            if let currentFont = value as? NSFont {
                let descriptor = currentFont.fontDescriptor
                let traits = descriptor.symbolicTraits
                let newDescriptor = NSFontDescriptor(name: "Arial", size: 11).withSymbolicTraits(traits)
                if let newFont = NSFont(descriptor: newDescriptor, size: 11) {
                    attr.addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        return attr
    }
}

@Model
final class Education {
    var institution: String
    var degree: String
    var startDate: Date
    var endDate: Date?
    var details: Data
    var isVisible: Bool = true
    var profile: Profile?

    init(
        institution: String, degree: String, startDate: Date, endDate: Date? = nil,
        details: Data = Data(), isVisible: Bool = true
    ) {
        self.institution = institution
        self.degree = degree
        self.startDate = startDate
        self.endDate = endDate
        self.details = details
        self.isVisible = isVisible
    }

    var detailsAttributedString: NSAttributedString {
        get {
            if details.isEmpty {
                return NSAttributedString(string: "")
            }
            return NSAttributedString(rtf: details, documentAttributes: nil) ?? NSAttributedString(string: "")
        }
        set {
            details = newValue.rtf(from: NSRange(location: 0, length: newValue.length)) ?? Data()
        }
    }

    var detailsString: String {
        detailsAttributedString.string
    }

    var normalizedDetailsAttributedString: NSAttributedString {
        let attr = detailsAttributedString.mutableCopy() as! NSMutableAttributedString
        attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length), options: []) { value, range, _ in
            if let currentFont = value as? NSFont {
                let descriptor = currentFont.fontDescriptor
                let traits = descriptor.symbolicTraits
                let newDescriptor = NSFontDescriptor(name: "Arial", size: 11).withSymbolicTraits(traits)
                if let newFont = NSFont(descriptor: newDescriptor, size: 11) {
                    attr.addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        return attr
    }
}

@Model
final class Reference {
    var name: String
    var position: String
    var company: String
    var email: String
    var phone: String
    var isVisible: Bool = true
    var profile: Profile?

    init(name: String, position: String, company: String, email: String, phone: String, isVisible: Bool = true) {
        self.name = name
        self.position = position
        self.company = company
        self.email = email
        self.phone = phone
        self.isVisible = isVisible
    }
}
