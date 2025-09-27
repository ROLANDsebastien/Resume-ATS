import AppKit
import Foundation
import PDFKit
import SwiftUI

class PDFService {
    static func generateATSResumePDF(for profile: Profile) -> URL? {
        let resumeView = ATSResumeView(profile: profile)

        // Create NSHostingView from SwiftUI view
        let hostingView = NSHostingView(rootView: resumeView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 612, height: 792)  // US Letter size

        // Generate PDF data
        let pdfData = hostingView.dataWithPDF(inside: hostingView.bounds)

        // Create PDF document
        let pdfDocument = PDFDocument(data: pdfData)

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ATS_Resume_\(profile.name).pdf")
        pdfDocument?.write(to: tempURL)

        return tempURL
    }

}
