import AppKit
import Foundation
import PDFKit
import SwiftUI

class PDFService {
    static func generateATSResumePDF(for profile: Profile) -> URL? {
        print("Generating PDF for profile: \(profile.name)")
        print("Experiences: \(profile.experiences.count)")
        print("Educations: \(profile.educations.count)")
        print("Skills: \(profile.skills.count)")

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ATS_Resume_\(profile.name).pdf")

        let resumeView = ATSResumeView(profile: profile, isForPDF: true)

        // Create NSHostingView from SwiftUI view
        let hostingView = NSHostingView(rootView: resumeView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 612, height: 792)  // US Letter size

        // Create a temporary window for rendering
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 612, height: 792), styleMask: [], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.orderFront(nil)

        // Allow time for rendering
        usleep(100000) // 0.1 seconds

        // Generate PDF data
        let pdfData = hostingView.dataWithPDF(inside: hostingView.bounds)

        window.close()

        print("PDF data size: \(pdfData.count)")

        // Create PDF document
        let pdfDocument = PDFDocument(data: pdfData)

        // Save to temporary file
        pdfDocument?.write(to: tempURL)

        print("PDF generated successfully")
        return tempURL
    }

}
