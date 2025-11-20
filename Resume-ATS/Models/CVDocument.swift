import Foundation
import SwiftData

@Model
final class CVDocument {
    var name: String
    var dateCreated: Date
    var pdfData: Data?

    init(name: String, dateCreated: Date = Date(), pdfData: Data? = nil) {
        self.name = name
        self.dateCreated = dateCreated
        self.pdfData = pdfData
    }
}