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
    var summary: String
    var experiences: [Experience]
    var educations: [Education]
    var references: [Reference]
    var skills: [String]

    init(
        name: String, summary: String = "", experiences: [Experience] = [],
        educations: [Education] = [], references: [Reference] = [], skills: [String] = []
    ) {
        self.name = name
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
