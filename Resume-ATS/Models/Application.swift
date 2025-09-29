//
//  Application.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import Foundation
import SwiftData

@Model
final class Application {
    var company: String
    var position: String
    var dateApplied: Date
    var status: Status
    var notes: String
    var documentBookmarks: [Data]?
    var profile: Profile?
    var coverLetter: CoverLetter?

    init(
        company: String, position: String, dateApplied: Date = Date(), status: Status = .applied,
        notes: String = "", documentBookmarks: [Data]? = nil, coverLetter: CoverLetter? = nil
    ) {
        self.company = company
        self.position = position
        self.dateApplied = dateApplied
        self.status = status
        self.notes = notes
        self.documentBookmarks = documentBookmarks
        self.coverLetter = coverLetter
    }

    enum Status: String, Codable, CaseIterable {
        case applied = "Candidature envoyée"
        case pending = "En attente"
        case interviewing = "Entretien"
        case rejected = "Refusée"
        case accepted = "Acceptée"
        case withdrawn = "Retirée"

        func localizedString(language: String) -> String {
            switch self {
            case .applied:
                return language == "fr" ? "Candidature envoyée" : "Applied"
            case .pending:
                return language == "fr" ? "En attente" : "Pending"
            case .interviewing:
                return language == "fr" ? "Entretien" : "Interviewing"
            case .rejected:
                return language == "fr" ? "Refusée" : "Rejected"
            case .accepted:
                return language == "fr" ? "Acceptée" : "Accepted"
            case .withdrawn:
                return language == "fr" ? "Retirée" : "Withdrawn"
            }
        }
    }
}
