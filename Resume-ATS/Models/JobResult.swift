import Foundation

struct JobResult: Identifiable, Codable {
    let id: String
    let title: String
    let company: String
    let location: String
    let salary: String?
    let url: String
    let source: String
    let contractType: String?
    let scrapedAt: Date
    
    init(title: String, company: String, location: String, salary: String? = nil, url: String, source: String, contractType: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.company = company
        self.location = location
        self.salary = salary
        self.url = url
        self.source = source
        self.contractType = contractType
        self.scrapedAt = Date()
    }
}