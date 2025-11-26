import Foundation
import SwiftData

@Model
final class Job {
    var id: String
    var title: String
    var company: String
    var location: String
    var salary: String?
    var url: String
    var source: String
    var aiScore: Int?
    var matchReason: String?
    var missingRequirements: [String]
    var isFavorite: Bool
    var isApplied: Bool
    var contractType: String?
    var notes: String
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        company: String,
        location: String,
        salary: String? = nil,
        url: String,
        source: String,
        contractType: String? = nil,
        aiScore: Int? = nil,
        matchReason: String? = nil,
        missingRequirements: [String] = [],
        isFavorite: Bool = false,
        isApplied: Bool = false,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.company = company
        self.location = location
        self.salary = salary
        self.url = url
        self.source = source
        self.contractType = contractType
        self.aiScore = aiScore
        self.matchReason = matchReason
        self.missingRequirements = missingRequirements
        self.isFavorite = isFavorite
        self.isApplied = isApplied
        self.notes = notes
        self.createdAt = createdAt
    }
}