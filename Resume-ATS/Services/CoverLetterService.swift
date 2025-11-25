import Foundation

/// Service for generating personalized cover letters using AI
class CoverLetterService {
    
    static func generateCoverLetter(
        for job: Job,
        profile: Profile,
        language: LanguageDetector.Language,
        completion: @escaping (String?) -> Void
    ) {
        let prompt = createPrompt(job: job, profile: profile, language: language)
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("📝 [CoverLetter] Generating cover letter for: \(job.title)")
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/gemini")
            process.arguments = ["-m", "flash", prompt]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                DispatchQueue.main.async {
                    if process.terminationStatus == 0, let output = output, !output.isEmpty {
                        print("✅ [CoverLetter] Generated successfully")
                        completion(output)
                    } else {
                        print("❌ [CoverLetter] Generation failed")
                        completion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ [CoverLetter] Error: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    private static func createPrompt(job: Job, profile: Profile, language: LanguageDetector.Language) -> String {
        let languageInstruction: String
        switch language {
        case .french:
            languageInstruction = "Écris une lettre de motivation professionnelle EN FRANÇAIS"
        case .dutch:
            languageInstruction = "Schrijf een professionele motivatiebrief IN HET NEDERLANDS"
        case .english:
            languageInstruction = "Write a professional cover letter IN ENGLISH"
        }
        
        return """
            \(languageInstruction) pour le poste suivant.
            
            JOB POSTING:
            Title: \(job.title)
            Company: \(job.company)
            Location: \(job.location)
            \(job.salary != nil ? "Salary: \(job.salary!)" : "")
            
            CANDIDATE PROFILE:
            Name: \(profile.firstName ?? "") \(profile.lastName ?? "")
            Email: \(profile.email ?? "")
            Phone: \(profile.phone ?? "")
            Summary: \(profile.summaryString)
            Skills: \(profile.skills.flatMap { $0.skillsArray }.joined(separator: ", "))
            Experience: \(profile.experiences.map { "\($0.position ?? "") at \($0.company) (\($0.startDate.formatted(.dateTime.year()))-\($0.endDate?.formatted(.dateTime.year()) ?? "Present"))" }.joined(separator: "; "))
            
            REQUIREMENTS:
            1. Professional tone and structure
            2. Highlight relevant skills and experience
            3. Show enthusiasm for the role
            4. Keep it concise (250-300 words)
            5. Include proper greeting and closing
            6. NO placeholder text like [Your Name] - use actual profile data
            
            Write ONLY the cover letter text, no explanations or metadata.
            """
    }
}
