import AppKit
import Foundation
import PDFKit
import SwiftUI

class PDFService {
    static func generateATSResumePDF(for profile: Profile, completion: @escaping (URL?) -> Void) {
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
        hostingView.frame = CGRect(x: 0, y: 0, width: 595, height: 842)  // A4 size

        // Generate PDF data directly from the hosting view
        let pdfData = hostingView.dataWithPDF(inside: hostingView.bounds)

        print("PDF data size: \(pdfData.count)")

        // Create PDF document
        let pdfDocument = PDFDocument(data: pdfData)

        // Save to temporary file
        pdfDocument?.write(to: tempURL)

        print("PDF generated successfully")
        completion(tempURL)
    }

    static func generateCoverLetterPDF(
        for coverLetter: CoverLetter, completion: @escaping (URL?) -> Void
    ) {
        print("Generating PDF for cover letter: \(coverLetter.title)")

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "Cover_Letter_\(coverLetter.title).pdf")

        // Create a simple view for the cover letter
        let coverLetterView = VStack(alignment: .leading, spacing: 20) {
            Text(coverLetter.title)
                .font(.title)
                .fontWeight(.bold)
            Text(coverLetter.contentString)
                .font(.body)
        }
        .padding()
        .frame(width: 595, height: 842)  // A4 size

        // Create NSHostingView from SwiftUI view
        let hostingView = NSHostingView(rootView: coverLetterView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 595, height: 842)

        // Generate PDF data directly from the hosting view
        let pdfData = hostingView.dataWithPDF(inside: hostingView.bounds)

        print("PDF data size: \(pdfData.count)")

        // Create PDF document
        let pdfDocument = PDFDocument(data: pdfData)

        // Save to temporary file
        pdfDocument?.write(to: tempURL)

        print("Cover letter PDF generated successfully")
        completion(tempURL)
    }

}
