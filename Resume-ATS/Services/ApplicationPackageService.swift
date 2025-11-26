import Foundation
import AppKit
import SwiftData

/// Service for creating application package folders with all necessary documents
class ApplicationPackageService {
    
    enum PackageError: Error {
        case folderCreationFailed
        case fileWriteFailed
        case cvExportFailed
    }
    
    static func createApplicationPackage(
        for jobTitle: String,
        company: String,
        location: String,
        url: String,
        profile: Profile,
        coverLetter: String,
        completion: @escaping (Result<URL, PackageError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Detect language
                let language = LanguageDetector.detectLanguage(
                    title: jobTitle,
                    company: company,
                    location: location
                )
                
                // Create folder structure
                let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
                let applicationsFolder = desktopURL.appendingPathComponent("Applications", isDirectory: true)
                
                // Create Applications folder if it doesn't exist
                try? FileManager.default.createDirectory(at: applicationsFolder, withIntermediateDirectories: true)
                
                // Sanitize folder name
                let sanitizedCompany = company.replacingOccurrences(of: "/", with: "-")
                let sanitizedTitle = jobTitle.replacingOccurrences(of: "/", with: "-")
                let folderName = "\(sanitizedCompany)_\(sanitizedTitle)"
                let packageFolder = applicationsFolder.appendingPathComponent(folderName, isDirectory: true)
                
                // Create package folder
                try FileManager.default.createDirectory(at: packageFolder, withIntermediateDirectories: true)
                print("📁 [Package] Created folder: \(packageFolder.path)")
                
                // 1. Write cover letter as PDF
                let coverLetterFileName = language.coverLetterFileName.replacingOccurrences(of: ".txt", with: ".pdf")
                let coverLetterFile = packageFolder.appendingPathComponent(coverLetterFileName)
                
                let coverLetterTitle: String
                switch language {
                case .french: coverLetterTitle = "Lettre de Motivation"
                case .dutch: coverLetterTitle = "Motivatiebrief"
                case .english: coverLetterTitle = "Cover Letter"
                }
                
                let pdfSuccess = PDFGeneratorService.generatePDF(
                    from: coverLetter,
                    title: coverLetterTitle,
                    outputURL: coverLetterFile
                )
                
                if pdfSuccess {
                    print("✅ [Package] Cover letter PDF created")
                } else {
                    print("⚠️ [Package] Failed to create cover letter PDF, falling back to text")
                    let textFile = packageFolder.appendingPathComponent(language.coverLetterFileName)
                    try coverLetter.write(to: textFile, atomically: true, encoding: .utf8)
                }
                
                // 2. Write job link
                let linkFile = packageFolder.appendingPathComponent("link.txt")
                let linkContent = """
                    Job Title: \(jobTitle)
                    Company: \(company)
                    Location: \(location)
                    URL: \(url)
                    """
                try linkContent.write(to: linkFile, atomically: true, encoding: .utf8)
                print("✅ [Package] Link file created")
                
                // 3. Generate CV PDF using the existing PDFService
                let cvFileName = language.cvFileName
                let cvFile = packageFolder.appendingPathComponent(cvFileName)
                
                // Use the existing PDFService to generate the CV
                PDFService.generateATSResumePDFWithPagination(for: profile) { tempCVURL in
                    if let tempCVURL = tempCVURL {
                        do {
                            // Copy the generated CV to the package folder
                            try FileManager.default.copyItem(at: tempCVURL, to: cvFile)
                            print("✅ [Package] CV PDF created using PDFService")
                            
                            // Clean up temp file
                            try? FileManager.default.removeItem(at: tempCVURL)
                            
                            // Open folder in Finder
                            DispatchQueue.main.async {
                                NSWorkspace.shared.open(packageFolder)
                                completion(.success(packageFolder))
                            }
                        } catch {
                            print("❌ [Package] Error copying CV: \(error)")
                            DispatchQueue.main.async {
                                completion(.failure(.cvExportFailed))
                            }
                        }
                    } else {
                        print("❌ [Package] Failed to generate CV PDF")
                        DispatchQueue.main.async {
                            completion(.failure(.cvExportFailed))
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("❌ [Package] Error: \(error)")
                    completion(.failure(.folderCreationFailed))
                }
            }
        }
    }
}
