//
//  Profile.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 21/09/2025.
//

import Foundation
import SwiftData

@Model
final class Profile {
    var name: String
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var location: String?
    var github: String?
    var gitlab: String?
    var linkedin: String?
    var summary: String
    var experiences: [Experience]
    var educations: [Education]
    var references: [Reference]
    var skills: [String]

    init(
        name: String, firstName: String? = nil, lastName: String? = nil, email: String? = nil,
        phone: String? = nil, location: String? = nil, github: String? = nil, gitlab: String? = nil,
        linkedin: String? = nil, summary: String = "", experiences: [Experience] = [],
        educations: [Education] = [], references: [Reference] = [], skills: [String] = []
    ) {
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.location = location
        self.github = github
        self.gitlab = gitlab
        self.linkedin = linkedin
        self.summary = summary
        self.experiences = experiences
        self.educations = educations
        self.references = references
        self.skills = skills
    }
}

struct Experience: Codable, Hashable {
    var company: String
    var startDate: Date
    var endDate: Date?
    var description: String
}

struct Education: Codable, Hashable {
    var institution: String
    var degree: String
    var startDate: Date
    var endDate: Date?
    var description: String
}

struct Reference: Codable, Hashable {
    var name: String
    var position: String
    var company: String
    var email: String
    var phone: String
}
