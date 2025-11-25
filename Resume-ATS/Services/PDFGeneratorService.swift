import Foundation
import AppKit
import PDFKit

/// Service for generating PDF documents
class PDFGeneratorService {
    
    // Generate a PDF from text content with basic formatting
    static func generatePDF(
        from text: String,
        title: String,
        outputURL: URL
    ) -> Bool {
        // Create a print info for PDF generation
        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 595, height: 842) // A4 size in points
        printInfo.topMargin = 50
        printInfo.bottomMargin = 50
        printInfo.leftMargin = 50
        printInfo.rightMargin = 50
        
        // Create attributed string with formatting
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .left
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.black
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Create a text view for rendering
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 495, height: 742))
        textView.textStorage?.setAttributedString(attributedString)
        
        // Generate PDF
        let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
        printOperation.showsPrintPanel = false
        printOperation.showsProgressPanel = false
        
        // Save to file
        printOperation.pdfPanel.options.insert(.showsPaperSize)
        printOperation.pdfPanel.options.insert(.showsOrientation)
        
        do {
            let pdfData = textView.dataWithPDF(inside: textView.bounds)
            try pdfData.write(to: outputURL)
            return true
        } catch {
            print("❌ [PDF] Error generating PDF: \(error)")
            return false
        }
    }
    
    // Generate a formatted CV PDF
    static func generateCVPDF(
        profile: Profile,
        language: LanguageDetector.Language,
        outputURL: URL
    ) -> Bool {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        
        let page = PDFPage()
        page.setBounds(pageRect, for: .mediaBox)
        
        // Create graphics context
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else { return false }
        
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return false }
        
        context.beginPage(mediaBox: &mediaBox)
        
        // Draw content
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext
        
        var yPosition: CGFloat = 792 // Start from top
        let leftMargin: CGFloat = 50
        
        // Helper function to draw text
        func drawText(_ text: String, fontSize: CGFloat, bold: Bool = false, y: inout CGFloat) {
            let font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let size = attributedString.size()
            attributedString.draw(at: CGPoint(x: leftMargin, y: y - size.height))
            y -= (size.height + 10)
        }
        
        // Title
        let cvTitle: String
        switch language {
        case .french: cvTitle = "Curriculum Vitae"
        case .dutch: cvTitle = "Curriculum Vitae"
        case .english: cvTitle = "Resume"
        }
        drawText(cvTitle, fontSize: 24, bold: true, y: &yPosition)
        yPosition -= 10
        
        // Personal Info
        let name = "\(profile.firstName ?? "") \(profile.lastName ?? "")"
        drawText(name, fontSize: 18, bold: true, y: &yPosition)
        
        if let email = profile.email, !email.isEmpty {
            drawText(email, fontSize: 11, y: &yPosition)
        }
        if let phone = profile.phone, !phone.isEmpty {
            drawText(phone, fontSize: 11, y: &yPosition)
        }
        
        yPosition -= 20
        
        // Summary
        let summaryTitle: String
        switch language {
        case .french: summaryTitle = "Profil"
        case .dutch: summaryTitle = "Profiel"
        case .english: summaryTitle = "Summary"
        }
        drawText(summaryTitle, fontSize: 14, bold: true, y: &yPosition)
        let summary = profile.summaryString
        if !summary.isEmpty {
            drawText(summary, fontSize: 11, y: &yPosition)
        }
        yPosition -= 20
        
        // Skills
        let skillsTitle: String
        switch language {
        case .french: skillsTitle = "Compétences"
        case .dutch: skillsTitle = "Vaardigheden"
        case .english: skillsTitle = "Skills"
        }
        drawText(skillsTitle, fontSize: 14, bold: true, y: &yPosition)
        let skills = profile.skills.flatMap { $0.skillsArray }.joined(separator: ", ")
        if !skills.isEmpty {
            drawText(skills, fontSize: 11, y: &yPosition)
        }
        yPosition -= 20
        
        // Experience
        let experienceTitle: String
        switch language {
        case .french: experienceTitle = "Expérience Professionnelle"
        case .dutch: experienceTitle = "Werkervaring"
        case .english: experienceTitle = "Work Experience"
        }
        drawText(experienceTitle, fontSize: 14, bold: true, y: &yPosition)
        
        for exp in profile.experiences.sorted(by: { $0.startDate > $1.startDate }) {
            let position = exp.position ?? "Position"
            let company = exp.company
            let dates = "\(exp.startDate.formatted(.dateTime.year())) - \(exp.endDate?.formatted(.dateTime.year()) ?? "Present")"
            
            drawText("\(position) - \(company)", fontSize: 11, bold: true, y: &yPosition)
            drawText(dates, fontSize: 10, y: &yPosition)
            yPosition -= 5
        }
        
        yPosition -= 15
        
        // Education
        let educationTitle: String
        switch language {
        case .french: educationTitle = "Formation"
        case .dutch: educationTitle = "Opleiding"
        case .english: educationTitle = "Education"
        }
        drawText(educationTitle, fontSize: 14, bold: true, y: &yPosition)
        
        for edu in profile.educations.sorted(by: { $0.startDate > $1.startDate }) {
            let degree = edu.degree
            let institution = edu.institution
            let dates = "\(edu.startDate.formatted(.dateTime.year())) - \(edu.endDate?.formatted(.dateTime.year()) ?? "Present")"
            
            drawText("\(degree) - \(institution)", fontSize: 11, bold: true, y: &yPosition)
            drawText(dates, fontSize: 10, y: &yPosition)
            yPosition -= 5
        }
        
        context.endPage()
        context.closePDF()
        
        // Save PDF
        do {
            try data.write(to: outputURL)
            return true
        } catch {
            print("❌ [PDF] Error saving CV PDF: \(error)")
            return false
        }
    }
}
