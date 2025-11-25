import Foundation
import SwiftData

class AIService {
    
    // MARK: - Existing Methods
    
    static func generateCoverLetter(
        jobDescription: String, profile: Profile?, additionalInstructions: String,
        completion: @escaping (String?) -> Void
    ) {
        let prompt = """
            Generate a professional cover letter based on the following job posting and the candidate's profile.

            Job Posting:
            \(jobDescription)

            Candidate Profile:
            Name: \(profile?.firstName ?? "") \(profile?.lastName ?? "")
            \(profile?.summaryString ?? "No summary available")
                        Skills: \(profile?.skills.flatMap { $0.skillsArray }.joined(separator: ", ") ?? "No skills listed")        Experience: \(profile?.experiences.map { "\($0.position ?? "") at \($0.company)" }.joined(separator: "; ") ?? "No experience listed")

            Additional Instructions:
            \(additionalInstructions.isEmpty ? "None" : additionalInstructions)

            Please write the cover letter body only, starting directly with the salutation (e.g., "Dear Hiring Manager,"). Do not include any header information like name, address, date, or placeholders. Use the candidate's actual name instead of placeholders. Do not use any markdown formatting like **bold** or *italic*. Write plain text only.
            """

        DispatchQueue.global(qos: .userInitiated).async {
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
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(
                    in: .whitespacesAndNewlines)
                let errorOutput = String(data: errorData, encoding: .utf8)

                DispatchQueue.main.async {
                    if process.terminationStatus == 0, let output = output, !output.isEmpty {
                        completion(output)
                    } else {
                        print("Gemini CLI error: \(errorOutput ?? "Unknown error")")
                        completion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error running Gemini CLI: \(error)")
                    completion(nil)
                }
            }
        }
    }

    static func extractCompanyAndPosition(
        from jobDescription: String,
        completion: @escaping (_ company: String, _ position: String) -> Void
    ) {
        let prompt = """
            Extract the company name and job position from the following job posting. Return ONLY two lines:
            Line 1: The company name
            Line 2: The job position/title

            If you cannot find this information clearly, make a reasonable inference based on context.

            Job Posting:
            \(jobDescription)

            Return format:
            Company: [company name]
            Position: [job position]
            """

        DispatchQueue.global(qos: .userInitiated).async {
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
                let output =
                    String(data: outputData, encoding: .utf8)?.trimmingCharacters(
                        in: .whitespacesAndNewlines) ?? ""

                var company = ""
                var position = ""

                let lines = output.split(separator: "\n").map(String.init)
                for line in lines {
                    if line.contains("Company:") {
                        company = line.replacingOccurrences(of: "Company:", with: "")
                            .trimmingCharacters(in: .whitespaces)
                    } else if line.contains("Position:") {
                        position = line.replacingOccurrences(of: "Position:", with: "")
                            .trimmingCharacters(in: .whitespaces)
                    }
                }

                DispatchQueue.main.async {
                    completion(company, position)
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error extracting company and position: \(error)")
                    completion("", "")
                }
            }
        }
    }
    
    // MARK: - Job Matching with AI
    
    static func matchJobWithProfile(
        jobResult: JobResult,
        profile: Profile?,
        completion: @escaping (_ aiScore: Int?, _ matchReason: String?, _ missingRequirements: [String]) -> Void
    ) {
        let prompt = """
            Analyze this job posting against the candidate's profile and provide a match assessment.
            
            JOB POSTING:
            Title: \(jobResult.title)
            Company: \(jobResult.company)
            Location: \(jobResult.location)
            \(jobResult.salary != nil ? "Salary: \(jobResult.salary!)" : "")
            Source: \(jobResult.source)
            
            CANDIDATE PROFILE:
            Name: \(profile?.firstName ?? "") \(profile?.lastName ?? "")
            Summary: \(profile?.summaryString ?? "No summary available")
            Skills: \(profile?.skills.flatMap { $0.skillsArray }.joined(separator: ", ") ?? "No skills listed")
            Experience: \(profile?.experiences.map { "\($0.position ?? "") at \($0.company)" }.joined(separator: "; ") ?? "No experience listed")
            
            TASK:
            1. Score the match from 0-100 (100 = perfect match)
            2. Explain why this is a good match (2-3 sentences max)
            3. List missing key requirements (max 5 items, be specific)
            
            RESPONSE FORMAT (JSON only):
            {
                "score": 85,
                "reason": "Strong match due to iOS experience and Swift skills",
                "missing": ["React Native experience", "5+ years experience"]
            }
            """
        
        DispatchQueue.global(qos: .userInitiated).async {
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
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let errorOutput = String(data: errorData, encoding: .utf8)
                
                DispatchQueue.main.async {
                    if process.terminationStatus == 0, let output = output, !output.isEmpty {
                        // Parse JSON response
                        if let data = output.data(using: .utf8) {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                    let score = json["score"] as? Int
                                    let reason = json["reason"] as? String
                                    let missing = json["missing"] as? [String] ?? []
                                    completion(score, reason, missing)
                                    return
                                }
                            } catch {
                                print("Failed to parse AI response JSON: \(error)")
                            }
                        }
                    }
                    
                    print("Gemini CLI error: \(errorOutput ?? "Unknown error")")
                    completion(nil, nil, [])
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error running Gemini CLI: \(error)")
                    completion(nil, nil, [])
                }
            }
        }
    }
    
    // MARK: - Batch Job Processing
    
    static func processBatchJobs(
        jobResults: [JobResult],
        profile: Profile?,
        completion: @escaping ([Job]) -> Void
    ) {
        var processedJobs: [Job] = []
        let dispatchGroup = DispatchGroup()
        
        for jobResult in jobResults {
            dispatchGroup.enter()
            
            matchJobWithProfile(jobResult: jobResult, profile: profile) { aiScore, matchReason, missingRequirements in
                let job = Job(
                    title: jobResult.title,
                    company: jobResult.company,
                    location: jobResult.location,
                    salary: jobResult.salary,
                    url: jobResult.url,
                    source: jobResult.source,
                    aiScore: aiScore,
                    matchReason: matchReason,
                    missingRequirements: missingRequirements
                )
                
                processedJobs.append(job)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Sort by AI score (highest first)
            processedJobs.sort { job1, job2 in
                guard let score1 = job1.aiScore, let score2 = job2.aiScore else {
                    return false
                }
                return score1 > score2
            }
            
            completion(processedJobs)
        }
    }
}