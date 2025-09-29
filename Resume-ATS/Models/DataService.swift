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
        let experiences: [SerializableExperience]
        let educations: [SerializableEducation]
        let references: [SerializableReference]
        let skills: [String]
    }

    struct SerializableExperience: Codable {
        let company: String
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

    struct SerializableApplication: Codable {
        let company: String
        let position: String
        let dateApplied: Date
        let status: String
        let notes: String
        let source: String?
        let documentPaths: [String]?  // Chemins relatifs des documents dans l'archive
        let profileName: String  // Ajout pour lier à un profil
    }

    struct ExportData: Codable {
        let profiles: [SerializableProfile]
        let applications: [SerializableApplication]
        let exportDate: Date
        let version: String
    }

    static func exportProfiles(_ profiles: [Profile], applications: [Application]) -> URL? {
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
                experiences: profile.experiences.map { exp in
                    SerializableExperience(
                        company: exp.company,
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
                skills: profile.skills
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
                profileName: application.profile?.name ?? ""
            )
            serializableApplications.append(serializableApp)
        }

        let exportData = ExportData(
            profiles: serializableProfiles,
            applications: serializableApplications,
            exportDate: Date(),
            version: "1.1"
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

        // Récupérer les candidatures existantes pour éviter les doublons
        let existingApplications = try context.fetch(FetchDescriptor<Application>())
        let existingApplicationKeys = Set(
            existingApplications.map {
                "\($0.company)|\($0.position)|\($0.dateApplied.timeIntervalSince1970)"
            })

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
                showSkills: serializableProfile.showSkills
            )

            // Add experiences
            for exp in serializableProfile.experiences {
                let experience = Experience(
                    company: exp.company,
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

            profile.skills = serializableProfile.skills

            context.insert(profile)
        }

        // Créer une map pour un accès rapide aux profils par nom
        var profileMap: [String: Profile] = [:]
        for profile in context.insertedModelsArray.compactMap({ $0 as? Profile }) {
            profileMap[profile.name] = profile
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
                    if fileManager.fileExists(atPath: tempDocumentURL.path) {
                        // Copier vers le dossier permanent
                        let permanentURL = appDocumentsDir.appendingPathComponent(path)
                        do {
                            try fileManager.copyItem(at: tempDocumentURL, to: permanentURL)
                            let bookmark = try permanentURL.bookmarkData(
                                options: .withSecurityScope, includingResourceValuesForKeys: nil,
                                relativeTo: nil)
                            bookmarks?.append(bookmark)
                        } catch {
                            print(
                                "Erreur lors de la copie ou création du bookmark pour \(path): \(error)"
                            )
                        }
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

            context.insert(application)
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

        try context.save()
    }
}
