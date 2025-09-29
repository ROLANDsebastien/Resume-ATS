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
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "Cover_Letter_\(coverLetter.title).pdf")

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
        let photoSize: CGFloat = 120
        let photoPadding: CGFloat = 20
        let photoCornerRadius: CGFloat = 10
        let headerHeight: CGFloat = max(photoSize + photoPadding, 140)
        let marginTop: CGFloat = margin

        // Créer la première page
        func createPage() -> (CGContext?, NSMutableData) {
            var pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            let data = NSMutableData()
            guard let consumer = CGDataConsumer(data: data as CFMutableData),
                let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil)
            else {
                return (nil as CGContext?, data)
            }
            context.beginPDFPage(nil)
            // Fond blanc
            context.setFillColor(NSColor.white.cgColor)
            context.fill(pageRect)
            return (context, data)
        }

        var (context, pageData) = createPage()
        guard context != nil else {
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
            _ text: String, font: NSFont, color: NSColor, x: CGFloat, maxWidth: CGFloat
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
                addPageToDocument(context!, pageData)
                pageIndex += 1
                let result = createPage()
                context = result.0
                pageData = result.1
                // Sur les pages suivantes, commencer en haut avec la marge
                currentY = marginTop
            }

            let textRect = CGRect(
                x: x, y: pageHeight - currentY - textHeight, width: maxWidth, height: textHeight)
            let path = CGMutablePath()
            path.addRect(textRect)
            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, context!)
            currentY += textHeight + 10
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
            var hasPlus = false

            for char in phoneString {
                if char == "+" && result.isEmpty {
                    // Garder le + seulement s'il est au début
                    result.append(char)
                    hasPlus = true
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
            mutableString.addAttribute(.foregroundColor, value: NSColor.black, range: NSRange(location: 0, length: mutableString.length))

            // Pour chaque partie du texte, s'assurer qu'elle a une police Arial de taille 12
            mutableString.enumerateAttribute(.font, in: NSRange(location: 0, length: mutableString.length), options: []) { value, range, _ in
                if let currentFont = value as? NSFont {
                    let descriptor = currentFont.fontDescriptor
                    let traits = descriptor.symbolicTraits
                    let newDescriptor = NSFontDescriptor(name: "Arial", size: 12).withSymbolicTraits(traits)
                    if let newFont = NSFont(descriptor: newDescriptor, size: 12) {
                        mutableString.addAttribute(.font, value: newFont, range: range)
                    }
                } else {
                    // Si pas de police, utiliser Arial normale
                    mutableString.addAttribute(.font, value: NSFont(name: "Arial", size: 12) ?? NSFont.systemFont(ofSize: 12), range: range)
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
                addPageToDocument(context!, pageData)
                pageIndex += 1
                let result = createPage()
                context = result.0
                pageData = result.1
                // Sur les pages suivantes, commencer en haut avec la marge
                currentY = marginTop
            }

            let textRect = CGRect(
                x: x, y: pageHeight - currentY - textHeight, width: maxWidth, height: textHeight)
            let path = CGMutablePath()
            path.addRect(textRect)
            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, context!)
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
            context?.saveGState()
            let path = CGPath(
                roundedRect: imageRect, cornerWidth: photoCornerRadius,
                cornerHeight: photoCornerRadius, transform: nil)
            context?.addPath(path)
            context?.clip()
            if let cgImage = image.cgImage(
                forProposedRect: nil as UnsafeMutablePointer<NSRect>?,
                context: nil as NSGraphicsContext?, hints: nil as [NSImageRep.HintKey: Any]?)
            {
                context?.draw(cgImage, in: imageRect)
            }
            context?.restoreGState()
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
                attributedString.append(NSAttributedString(string: "Email: ", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                attributedString.append(NSAttributedString(string: email, attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                contactInfo.append(attributedString)
            }
            if let phone = profile.phone, !phone.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(NSAttributedString(string: "Téléphone: ", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                attributedString.append(NSAttributedString(string: cleanPhoneForATS(phone), attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                contactInfo.append(attributedString)
            }
            if let location = profile.location, !location.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(NSAttributedString(string: "Localisation: ", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                attributedString.append(NSAttributedString(string: location, attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                contactInfo.append(attributedString)
            }
            if let linkedin = profile.linkedin, !linkedin.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(NSAttributedString(string: "LinkedIn: ", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                attributedString.append(NSAttributedString(string: cleanURLDisplay(linkedin), attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                contactInfo.append(attributedString)
            }
            if let github = profile.github, !github.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(NSAttributedString(string: "GitHub: ", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                attributedString.append(NSAttributedString(string: cleanURLDisplay(github), attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                contactInfo.append(attributedString)
            }
            if let gitlab = profile.gitlab, !gitlab.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(NSAttributedString(string: "GitLab: ", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                attributedString.append(NSAttributedString(string: cleanURLDisplay(gitlab), attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                contactInfo.append(attributedString)
            }
            if let website = profile.website, !website.isEmpty {
                let attributedString = NSMutableAttributedString()
                attributedString.append(NSAttributedString(string: "Site Web: ", attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]))
                attributedString.append(NSAttributedString(string: cleanURLDisplay(website), attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
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
                    CTFrameDraw(frame, context!)
                    currentY += textHeight  // pas d'espacement supplémentaire
                    headerBlockHeight += textHeight
                }
                // Positionner le début du contenu sous le header (nom + infos + sans marge)
                currentY = headerHeight + headerBlockHeight
            } else {
                currentY = marginTop
            }

            // Résumé professionnel
            if !profile.summaryString.isEmpty {
                drawText(
                    "Résumé Professionnel", font: NSFont.boldSystemFont(ofSize: 18), color: .black,
                    x: margin, maxWidth: pageWidth - 2 * margin)
                drawAttributedText(
                    profile.normalizedSummaryAttributedString,
                    x: margin, maxWidth: pageWidth - 2 * margin)
            }

            // Expériences professionnelles
            if profile.showExperiences && !profile.experiences.filter({ $0.isVisible }).isEmpty {
                drawText(
                    "Expérience Professionnelle", font: NSFont.boldSystemFont(ofSize: 18),
                    color: .black, x: margin, maxWidth: pageWidth - 2 * margin)
                for experience in profile.experiences.filter({ $0.isVisible }) {
                    // Ligne entreprise + poste à gauche, date à droite sur la même ligne
                    let leftText =
                        experience.company
                        + (experience.position != nil && !experience.position!.isEmpty
                            ? " - \(experience.position!)" : "")
                    let dateText: String = {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM/yyyy"
                        let startStr = formatter.string(from: experience.startDate)
                        if let endDate = experience.endDate {
                            let endStr = formatter.string(from: endDate)
                            return "\(startStr) - \(endStr)"
                        } else {
                            return "\(startStr) - Présent"
                        }
                    }()

                    // Mesurer la hauteur de la ligne
                    let attributesLeft: [NSAttributedString.Key: Any] = [
                        .font: NSFont.boldSystemFont(ofSize: 14),
                        .foregroundColor: NSColor.black,
                    ]
                    let attributesRight: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: 13),
                        .foregroundColor: NSColor.black,
                    ]
                    let leftAttr = NSAttributedString(string: leftText, attributes: attributesLeft)
                    let rightAttr = NSAttributedString(
                        string: dateText, attributes: attributesRight)
                    let leftSize = leftAttr.size()
                    let rightSize = rightAttr.size()
                    let lineHeight = max(leftSize.height, rightSize.height)

                    // Pagination si besoin
                    if currentY + lineHeight > pageHeight - margin {
                        addPageToDocument(context!, pageData)
                        pageIndex += 1
                        let result = createPage()
                        context = result.0
                        pageData = result.1
                        currentY = marginTop
                    }

                    // Dessiner le texte à gauche et la date à droite sur la même ligne en utilisant CTFrameDraw
                    let yPos = pageHeight - currentY - lineHeight
                    let leftRect = CGRect(
                        x: margin, y: yPos, width: pageWidth / 2, height: lineHeight)
                    let leftPath = CGMutablePath()
                    leftPath.addRect(leftRect)
                    let leftFramesetter = CTFramesetterCreateWithAttributedString(leftAttr)
                    let leftFrame = CTFramesetterCreateFrame(
                        leftFramesetter, CFRange(location: 0, length: 0), leftPath, nil)
                    CTFrameDraw(leftFrame, context!)

                    let rightRect = CGRect(
                        x: pageWidth - margin - rightSize.width, y: yPos, width: rightSize.width,
                        height: lineHeight)
                    let rightPath = CGMutablePath()
                    rightPath.addRect(rightRect)
                    let rightFramesetter = CTFramesetterCreateWithAttributedString(rightAttr)
                    let rightFrame = CTFramesetterCreateFrame(
                        rightFramesetter, CFRange(location: 0, length: 0), rightPath, nil)
                    CTFrameDraw(rightFrame, context!)

                    currentY += lineHeight + 2

                    // Détails de l'expérience (pagination gérée par drawAttributedText)
                    drawAttributedText(
                        experience.normalizedDetailsAttributedString,
                        x: margin, maxWidth: pageWidth - 2 * margin)
                }
            }

            // Formation
            if profile.showEducations && !profile.educations.filter({ $0.isVisible }).isEmpty {
                drawText(
                    "Formation", font: NSFont.boldSystemFont(ofSize: 18), color: .black, x: margin,
                    maxWidth: pageWidth - 2 * margin)
                for education in profile.educations.filter({ $0.isVisible }) {
                    drawText(
                        "\(education.institution) - \(education.degree)",
                        font: NSFont.boldSystemFont(ofSize: 14), color: .black, x: margin,
                        maxWidth: pageWidth - 2 * margin)
                    drawAttributedText(
                        education.normalizedDetailsAttributedString,
                        x: margin, maxWidth: pageWidth - 2 * margin)
                }
            }

            // Compétences
            if profile.showSkills && !profile.skills.isEmpty {
                drawText(
                    "Compétences", font: NSFont.boldSystemFont(ofSize: 18), color: .black,
                    x: margin,
                    maxWidth: pageWidth - 2 * margin)
                drawText(
                    profile.skills.joined(separator: ", "), font: NSFont.systemFont(ofSize: 12),
                    color: .black, x: margin, maxWidth: pageWidth - 2 * margin)
            }

            // Ajouter la dernière page
            if let ctx = context {
                addPageToDocument(ctx, pageData)
            }

            // Sauvegarder le PDF
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "ATS_Resume_Paginated_\(profile.name).pdf")
            pdfDocument.write(to: tempURL)

            print("PDF paginé généré avec succès")
            completion(tempURL)
        }
    }
}
