//
//  DataService.swift
//  Resume-ATS
//
//  Created by opencode on 2025-09-27.
//

import AppKit
import Foundation
import SwiftData

class DataService {
    struct SerializableSkillGroup: Codable {
        let title: String
        let skills: [String]
    }

    struct SerializableCertification: Codable {
        let name: String
        let date: Date?
        let certificationNumber: String?
        let webLink: String?
        let isVisible: Bool
    }

    struct SerializableLanguage: Codable {
        let name: String
        let level: String?
        let isVisible: Bool
    }

    // Serializable structs
    struct SerializableProfile: Codable {
        let name: String
        let firstName: String?
        let lastName: String?
        let email: String?
        let phone: String?
        let location: String?
        let github: String?
        let gitlab: String?
        let linkedin: String?
        let website: String?
        let photo: Data?
        let showPhotoInPDF: Bool
        let summary: Data
        let showExperiences: Bool
        let showEducations: Bool
        let showReferences: Bool
        let showSkills: Bool
        let showCertifications: Bool
        let showLanguages: Bool
        let experiences: [SerializableExperience]
        let educations: [SerializableEducation]
        let references: [SerializableReference]
        let skills: [SerializableSkillGroup]
        let certifications: [SerializableCertification]
        let languages: [SerializableLanguage]
    }

    struct SerializableExperience: Codable {
        let company: String
        let position: String?
        let startDate: Date
        let endDate: Date?
        let details: Data
        let isVisible: Bool
    }

    struct SerializableEducation: Codable {
        let institution: String
        let degree: String
        let startDate: Date
        let endDate: Date?
        let details: Data
        let isVisible: Bool
    }

    struct SerializableReference: Codable {
        let name: String
        let position: String
        let company: String
        let email: String
        let phone: String
        let isVisible: Bool
    }

    struct SerializableCoverLetter: Codable {
        let title: String
        let content: Data
        let creationDate: Date
    }

    struct SerializableCVDocument: Codable {
        let name: String
        let dateCreated: Date
        let pdfPath: String?  // Chemin relatif du PDF dans l'archive
    }

    struct SerializableApplication: Codable {
        let company: String
        let position: String
        let dateApplied: Date
        let status: String
        let notes: String
        let source: String?
        let documentPaths: [String]?  // Chemins relatifs des documents dans l'archive
        let profileName: String  // Ajout pour lier à un profil
        let coverLetterTitle: String?  // Ajout pour lier à une lettre
    }

    struct ExportData: Codable {
        let profiles: [SerializableProfile]
        let coverLetters: [SerializableCoverLetter]?
        let applications: [SerializableApplication]
        let cvDocuments: [SerializableCVDocument]?
        let exportDate: Date
        let version: String
    }

    static func exportProfiles(
        _ profiles: [Profile], coverLetters: [CoverLetter], applications: [Application], cvDocuments: [CVDocument]
    ) -> URL? {
        let fileManager = FileManager.default

        // Créer un dossier temporaire pour l'export
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(
            "ResumeATS_Export_\(UUID().uuidString)")
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Créer le dossier pour les documents
        let documentsDir = tempDir.appendingPathComponent("Documents")
        try? fileManager.createDirectory(at: documentsDir, withIntermediateDirectories: true)

        // Sérialiser les profils
        let serializableProfiles = profiles.map { profile in
            SerializableProfile(
                name: profile.name,
                firstName: profile.firstName,
                lastName: profile.lastName,
                email: profile.email,
                phone: profile.phone,
                location: profile.location,
                github: profile.github,
                gitlab: profile.gitlab,
                linkedin: profile.linkedin,
                website: profile.website,
                photo: profile.photo,
                showPhotoInPDF: profile.showPhotoInPDF,
                summary: profile.summary,
                showExperiences: profile.showExperiences,
                showEducations: profile.showEducations,
                showReferences: profile.showReferences,
                showSkills: profile.showSkills,
                showCertifications: profile.showCertifications,
                showLanguages: profile.showLanguages,
                experiences: profile.experiences.map { exp in
                    SerializableExperience(
                        company: exp.company,
                        position: exp.position,
                        startDate: exp.startDate,
                        endDate: exp.endDate,
                        details: exp.details,
                        isVisible: exp.isVisible
                    )
                },
                educations: profile.educations.map { edu in
                    SerializableEducation(
                        institution: edu.institution,
                        degree: edu.degree,
                        startDate: edu.startDate,
                        endDate: edu.endDate,
                        details: edu.details,
                        isVisible: edu.isVisible
                    )
                },
                references: profile.references.map { ref in
                    SerializableReference(
                        name: ref.name,
                        position: ref.position,
                        company: ref.company,
                        email: ref.email,
                        phone: ref.phone,
                        isVisible: ref.isVisible
                    )
                },
                skills: profile.skills.map { skillGroup in
                    SerializableSkillGroup(title: skillGroup.title, skills: skillGroup.skills)
                },
                certifications: profile.certifications.map { cert in
                    SerializableCertification(
                        name: cert.name, date: cert.date,
                        certificationNumber: cert.certificationNumber, webLink: cert.webLink,
                        isVisible: cert.isVisible)
                },
                languages: profile.languages.map { lang in
                    SerializableLanguage(
                        name: lang.name, level: lang.level, isVisible: lang.isVisible)
                }
            )
        }
        // Sérialiser les lettres de motivation
        let serializableCoverLetters = coverLetters.map { coverLetter in
            SerializableCoverLetter(
                title: coverLetter.title,
                content: coverLetter.content,
                creationDate: coverLetter.creationDate
            )
        }

        // Traiter les applications et copier les documents
        var serializableApplications: [SerializableApplication] = []

        for application in applications {
            var documentPaths: [String]? = nil

            if let bookmarks = application.documentBookmarks {
                documentPaths = []
                for bookmark in bookmarks {
                    do {
                        var isStale = false
                        let url = try URL(
                            resolvingBookmarkData: bookmark, options: .withSecurityScope,
                            relativeTo: nil, bookmarkDataIsStale: &isStale)

                        if !isStale && url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            let documentName = url.lastPathComponent
                            let destinationURL = documentsDir.appendingPathComponent(documentName)

                            // Copier le fichier
                            try fileManager.copyItem(at: url, to: destinationURL)
                            documentPaths?.append(documentName)
                        }
                    } catch {
                        print("Erreur lors de la copie du document: \(error)")
                    }
                }
            }

            let serializableApp = SerializableApplication(
                company: application.company,
                position: application.position,
                dateApplied: application.dateApplied,
                status: application.status.rawValue,
                notes: application.notes,
                source: application.source,
                documentPaths: documentPaths,
                profileName: application.profile?.name ?? "",
                coverLetterTitle: application.coverLetter?.title
            )
            serializableApplications.append(serializableApp)
        }

        // Traiter les CVs et copier les PDFs
        var serializableCVs: [SerializableCVDocument] = []

        for cvDocument in cvDocuments {
            var pdfPath: String? = nil

            if let bookmark = cvDocument.pdfBookmark {
                do {
                    var isStale = false
                    let url = try URL(
                        resolvingBookmarkData: bookmark, options: .withSecurityScope,
                        relativeTo: nil, bookmarkDataIsStale: &isStale)

                    if !isStale && url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        let pdfName = url.lastPathComponent
                        let destinationURL = documentsDir.appendingPathComponent(pdfName)

                        // Copier le fichier
                        try fileManager.copyItem(at: url, to: destinationURL)
                        pdfPath = pdfName
                    }
                } catch {
                    print("Erreur lors de la copie du CV: \(error)")
                }
            }

            let serializableCV = SerializableCVDocument(
                name: cvDocument.name,
                dateCreated: cvDocument.dateCreated,
                pdfPath: pdfPath
            )
            serializableCVs.append(serializableCV)
        }

        let exportData = ExportData(
            profiles: serializableProfiles,
            coverLetters: serializableCoverLetters,
            applications: serializableApplications,
            cvDocuments: serializableCVs,
            exportDate: Date(),
            version: "1.2"
        )

        // Écrire le fichier JSON
        let jsonURL = tempDir.appendingPathComponent("data.json")
        let jsonData = try? JSONEncoder().encode(exportData)
        try? jsonData?.write(to: jsonURL)

        // Créer l'archive ZIP
        let zipURL = fileManager.temporaryDirectory.appendingPathComponent(
            "ResumeATS_Backup_\(Date().formatted(.iso8601.dateSeparator(.dash))).zip")

        // Utiliser ditto pour créer l'archive (commande macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", tempDir.path, zipURL.path]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                // Nettoyer le dossier temporaire
                try? fileManager.removeItem(at: tempDir)
                return zipURL
            }
        } catch {
            print("Erreur lors de la création de l'archive: \(error)")
        }

        // Nettoyer en cas d'erreur
        try? fileManager.removeItem(at: tempDir)
        return nil
    }

    static func importProfiles(from zipURL: URL, context: ModelContext) throws {
        let fileManager = FileManager.default

        // Créer un dossier temporaire pour extraire l'archive
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(
            "ResumeATS_Import_\(UUID().uuidString)")
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Extraire l'archive
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zipURL.path, tempDir.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "DataService", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Erreur lors de l'extraction de l'archive"])
        }

        // Lire le fichier JSON
        let jsonURL = tempDir.appendingPathComponent("data.json")
        let jsonData = try Data(contentsOf: jsonURL)
        let exportData = try JSONDecoder().decode(ExportData.self, from: jsonData)

        // --- Prévention des doublons ---
        // Récupérer les profils existants pour éviter les doublons
        let existingProfiles = try context.fetch(FetchDescriptor<Profile>())
        let existingProfileNames = Set(existingProfiles.map { $0.name })

        // Récupérer les lettres existantes pour éviter les doublons
        let existingCoverLetters = try context.fetch(FetchDescriptor<CoverLetter>())
        let existingCoverLetterTitles = Set(existingCoverLetters.map { $0.title })

        // Récupérer les candidatures existantes pour éviter les doublons
        let existingApplications = try context.fetch(FetchDescriptor<Application>())
        let existingApplicationKeys = Set(
            existingApplications.map {
                "\($0.company)|\($0.position)|\($0.dateApplied.timeIntervalSince1970)"
            })

        // Récupérer les CVs existants pour éviter les doublons
        let existingCVs = try context.fetch(FetchDescriptor<CVDocument>())
        let existingCVNames = Set(existingCVs.map { $0.name })

        // Importer les profils non existants
        for serializableProfile in exportData.profiles
        where !existingProfileNames.contains(serializableProfile.name) {
            let profile = Profile(
                name: serializableProfile.name,
                firstName: serializableProfile.firstName,
                lastName: serializableProfile.lastName,
                email: serializableProfile.email,
                phone: serializableProfile.phone,
                location: serializableProfile.location,
                github: serializableProfile.github,
                gitlab: serializableProfile.gitlab,
                linkedin: serializableProfile.linkedin,
                website: serializableProfile.website,
                photo: serializableProfile.photo,
                showPhotoInPDF: serializableProfile.showPhotoInPDF,
                summary: serializableProfile.summary,
                showExperiences: serializableProfile.showExperiences,
                showEducations: serializableProfile.showEducations,
                showReferences: serializableProfile.showReferences,
                showSkills: serializableProfile.showSkills,
                showCertifications: serializableProfile.showCertifications,
                showLanguages: serializableProfile.showLanguages
            )

            // Add experiences
            for exp in serializableProfile.experiences {
                let experience = Experience(
                    company: exp.company,
                    position: exp.position,
                    startDate: exp.startDate,
                    endDate: exp.endDate,
                    details: exp.details,
                    isVisible: exp.isVisible
                )
                experience.profile = profile
                profile.experiences.append(experience)
            }

            // Add educations
            for edu in serializableProfile.educations {
                let education = Education(
                    institution: edu.institution,
                    degree: edu.degree,
                    startDate: edu.startDate,
                    endDate: edu.endDate,
                    details: edu.details,
                    isVisible: edu.isVisible
                )
                education.profile = profile
                profile.educations.append(education)
            }

            // Add references
            for ref in serializableProfile.references {
                let reference = Reference(
                    name: ref.name,
                    position: ref.position,
                    company: ref.company,
                    email: ref.email,
                    phone: ref.phone,
                    isVisible: ref.isVisible
                )
                reference.profile = profile
                profile.references.append(reference)
            }

            // Add skills
            for skillGroup in serializableProfile.skills {
                let newSkillGroup = SkillGroup(
                    title: skillGroup.title,
                    skills: skillGroup.skills
                )
                newSkillGroup.profile = profile
                profile.skills.append(newSkillGroup)
            }

            // Add certifications
            for cert in serializableProfile.certifications {
                let newCertification = Certification(
                    name: cert.name,
                    date: cert.date,
                    certificationNumber: cert.certificationNumber,
                    webLink: cert.webLink,
                    isVisible: cert.isVisible
                )
                newCertification.profile = profile
                profile.certifications.append(newCertification)
            }

            // Add languages
            for lang in serializableProfile.languages {
                let newLanguage = Language(
                    name: lang.name,
                    level: lang.level,
                    isVisible: lang.isVisible
                )
                newLanguage.profile = profile
                profile.languages.append(newLanguage)
            }

            context.insert(profile)
        }

        // Importer les lettres de motivation non existantes
        if let serializableCoverLetters = exportData.coverLetters {
            for serializableCoverLetter in serializableCoverLetters
            where !existingCoverLetterTitles.contains(serializableCoverLetter.title) {
                let coverLetter = CoverLetter(
                    title: serializableCoverLetter.title,
                    content: serializableCoverLetter.content,
                    creationDate: serializableCoverLetter.creationDate
                )
                context.insert(coverLetter)
            }
        }

        // Créer une map pour un accès rapide aux profils par nom
        var profileMap: [String: Profile] = [:]
        for profile in existingProfiles {
            profileMap[profile.name] = profile
        }
        for profile in context.insertedModelsArray.compactMap({ $0 as? Profile }) {
            profileMap[profile.name] = profile
        }

        // Créer une map pour un accès rapide aux lettres par titre
        var coverLetterMap: [String: CoverLetter] = [:]
        for coverLetter in existingCoverLetters {
            coverLetterMap[coverLetter.title] = coverLetter
        }
        for coverLetter in context.insertedModelsArray.compactMap({ $0 as? CoverLetter }) {
            coverLetterMap[coverLetter.title] = coverLetter
        }

        // Importer les applications
        let documentsDir = tempDir.appendingPathComponent("Documents")

        // Créer un dossier permanent pour les documents importés
        let appDocumentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ResumeATS_Documents")
        try? fileManager.createDirectory(at: appDocumentsDir, withIntermediateDirectories: true)

        for serializableApp in exportData.applications
        where !existingApplicationKeys.contains(
            "\(serializableApp.company)|\(serializableApp.position)|\(serializableApp.dateApplied.timeIntervalSince1970)"
        ) {
            var bookmarks: [Data]? = nil

            if let documentPaths = serializableApp.documentPaths {
                bookmarks = []
                for path in documentPaths {
                    let tempDocumentURL = documentsDir.appendingPathComponent(path)
                    let permanentURL = appDocumentsDir.appendingPathComponent(path)

                    // Ensure the source file exists
                    guard fileManager.fileExists(atPath: tempDocumentURL.path) else {
                        print("Document source file not found after extraction: \(path)")
                        continue
                    }

                    // Try to copy the item
                    do {
                        try fileManager.copyItem(at: tempDocumentURL, to: permanentURL)
                    } catch let error as NSError {
                        // If the error is that the file already exists, we can ignore it.
                        // Cocoa error code 516 is "file exists".
                        if !(error.domain == NSCocoaErrorDomain && error.code == 516) {
                            // If it's a different error, print it and skip this document.
                            print("Failed to copy document \(path): \(error)")
                            continue
                        }
                    }

                    // At this point, the file is guaranteed to be at permanentURL. Create the bookmark.
                    do {
                        let bookmark = try permanentURL.bookmarkData(
                            options: .withSecurityScope, includingResourceValuesForKeys: nil,
                            relativeTo: nil)
                        bookmarks?.append(bookmark)
                    } catch {
                        print("Failed to create bookmark for document \(path): \(error)")
                    }
                }
            }

            let status = Application.Status(rawValue: serializableApp.status) ?? .applied
            let application = Application(
                company: serializableApp.company,
                position: serializableApp.position,
                dateApplied: serializableApp.dateApplied,
                status: status,
                notes: serializableApp.notes,
                source: serializableApp.source,
                documentBookmarks: bookmarks
            )

            // Lier l'application au bon profil
            if !serializableApp.profileName.isEmpty {
                application.profile = profileMap[serializableApp.profileName]
            }

            // Lier l'application à la bonne lettre
            if let coverLetterTitle = serializableApp.coverLetterTitle {
                application.coverLetter = coverLetterMap[coverLetterTitle]
            }

            context.insert(application)
        }

        // Importer les CVs
        if let serializableCVs = exportData.cvDocuments {
            for serializableCV in serializableCVs where !existingCVNames.contains(serializableCV.name) {
                var bookmark: Data? = nil

                if let pdfPath = serializableCV.pdfPath {
                    let tempPDFURL = documentsDir.appendingPathComponent(pdfPath)
                    let permanentURL = appDocumentsDir.appendingPathComponent(pdfPath)

                    // Ensure the source file exists
                    guard fileManager.fileExists(atPath: tempPDFURL.path) else {
                        print("CV source file not found after extraction: \(pdfPath)")
                        continue
                    }

                    // Try to copy the item
                    do {
                        try fileManager.copyItem(at: tempPDFURL, to: permanentURL)
                    } catch let error as NSError {
                        // If the error is that the file already exists, we can ignore it.
                        // Cocoa error code 516 is "file exists".
                        if !(error.domain == NSCocoaErrorDomain && error.code == 516) {
                            // If it's a different error, print it and skip this document.
                            print("Failed to copy CV \(pdfPath): \(error)")
                            continue
                        }
                    }

                    // At this point, the file is guaranteed to be at permanentURL. Create the bookmark.
                    do {
                        bookmark = try permanentURL.bookmarkData(
                            options: .withSecurityScope, includingResourceValuesForKeys: nil,
                            relativeTo: nil)
                    } catch {
                        print("Failed to create bookmark for CV \(pdfPath): \(error)")
                    }
                }

                let cvDocument = CVDocument(
                    name: serializableCV.name,
                    dateCreated: serializableCV.dateCreated,
                    pdfBookmark: bookmark
                )
                context.insert(cvDocument)
            }
        }

        try context.save()

        // Nettoyer le dossier temporaire
        try? fileManager.removeItem(at: tempDir)
    }

    static func clearAllData(context: ModelContext) throws {
        // Supprimer tous les profils (les expériences, éducations et références seront supprimées en cascade)
        let profiles = try context.fetch(FetchDescriptor<Profile>())
        for profile in profiles {
            context.delete(profile)
        }

        // Supprimer toutes les candidatures
        let applications = try context.fetch(FetchDescriptor<Application>())
        for application in applications {
            context.delete(application)
        }

        // Supprimer tous les CVs
        let cvDocuments = try context.fetch(FetchDescriptor<CVDocument>())
        for cvDocument in cvDocuments {
            context.delete(cvDocument)
        }

        try context.save()
    }
}
