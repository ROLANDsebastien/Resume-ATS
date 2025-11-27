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
            
            let selectedModel = AIService.getSelectedAIModel()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: selectedModel.executablePath)
            process.arguments = selectedModel.arguments
            
            // For Qwen, write prompt to stdin
            if selectedModel == .qwen {
                let stdinPipe = Pipe()
                process.standardInput = stdinPipe
                if let data = prompt.data(using: .utf8) {
                    stdinPipe.fileHandleForWriting.write(data)
                    stdinPipe.fileHandleForWriting.closeFile()
                }
            } else {
                // For Gemini, add prompt to arguments
                process.arguments = (process.arguments ?? []) + [prompt]
            }
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            
            // Suppress stderr for Qwen to avoid "Command command not found" messages
            if selectedModel == .qwen {
                let nullDev = Pipe()
                process.standardError = nullDev
            } else {
                process.standardError = errorPipe
            }
            
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
        let selectedModel = AIService.getSelectedAIModel()
        
        let languageInstruction: String
        switch language {
        case .french:
            languageInstruction = selectedModel == .gemini ? 
                "Écris une lettre de motivation professionnelle EN FRANÇAIS" :
                "You are a French cover letter writer. Write in FRENCH."
        case .dutch:
            languageInstruction = selectedModel == .gemini ? 
                "Schrijf een professionele motivatiebrief IN HET NEDERLANDS" :
                "You are a Dutch cover letter writer. Write in DUTCH."
        case .english:
            languageInstruction = selectedModel == .gemini ? 
                "Write a professional cover letter IN ENGLISH" :
                "You are an English cover letter writer. Write in ENGLISH."
        }
        
        if selectedModel == .gemini {
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
            3. Show enthusiasm for role
            4. Keep it concise (250-300 words)
            5. Include proper greeting and closing
            6. NO placeholder text like [Your Name] - use actual profile data
            7. Plain text only, no markdown formatting
            
            Write ONLY cover letter text, no explanations or metadata.
            """
        } else {
            // Qwen prompt - more direct
            return """
            You are a professional cover letter writer for Resume-ATS. \(languageInstruction)

            JOB DETAILS:
            Title: \(job.title)
            Company: \(job.company)
            Location: \(job.location)
            \(job.salary != nil ? "Salary: \(job.salary!)" : "")

            CANDIDATE INFO:
            Name: \(profile.firstName ?? "") \(profile.lastName ?? "")
            Email: \(profile.email ?? "")
            Phone: \(profile.phone ?? "")
            Summary: \(profile.summaryString)
            Skills: \(profile.skills.flatMap { $0.skillsArray }.joined(separator: ", "))
            Experience: \(profile.experiences.map { "\($0.position ?? "") at \($0.company) (\($0.startDate.formatted(.dateTime.year()))-\($0.endDate?.formatted(.dateTime.year()) ?? "Present"))" }.joined(separator: "; "))

            INSTRUCTIONS:
            1. Professional tone and structure
            2. Highlight relevant skills and experience  
            3. Show enthusiasm for role
            4. Keep it concise (250-300 words)
            5. Include proper greeting and closing
            6. Use actual profile data, no placeholders
            7. Plain text only, no markdown formatting

            WRITE ONLY THE COVER LETTER TEXT.
            """
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
