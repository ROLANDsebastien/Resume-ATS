import AppKit
import Foundation
import PDFKit
import SwiftUI

class PDFService {
    private static func localizedTitle(for key: String, language: String) -> String {
        let enDict: [String: String] = [
            "professional_summary": "Summary",
            "professional_experience": "Experience",
            "education": "Education",
            "references": "References",
            "skills": "Skills",
            "certifications": "Certifications",
            "languages": "Languages",
            "email_prefix": "Email:",
            "phone_prefix": "Phone:",
            "location_prefix": "Location:",
            "github_prefix": "GitHub:",
            "gitlab_prefix": "GitLab:",
            "linkedin_prefix": "LinkedIn:",
            "website_prefix": "Website:",
            "present": "Present",
        ]
        let frDict: [String: String] = [
            "professional_summary": "Résumé",
            "professional_experience": "Expériences",
            "education": "Formation",
            "references": "Références",
            "skills": "Compétences",
            "certifications": "Certifications",
            "languages": "Langues",
            "email_prefix": "Email :",
            "phone_prefix": "Téléphone :",
            "location_prefix": "Localisation :",
            "github_prefix": "GitHub :",
            "gitlab_prefix": "GitLab :",
            "linkedin_prefix": "LinkedIn :",
            "website_prefix": "Site Web :",
            "present": "Présent",
        ]
        if language == "en" {
            return enDict[key] ?? key
        } else {
            return frDict[key] ?? key
        }
    }

    static func generateATSResumePDF(
        for profile: Profile, completion: @escaping (URL?) -> Void
    ) {
        print("Generating PDF for profile: \(profile.name)")
        print("Experiences: \(profile.experiences.count)")
        print("Educations: \(profile.educations.count)")
        print("Skills: \(profile.skills.count)")

        // Save to temporary file
        let sanitizedName = profile.name.replacingOccurrences(
            of: "[^a-zA-Z0-9_\\- ]", with: "_", options: .regularExpression)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ATS_Resume_\(sanitizedName).pdf")

        let resumeView = ATSResumeView(profile: profile, language: profile.language, isForPDF: true)

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
        let sanitizedTitle = coverLetter.title.replacingOccurrences(
            of: "[^a-zA-Z0-9_\\- ]", with: "_", options: .regularExpression)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "Cover_Letter_\(sanitizedTitle).pdf")

        // Create NSTextView for rendering the rich text
        let textView = NSTextView(frame: CGRect(x: 0, y: 0, width: 595, height: 842))
        textView.textStorage?.setAttributedString(coverLetter.normalizedContentAttributedString)
        textView.isEditable = false
        textView.backgroundColor = .white

        // Generate PDF data
        let pdfData = textView.dataWithPDF(inside: textView.bounds)

        // Create PDF document
        let pdfDocument = PDFDocument(data: pdfData)

        // Save to temporary file
        pdfDocument?.write(to: tempURL)

        print("Cover letter PDF generated successfully")
        completion(tempURL)
    }

    static func generateStatisticsPDF(
        applications: [Application], language: String, selectedYear: Int,
        completion: @escaping (URL?) -> Void
    ) {
        print("Generating statistics PDF")

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "Statistics_Report.pdf")

        let statsView = StatisticsPDFView(
            applications: applications, language: language, selectedYear: selectedYear)

        let hostingView = NSHostingView(rootView: statsView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 595, height: 842)

        let pdfData = hostingView.dataWithPDF(inside: hostingView.bounds)

        let pdfDocument = PDFDocument(data: pdfData)
        pdfDocument?.write(to: tempURL)

        print("Statistics PDF generated successfully")
        completion(tempURL)
    }

    /// Nouvelle fonction : Génération PDF paginée pour le CV ATS
    static func generateATSResumePDFWithPagination(
        for profile: Profile, completion: @escaping (URL?) -> Void
    ) {
        print("Génération PDF paginée pour le profil : \(profile.name)")

        // Taille A4 en points
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40

        // Créer le document PDF
        let pdfDocument = PDFDocument()

        // Variables pour la pagination
        var currentY: CGFloat = 0
        var pageIndex = 0
        let photoSize: CGFloat = 140
        let photoPadding: CGFloat = 20
        let photoCornerRadius: CGFloat = 10
        let headerHeight: CGFloat = photoSize + 60
        let marginTop: CGFloat = margin

        // Créer la première page
        func createPage() -> (CGContext?, NSMutableData) {
            var pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            let data = NSMutableData()
            guard let consumer = CGDataConsumer(data: data as CFMutableData),
                let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil)
            else {
                print("Failed to create PDF page context")
                return (nil as CGContext?, data)
            }
            context.beginPDFPage(nil)
            // Fond blanc
            context.setFillColor(NSColor.white.cgColor)
            context.fill(pageRect)
            return (context, data)
        }

        var pageData: NSMutableData
        var initialContext: CGContext?
        (initialContext, pageData) = createPage()
        var context: CGContext
        if let temp = initialContext {
            context = temp
        } else {
            completion(nil)
            return
        }

        // Fonction utilitaire pour changer de page
        func addPageToDocument(_ context: CGContext, _ pageData: NSMutableData) {
            context.endPDFPage()
            context.closePDF()
            if let pdfPageDoc = PDFDocument(data: pageData as Data),
                let pdfPage = pdfPageDoc.page(at: 0)
            {
                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }

        // Fonction pour dessiner du texte avec pagination
        func drawText(
            _ text: String, font: NSFont, color: NSColor, x: CGFloat, maxWidth: CGFloat,
            spacing: CGFloat = 10
        ) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
            ]
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
            let currentRange = CFRange(location: 0, length: attributedText.length)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                framesetter, CFRange(location: 0, length: attributedText.length), nil,
                CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            let textHeight = suggestedSize.height

            // Si le texte ne tient pas sur la page, changer de page
            if currentY + textHeight > pageHeight - margin {
                addPageToDocument(context, pageData)
                pageIndex += 1
                let result = createPage()
                context = result.0!
                pageData = result.1
                // Sur les pages suivantes, commencer en haut avec la marge
                currentY = marginTop
            }

            let textRect = CGRect(
                x: x, y: pageHeight - currentY - textHeight, width: maxWidth, height: textHeight)
            let path = CGMutablePath()
            path.addRect(textRect)
            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, context)
            currentY += textHeight + spacing
        }

        // Fonction pour nettoyer l'affichage des URLs
        func cleanURLDisplay(_ urlString: String) -> String {
            var cleaned = urlString
            // Enlever https://
            if cleaned.hasPrefix("https://") {
                cleaned = String(cleaned.dropFirst(8))
            }
            // Enlever www. si présent
            if cleaned.hasPrefix("www.") {
                cleaned = String(cleaned.dropFirst(4))
            }
            return cleaned
        }

        // Fonction pour nettoyer le numéro de téléphone pour les ATS
        func cleanPhoneForATS(_ phoneString: String) -> String {
            // Garder seulement les chiffres et le + au début
            var result = ""

            for char in phoneString {
                if char == "+" && result.isEmpty {
                    // Garder le + seulement s'il est au début
                    result.append(char)
                } else if char.isNumber {
                    // Garder les chiffres
                    result.append(char)
                }
                // Ignorer tous les autres caractères
            }

            return result
        }

        // Fonction pour dessiner du texte avec attributs et pagination
        func drawAttributedText(
            _ attributedString: NSAttributedString, x: CGFloat, maxWidth: CGFloat
        ) {
            // Créer une copie mutable pour s'assurer que tous les attributs sont corrects
            let mutableString = NSMutableAttributedString(attributedString: attributedString)

            // S'assurer que tout le texte a une police et une couleur
            mutableString.addAttribute(
                .foregroundColor, value: NSColor.black,
                range: NSRange(location: 0, length: mutableString.length))

            // Pour chaque partie du texte, s'assurer qu'elle a une police Arial de taille 10 (plus petite)
            mutableString.enumerateAttribute(
                .font, in: NSRange(location: 0, length: mutableString.length), options: []
            ) { value, range, _ in
                if let currentFont = value as? NSFont {
                    let descriptor = currentFont.fontDescriptor
                    let traits = descriptor.symbolicTraits
                    let newDescriptor = NSFontDescriptor(name: "Arial", size: 10)
                        .withSymbolicTraits(traits)
                    if let newFont = NSFont(descriptor: newDescriptor, size: 10) {
                        mutableString.addAttribute(.font, value: newFont, range: range)
                    }
                } else {
                    // Si pas de police, utiliser Arial normale
                    mutableString.addAttribute(
                        .font,
                        value: NSFont(name: "Arial", size: 10) ?? NSFont.systemFont(ofSize: 10),
                        range: range)
                }
            }

            let framesetter = CTFramesetterCreateWithAttributedString(mutableString)
            let currentRange = CFRange(location: 0, length: mutableString.length)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                framesetter, CFRange(location: 0, length: mutableString.length), nil,
                CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            let textHeight = suggestedSize.height

            // Si le texte ne tient pas sur la page, changer de page
            if currentY + textHeight > pageHeight - margin {
                addPageToDocument(context, pageData)
                pageIndex += 1
                let result = createPage()
                context = result.0!
                pageData = result.1
                // Sur les pages suivantes, commencer en haut avec la marge
                currentY = marginTop
            }

            let textRect = CGRect(
                x: x, y: pageHeight - currentY - textHeight, width: maxWidth, height: textHeight)
            let path = CGMutablePath()
            path.addRect(textRect)
            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, context)
            currentY += textHeight + 10
        }

        // --- HEADER : PHOTO + NOM/CONTACT ---
        // Dessiner la photo de profil arrondie en haut à droite (uniquement sur la première page)
        if pageIndex == 0, profile.showPhotoInPDF, let photoData = profile.photo,
            let image = NSImage(data: photoData)
        {
            let imageRect = CGRect(
                x: pageWidth - margin - photoSize,
                y: pageHeight - margin - photoSize,
                width: photoSize,
                height: photoSize
            )
            context.saveGState()
            let path = CGPath(
                roundedRect: imageRect, cornerWidth: photoCornerRadius,
                cornerHeight: photoCornerRadius, transform: nil)
            context.addPath(path)
            context.clip()
            if let cgImage = image.cgImage(
                forProposedRect: nil as UnsafeMutablePointer<NSRect>?,
                context: nil as NSGraphicsContext?, hints: nil as [NSImageRep.HintKey: Any]?)
            {
                context.draw(cgImage, in: imageRect)
            }
            context.restoreGState()
        }

        // Nom et prénom à gauche de la photo
        let textStartX: CGFloat = margin
        let textMaxWidth: CGFloat = pageWidth - 2 * margin - photoSize - photoPadding

        // Header uniquement sur la première page
        if pageIndex == 0 {
            currentY = marginTop
            if let first = profile.firstName, let last = profile.lastName {
                drawText(
                    "\(first) \(last)", font: NSFont.boldSystemFont(ofSize: 24), color: .black,
                    x: textStartX, maxWidth: textMaxWidth)
            }
            drawText(
                profile.name, font: NSFont.systemFont(ofSize: 14), color: .black, x: textStartX,
                maxWidth: textMaxWidth)

            // Afficher chaque info de contact disponible sur une ligne distincte sous le nom
            var contactInfo: [NSAttributedString] = []
            if let email = profile.email, !email.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(
                    NSAttributedString(
                        string: "Email: ",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 11),
                            .foregroundColor: NSColor.black,
                        ]))
                attributedString.append(
                    NSAttributedString(
                        string: email,
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.darkGray,
                        ]))
                contactInfo.append(attributedString)
            }
            if let phone = profile.phone, !phone.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(
                    NSAttributedString(
                        string: "Téléphone: ",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 11),
                            .foregroundColor: NSColor.black,
                        ]))
                attributedString.append(
                    NSAttributedString(
                        string: cleanPhoneForATS(phone),
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.darkGray,
                        ]))
                contactInfo.append(attributedString)
            }
            if let location = profile.location, !location.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(
                    NSAttributedString(
                        string: "Localisation: ",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 11),
                            .foregroundColor: NSColor.black,
                        ]))
                attributedString.append(
                    NSAttributedString(
                        string: location,
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.darkGray,
                        ]))
                contactInfo.append(attributedString)
            }
            if let linkedin = profile.linkedin, !linkedin.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(
                    NSAttributedString(
                        string: "LinkedIn: ",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 11),
                            .foregroundColor: NSColor.black,
                        ]))
                attributedString.append(
                    NSAttributedString(
                        string: cleanURLDisplay(linkedin),
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.darkGray,
                        ]))
                contactInfo.append(attributedString)
            }
            if let github = profile.github, !github.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(
                    NSAttributedString(
                        string: "GitHub: ",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 11),
                            .foregroundColor: NSColor.black,
                        ]))
                attributedString.append(
                    NSAttributedString(
                        string: cleanURLDisplay(github),
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.darkGray,
                        ]))
                contactInfo.append(attributedString)
            }
            if let gitlab = profile.gitlab, !gitlab.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(
                    NSAttributedString(
                        string: "GitLab: ",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 11),
                            .foregroundColor: NSColor.black,
                        ]))
                attributedString.append(
                    NSAttributedString(
                        string: cleanURLDisplay(gitlab),
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.darkGray,
                        ]))
                contactInfo.append(attributedString)
            }
            if let website = profile.website, !website.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(
                    NSAttributedString(
                        string: "Site Web: ",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 11),
                            .foregroundColor: NSColor.black,
                        ]))
                attributedString.append(
                    NSAttributedString(
                        string: cleanURLDisplay(website),
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.darkGray,
                        ]))
                contactInfo.append(attributedString)
            }
            var headerBlockHeight: CGFloat = 0
            if !contactInfo.isEmpty {
                let infoBlockWidth: CGFloat =
                    (pageWidth - 2 * margin - photoSize - photoPadding) * 0.9
                for attributedText in contactInfo {
                    let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
                    let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                        framesetter, CFRange(location: 0, length: attributedText.length), nil,
                        CGSize(width: infoBlockWidth, height: CGFloat.greatestFiniteMagnitude), nil)
                    let textHeight = suggestedSize.height
                    let textRect = CGRect(
                        x: textStartX, y: pageHeight - currentY - textHeight, width: infoBlockWidth,
                        height: textHeight)
                    let path = CGMutablePath()
                    path.addRect(textRect)
                    let frame = CTFramesetterCreateFrame(
                        framesetter, CFRange(location: 0, length: 0), path, nil)
                    CTFrameDraw(frame, context)
                    currentY += textHeight  // pas d'espacement supplémentaire
                    headerBlockHeight += textHeight
                }
                // Positionner le début du contenu sous le header (nom + infos + sans marge)
                currentY = max(headerHeight, headerBlockHeight) + 5
            } else {
                currentY = marginTop
            }

            for section in profile.sectionsOrder {
                switch section {
                case .summary:
                    if !profile.summaryString.isEmpty {
                        drawText(
                            localizedTitle(for: "professional_summary", language: profile.language),
                            font: NSFont.boldSystemFont(ofSize: 18), color: .black,
                            x: margin, maxWidth: pageWidth - 2 * margin, spacing: 8)
                        drawAttributedText(
                            profile.normalizedSummaryAttributedString,
                            x: margin, maxWidth: pageWidth - 2 * margin)
                    }
                case .experiences:
                    if profile.showExperiences
                        && !profile.experiences.filter({ $0.isVisible }).isEmpty
                    {
                        drawText(
                            localizedTitle(
                                for: "professional_experience", language: profile.language),
                            font: NSFont.boldSystemFont(ofSize: 18),
                            color: .black, x: margin, maxWidth: pageWidth - 2 * margin)
                        for experience in profile.experiences.filter({ $0.isVisible }).sorted(by: {
                            $0.startDate > $1.startDate
                        }) {
                            // Ligne entreprise, date à droite
                            let companyText = experience.company
                            let dateText: String = {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MM/yyyy"
                                let startStr = formatter.string(from: experience.startDate)
                                if let endDate = experience.endDate {
                                    let endStr = formatter.string(from: endDate)
                                    return "\(startStr) - \(endStr)"
                                } else {
                                    return
                                        "\(startStr) - \(localizedTitle(for: "present", language: profile.language))"
                                }
                            }()

                            let companyAttributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.boldSystemFont(ofSize: 12),
                                .foregroundColor: NSColor.black,
                            ]
                            let dateAttributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.systemFont(ofSize: 11),
                                .foregroundColor: NSColor.black,
                            ]

                            let companyAttr = NSAttributedString(
                                string: companyText, attributes: companyAttributes)
                            let dateAttr = NSAttributedString(
                                string: dateText, attributes: dateAttributes)
                            let companySize = companyAttr.size()
                            let dateSize = dateAttr.size()
                            let firstLineHeight = max(companySize.height, dateSize.height)

                            if currentY + firstLineHeight > pageHeight - margin {
                                addPageToDocument(context, pageData)
                                pageIndex += 1
                                let result = createPage()
                                context = result.0!
                                pageData = result.1
                                currentY = marginTop
                            }

                            let yPos = pageHeight - currentY - firstLineHeight
                            let companyRect = CGRect(
                                x: margin, y: yPos, width: pageWidth / 2, height: firstLineHeight)
                            let companyPath = CGMutablePath()
                            companyPath.addRect(companyRect)
                            let companyFramesetter = CTFramesetterCreateWithAttributedString(
                                companyAttr)
                            let companyFrame = CTFramesetterCreateFrame(
                                companyFramesetter, CFRange(location: 0, length: 0), companyPath,
                                nil)
                            CTFrameDraw(companyFrame, context)

                            let dateRect = CGRect(
                                x: pageWidth - margin - dateSize.width, y: yPos,
                                width: dateSize.width, height: firstLineHeight)
                            let datePath = CGMutablePath()
                            datePath.addRect(dateRect)
                            let dateFramesetter = CTFramesetterCreateWithAttributedString(dateAttr)
                            let dateFrame = CTFramesetterCreateFrame(
                                dateFramesetter, CFRange(location: 0, length: 0), datePath, nil)
                            CTFrameDraw(dateFrame, context)

                            currentY += firstLineHeight + 2

                            // Position en dessous
                            if let position = experience.position, !position.isEmpty {
                                drawText(
                                    position,
                                    font: NSFont.systemFont(ofSize: 11),
                                    color: .black,
                                    x: margin,
                                    maxWidth: pageWidth - 2 * margin
                                )
                            }

                            // Détails de l'expérience
                            drawAttributedText(
                                experience.normalizedDetailsAttributedString,
                                x: margin, maxWidth: pageWidth - 2 * margin)
                        }
                    }
                case .educations:
                    if profile.showEducations
                        && !profile.educations.filter({ $0.isVisible }).isEmpty
                    {
                        drawText(
                            localizedTitle(for: "education", language: profile.language),
                            font: NSFont.boldSystemFont(ofSize: 18), color: .black, x: margin,
                            maxWidth: pageWidth - 2 * margin)
                        for education in profile.educations.filter({ $0.isVisible }) {
                            // Institution on left, dates on right
                            let leftText = education.institution
                            let dateText: String = {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MM/yyyy"
                                let startStr = formatter.string(from: education.startDate)
                                if let endDate = education.endDate {
                                    let endStr = formatter.string(from: endDate)
                                    return "\(startStr) - \(endStr)"
                                } else {
                                    return
                                        "\(startStr) - \(localizedTitle(for: "present", language: profile.language))"
                                }
                            }()

                            // Measure heights
                            let attributesLeft: [NSAttributedString.Key: Any] = [
                                .font: NSFont.boldSystemFont(ofSize: 12),
                                .foregroundColor: NSColor.black,
                            ]
                            let attributesRight: [NSAttributedString.Key: Any] = [
                                .font: NSFont.systemFont(ofSize: 11),
                                .foregroundColor: NSColor.black,
                            ]
                            let leftAttr = NSAttributedString(
                                string: leftText, attributes: attributesLeft)
                            let rightAttr = NSAttributedString(
                                string: dateText, attributes: attributesRight)
                            let leftSize = leftAttr.size()
                            let rightSize = rightAttr.size()
                            let lineHeight = max(leftSize.height, rightSize.height)

                            // Pagination if needed
                            if currentY + lineHeight > pageHeight - margin {
                                addPageToDocument(context, pageData)
                                pageIndex += 1
                                let result = createPage()
                                if let newContext = result.0 {
                                    context = newContext
                                } else {
                                    return
                                }
                                pageData = result.1
                                currentY = marginTop
                            }

                            // Draw institution left, dates right
                            let yPos = pageHeight - currentY - lineHeight
                            let leftRect = CGRect(
                                x: margin, y: yPos, width: pageWidth / 2, height: lineHeight)
                            let leftPath = CGMutablePath()
                            leftPath.addRect(leftRect)
                            let leftFramesetter = CTFramesetterCreateWithAttributedString(leftAttr)
                            let leftFrame = CTFramesetterCreateFrame(
                                leftFramesetter, CFRange(location: 0, length: 0), leftPath, nil)
                            CTFrameDraw(leftFrame, context)

                            let rightRect = CGRect(
                                x: pageWidth - margin - rightSize.width, y: yPos,
                                width: rightSize.width, height: lineHeight)
                            let rightPath = CGMutablePath()
                            rightPath.addRect(rightRect)
                            let rightFramesetter = CTFramesetterCreateWithAttributedString(
                                rightAttr)
                            let rightFrame = CTFramesetterCreateFrame(
                                rightFramesetter, CFRange(location: 0, length: 0), rightPath, nil)
                            CTFrameDraw(rightFrame, context)

                            currentY += lineHeight + 2

                            // Degree below
                            drawText(
                                education.degree, font: NSFont.systemFont(ofSize: 11),
                                color: .black, x: margin, maxWidth: pageWidth - 2 * margin)

                            // Details
                            drawAttributedText(
                                education.normalizedDetailsAttributedString, x: margin,
                                maxWidth: pageWidth - 2 * margin)
                        }
                    }
                case .references:
                    if profile.showReferences
                        && !profile.references.filter({ $0.isVisible }).isEmpty
                    {
                        drawText(
                            localizedTitle(for: "references", language: profile.language),
                            font: NSFont.boldSystemFont(ofSize: 18), color: .black, x: margin,
                            maxWidth: pageWidth - 2 * margin)

                        let visibleReferences = profile.references.filter { $0.isVisible }
                        var index = 0
                        while index < visibleReferences.count {
                            let leftReference = visibleReferences[index]

                            // Build left reference text
                            var leftText = "\(leftReference.name) - \(leftReference.position)"
                            if !leftReference.company.isEmpty {
                                leftText += " (\(leftReference.company))"
                            }

                            var leftContactText = ""
                            if !leftReference.email.isEmpty {
                                leftContactText = leftReference.email
                            }
                            if !leftReference.phone.isEmpty {
                                if !leftContactText.isEmpty {
                                    leftContactText += " | \(leftReference.phone)"
                                } else {
                                    leftContactText = leftReference.phone
                                }
                            }

                            let rightReference =
                                (index + 1 < visibleReferences.count)
                                ? visibleReferences[index + 1] : nil
                            var rightText = ""
                            var rightContactText = ""

                            if let rightRef = rightReference {
                                rightText = "\(rightRef.name) - \(rightRef.position)"
                                if !rightRef.company.isEmpty {
                                    rightText += " (\(rightRef.company))"
                                }

                                if !rightRef.email.isEmpty {
                                    rightContactText = rightRef.email
                                }
                                if !rightRef.phone.isEmpty {
                                    if !rightContactText.isEmpty {
                                        rightContactText += " | \(rightRef.phone)"
                                    } else {
                                        rightContactText = rightRef.phone
                                    }
                                }
                            }

                            // Draw left reference (name and position)
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.boldSystemFont(ofSize: 10),
                                .foregroundColor: NSColor.black,
                            ]
                            let leftAttr = NSAttributedString(
                                string: leftText, attributes: attributes)
                            let leftSize = leftAttr.size()
                            let rightAttr = NSAttributedString(
                                string: rightText, attributes: attributes)
                            let rightSize = rightAttr.size()
                            let lineHeight = max(leftSize.height, rightSize.height)

                            // Pagination if needed
                            if currentY + lineHeight + 18 > pageHeight - margin {
                                addPageToDocument(context, pageData)
                                pageIndex += 1
                                let result = createPage()
                                if let newContext = result.0 {
                                    context = newContext
                                } else {
                                    return
                                }
                                pageData = result.1
                                currentY = marginTop
                            }

                            // Draw left name/position
                            let yPos = pageHeight - currentY - lineHeight
                            let leftRect = CGRect(
                                x: margin, y: yPos, width: (pageWidth - 2 * margin) / 2,
                                height: lineHeight)
                            let leftPath = CGMutablePath()
                            leftPath.addRect(leftRect)
                            let leftFramesetter = CTFramesetterCreateWithAttributedString(leftAttr)
                            let leftFrame = CTFramesetterCreateFrame(
                                leftFramesetter, CFRange(location: 0, length: 0), leftPath, nil)
                            CTFrameDraw(leftFrame, context)

                            // Draw right name/position if exists
                            if !rightText.isEmpty {
                                let rightRect = CGRect(
                                    x: margin + (pageWidth - 2 * margin) / 2, y: yPos,
                                    width: (pageWidth - 2 * margin) / 2, height: lineHeight)
                                let rightPath = CGMutablePath()
                                rightPath.addRect(rightRect)
                                let rightFramesetter = CTFramesetterCreateWithAttributedString(
                                    rightAttr)
                                let rightFrame = CTFramesetterCreateFrame(
                                    rightFramesetter, CFRange(location: 0, length: 0), rightPath,
                                    nil)
                                CTFrameDraw(rightFrame, context)
                            }

                            currentY += lineHeight

                            // Draw contact info directly without extra spacing
                            let contactAttributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.systemFont(ofSize: 9),
                                .foregroundColor: NSColor.black,
                            ]

                            var contactLineHeight: CGFloat = 0

                            if !leftContactText.isEmpty || !rightContactText.isEmpty {
                                let leftContactAttr = NSAttributedString(
                                    string: leftContactText, attributes: contactAttributes)
                                let leftContactSize = leftContactAttr.size()
                                let rightContactAttr = NSAttributedString(
                                    string: rightContactText, attributes: contactAttributes)
                                let rightContactSize = rightContactAttr.size()
                                contactLineHeight = max(
                                    leftContactSize.height, rightContactSize.height)

                                // Pagination if needed
                                if currentY + contactLineHeight > pageHeight - margin {
                                    addPageToDocument(context, pageData)
                                    pageIndex += 1
                                    let result = createPage()
                                    if let newContext = result.0 {
                                        context = newContext
                                    } else {
                                        return
                                    }
                                    pageData = result.1
                                    currentY = marginTop
                                }

                                // Draw left contact
                                if !leftContactText.isEmpty {
                                    let contactYPos = pageHeight - currentY - leftContactSize.height
                                    let leftContactRect = CGRect(
                                        x: margin, y: contactYPos,
                                        width: (pageWidth - 2 * margin) / 2,
                                        height: leftContactSize.height)
                                    let leftContactPath = CGMutablePath()
                                    leftContactPath.addRect(leftContactRect)
                                    let leftContactFramesetter =
                                        CTFramesetterCreateWithAttributedString(
                                            leftContactAttr)
                                    let leftContactFrame = CTFramesetterCreateFrame(
                                        leftContactFramesetter, CFRange(location: 0, length: 0),
                                        leftContactPath, nil)
                                    CTFrameDraw(leftContactFrame, context)
                                }

                                // Draw right contact
                                if !rightContactText.isEmpty {
                                    let contactYPos =
                                        pageHeight - currentY - rightContactSize.height
                                    let rightContactRect = CGRect(
                                        x: margin + (pageWidth - 2 * margin) / 2, y: contactYPos,
                                        width: (pageWidth - 2 * margin) / 2,
                                        height: rightContactSize.height)
                                    let rightContactPath = CGMutablePath()
                                    rightContactPath.addRect(rightContactRect)
                                    let rightContactFramesetter =
                                        CTFramesetterCreateWithAttributedString(
                                            rightContactAttr)
                                    let rightContactFrame = CTFramesetterCreateFrame(
                                        rightContactFramesetter, CFRange(location: 0, length: 0),
                                        rightContactPath, nil)
                                    CTFrameDraw(rightContactFrame, context)
                                }

                                currentY += contactLineHeight + 5
                            }

                            index += 2
                        }
                    }
                case .skills:
                    if profile.showSkills && !profile.skills.isEmpty {
                        drawText(
                            localizedTitle(for: "skills", language: profile.language),
                            font: NSFont.boldSystemFont(ofSize: 18), color: .black,
                            x: margin,
                            maxWidth: pageWidth - 2 * margin)

                        // Display skills in 4 columns
                        let columnCount = min(4, profile.skills.count)
                        let columnSpacing: CGFloat = 10  // Spacing between columns
                        let totalSpacing = columnSpacing * CGFloat(columnCount - 1)
                        let columnWidth =
                            (pageWidth - 2 * margin - totalSpacing) / CGFloat(columnCount)

                        // Calculate column heights for pagination
                        var columnHeights: [CGFloat] = Array(repeating: 0, count: columnCount)
                        for col in 0..<columnCount {
                            var height: CGFloat = 0
                            let skillGroup = profile.skills[col]

                            // Title height
                            let titleAttributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.boldSystemFont(ofSize: 10),
                                .foregroundColor: NSColor.black,
                            ]
                            let titleAttr = NSAttributedString(
                                string: skillGroup.title, attributes: titleAttributes)
                            height += titleAttr.size().height + 2

                            // Skills heights
                            let skillAttributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.systemFont(ofSize: 9),
                                .foregroundColor: NSColor.black,
                            ]
                            for skill in skillGroup.skills {
                                let skillAttr = NSAttributedString(
                                    string: skill, attributes: skillAttributes)
                                height += skillAttr.size().height + 1
                            }

                            columnHeights[col] = height
                        }

                        let maxHeight = columnHeights.max() ?? 0

                        // Pagination if needed
                        if currentY + maxHeight > pageHeight - margin {
                            addPageToDocument(context, pageData)
                            pageIndex += 1
                            let result = createPage()
                            if let newContext = result.0 {
                                context = newContext
                            } else {
                                return
                            }
                            pageData = result.1
                            currentY = marginTop
                        }

                        // Draw all columns in parallel
                        for col in 0..<columnCount {
                            let skillGroup = profile.skills[col]
                            let columnX = margin + CGFloat(col) * (columnWidth + columnSpacing)
                            var yOffset: CGFloat = 0

                            // Draw title
                            let titleAttributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.boldSystemFont(ofSize: 10),
                                .foregroundColor: NSColor.black,
                            ]
                            let titleAttr = NSAttributedString(
                                string: skillGroup.title, attributes: titleAttributes)
                            let titleSize = titleAttr.size()

                            let titleRect = CGRect(
                                x: columnX, y: pageHeight - currentY - titleSize.height,
                                width: columnWidth, height: titleSize.height)
                            let titlePath = CGMutablePath()
                            titlePath.addRect(titleRect)
                            let titleFramesetter = CTFramesetterCreateWithAttributedString(
                                titleAttr)
                            let titleFrame = CTFramesetterCreateFrame(
                                titleFramesetter, CFRange(location: 0, length: 0), titlePath,
                                nil)
                            CTFrameDraw(titleFrame, context)

                            yOffset += titleSize.height + 2

                            // Draw skills
                            let skillAttributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.systemFont(ofSize: 9),
                                .foregroundColor: NSColor.black,
                            ]
                            for skill in skillGroup.skills {
                                let skillAttr = NSAttributedString(
                                    string: skill, attributes: skillAttributes)
                                let skillSize = skillAttr.size()

                                let skillRect = CGRect(
                                    x: columnX,
                                    y: pageHeight - currentY - yOffset - skillSize.height,
                                    width: columnWidth, height: skillSize.height)
                                let skillPath = CGMutablePath()
                                skillPath.addRect(skillRect)
                                let skillFramesetter = CTFramesetterCreateWithAttributedString(
                                    skillAttr)
                                let skillFrame = CTFramesetterCreateFrame(
                                    skillFramesetter, CFRange(location: 0, length: 0),
                                    skillPath,
                                    nil)
                                CTFrameDraw(skillFrame, context)

                                yOffset += skillSize.height + 1
                            }
                        }

                        currentY += maxHeight + 5
                    }
                case .certifications:
                    if profile.showCertifications
                        && !profile.certifications.filter({ $0.isVisible }).isEmpty
                    {
                        drawText(
                            localizedTitle(for: "certifications", language: profile.language),
                            font: NSFont.boldSystemFont(ofSize: 18), color: .black,
                            x: margin,
                            maxWidth: pageWidth - 2 * margin)
                        for certification in profile.certifications.filter({ $0.isVisible }) {
                            // Name and date on same line: name left bold, date right normal
                            let leftText = certification.name
                            let dateText: String? = {
                                if let date = certification.date {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "MM/yyyy"
                                    return formatter.string(from: date)
                                }
                                return nil
                            }()
                            if let dateText = dateText {
                                let attributesLeft: [NSAttributedString.Key: Any] = [
                                    .font: NSFont.boldSystemFont(ofSize: 10),
                                    .foregroundColor: NSColor.black,
                                ]
                                let attributesRight: [NSAttributedString.Key: Any] = [
                                    .font: NSFont.systemFont(ofSize: 11),
                                    .foregroundColor: NSColor.black,
                                ]
                                let leftAttr = NSAttributedString(
                                    string: leftText, attributes: attributesLeft)
                                let rightAttr = NSAttributedString(
                                    string: dateText, attributes: attributesRight)
                                let leftSize = leftAttr.size()
                                let rightSize = rightAttr.size()
                                let lineHeight = max(leftSize.height, rightSize.height)
                                // Pagination si besoin
                                if currentY + lineHeight > pageHeight - margin {
                                    addPageToDocument(context, pageData)
                                    pageIndex += 1
                                    let result = createPage()
                                    context = result.0!
                                    pageData = result.1
                                    currentY = marginTop
                                }
                                let yPos = pageHeight - currentY - lineHeight
                                let leftRect = CGRect(
                                    x: margin, y: yPos, width: pageWidth / 2, height: lineHeight)
                                let leftPath = CGMutablePath()
                                leftPath.addRect(leftRect)
                                let leftFramesetter = CTFramesetterCreateWithAttributedString(
                                    leftAttr)
                                let leftFrame = CTFramesetterCreateFrame(
                                    leftFramesetter, CFRange(location: 0, length: 0), leftPath, nil)
                                CTFrameDraw(leftFrame, context)
                                let rightRect = CGRect(
                                    x: pageWidth - margin - rightSize.width, y: yPos,
                                    width: rightSize.width, height: lineHeight)
                                let rightPath = CGMutablePath()
                                rightPath.addRect(rightRect)
                                let rightFramesetter = CTFramesetterCreateWithAttributedString(
                                    rightAttr)
                                let rightFrame = CTFramesetterCreateFrame(
                                    rightFramesetter, CFRange(location: 0, length: 0), rightPath,
                                    nil)
                                CTFrameDraw(rightFrame, context)
                                currentY += lineHeight + 2
                            } else {
                                // Just draw name if no date
                                drawText(
                                    leftText, font: NSFont.boldSystemFont(ofSize: 10),
                                    color: .black,
                                    x: margin, maxWidth: pageWidth - 2 * margin)
                            }
                            // Certification number below
                            if let number = certification.certificationNumber, !number.isEmpty {
                                let numberText = "ID: \(number)"
                                drawText(
                                    numberText, font: NSFont.systemFont(ofSize: 9), color: .black,
                                    x: margin, maxWidth: pageWidth - 2 * margin, spacing: 2)
                            }
                            // Web link below
                            if let webLink = certification.webLink, !webLink.isEmpty {
                                drawText(
                                    webLink, font: NSFont.systemFont(ofSize: 9), color: .black,
                                    x: margin,
                                    maxWidth: pageWidth - 2 * margin)
                            }
                        }
                    }
                case .languages:
                    if profile.showLanguages && !profile.languages.filter({ $0.isVisible }).isEmpty
                    {
                        drawText(
                            localizedTitle(for: "languages", language: profile.language),
                            font: NSFont.boldSystemFont(ofSize: 18), color: .black,
                            x: margin,
                            maxWidth: pageWidth - 2 * margin)
                        let visibleLanguages = profile.languages.filter({ $0.isVisible })
                        var index = 0
                        while index < visibleLanguages.count {
                            let leftLanguage = visibleLanguages[index]
                            var leftText = leftLanguage.name
                            if let level = leftLanguage.level, !level.isEmpty {
                                leftText += " - \(level)"
                            }

                            let rightLanguage =
                                (index + 1 < visibleLanguages.count)
                                ? visibleLanguages[index + 1] : nil
                            var rightText = ""
                            if let rightLang = rightLanguage {
                                rightText = rightLang.name
                                if let level = rightLang.level, !level.isEmpty {
                                    rightText += " - \(level)"
                                }
                            }

                            // Draw left
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.systemFont(ofSize: 10),
                                .foregroundColor: NSColor.black,
                            ]
                            let leftAttr = NSAttributedString(
                                string: leftText, attributes: attributes)
                            let leftSize = leftAttr.size()
                            let rightAttr = NSAttributedString(
                                string: rightText, attributes: attributes)
                            let rightSize = rightAttr.size()
                            let lineHeight = max(leftSize.height, rightSize.height)

                            // Pagination if needed
                            if currentY + lineHeight > pageHeight - margin {
                                addPageToDocument(context, pageData)
                                pageIndex += 1
                                let result = createPage()
                                if let newContext = result.0 {
                                    context = newContext
                                } else {
                                    return
                                }
                                pageData = result.1
                                currentY = marginTop
                            }

                            // Draw left
                            let yPos = pageHeight - currentY - lineHeight
                            let leftRect = CGRect(
                                x: margin, y: yPos, width: (pageWidth - 2 * margin) / 2,
                                height: lineHeight)
                            let leftPath = CGMutablePath()
                            leftPath.addRect(leftRect)
                            let leftFramesetter = CTFramesetterCreateWithAttributedString(leftAttr)
                            let leftFrame = CTFramesetterCreateFrame(
                                leftFramesetter, CFRange(location: 0, length: 0), leftPath, nil)
                            CTFrameDraw(leftFrame, context)

                            // Draw right if exists
                            if !rightText.isEmpty {
                                let rightRect = CGRect(
                                    x: margin + (pageWidth - 2 * margin) / 2, y: yPos,
                                    width: (pageWidth - 2 * margin) / 2, height: lineHeight)
                                let rightPath = CGMutablePath()
                                rightPath.addRect(rightRect)
                                let rightFramesetter = CTFramesetterCreateWithAttributedString(
                                    rightAttr)
                                let rightFrame = CTFramesetterCreateFrame(
                                    rightFramesetter, CFRange(location: 0, length: 0), rightPath,
                                    nil)
                                CTFrameDraw(rightFrame, context)
                            }

                            currentY += lineHeight + 5
                            index += 2
                        }
                    }
                }
            }

            // Ajouter la dernière page
            let ctx = context
            addPageToDocument(ctx, pageData)
        }

        // Sauvegarder le PDF
        let sanitizedName = profile.name.replacingOccurrences(
            of: "[^a-zA-Z0-9_\\- ]", with: "_", options: .regularExpression)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ATS_Resume_Paginated_\(sanitizedName).pdf")
        pdfDocument.write(to: tempURL)

        print("PDF paginé généré avec succès")
        completion(tempURL)
    }
}
