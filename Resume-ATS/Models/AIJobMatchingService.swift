import Foundation
import SwiftData

// MARK: - AI Integration Service

class AIJobMatchingService {
    
    // Match a single job with profile using AI
    static func matchJobWithProfile(
        jobResult: JobResult,
        profile: Profile?,
        completion: @escaping (_ aiScore: Int?, _ matchReason: String?, _ missingRequirements: [String]) -> Void
    ) {
// Create model-specific prompts
            // Create unified prompt for both models (using the precise Gemini configuration)
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
            Experience: \(profile?.experiences.map { "\($0.position ?? "") at \($0.company) (\($0.startDate.formatted(date: .abbreviated, time: .omitted)) - \($0.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "Present")" }.joined(separator: "; ") ?? "No experience listed")
            Education: \(profile?.educations.map { "\($0.degree) from \($0.institution)" }.joined(separator: "; ") ?? "No education listed")
            Languages: \(profile?.languages.map { "\($0.name) (\($0.level ?? "Unknown"))" }.joined(separator: ", ") ?? "No languages listed")
            
            CANDIDATE SPECIALIZATIONS:
            \(profile?.skills.map { "- \($0.title): \($0.skillsArray.joined(separator: ", "))" }.joined(separator: "\n") ?? "No skills listed")
            
            EXPERIENCE SUMMARY:
            - Total Years of Experience: \(AIJobMatchingService.calculateTotalExperienceYears(profile: profile)) years
            - Key Roles: \(profile?.experiences.compactMap { $0.position }.prefix(3).joined(separator: ", ") ?? "None")
            
            TASK:
            1. Score the match from 0-100 (100 = perfect match)
            2. **IMPORTANT**: If job title or description appears to be in Dutch/Flemish (not French or English), reduce the score by at least 50 points
            3. **EXPERIENCE LEVEL**: Consider that the candidate is suitable for Junior to 2+ years experience positions. Don't penalize for "2+ years" or "Junior/Intermediate" requirements.
            4. **SKILLS MATCHING**: Give extra points for:
               - DevOps/Cloud roles (AWS, Azure, Kubernetes, Docker, CI/CD)
               - QA/Automation roles (Test Automation, QA Automation, Automation tools)
            5. Explain why this is a good match (2-3 sentences max)
            6. List missing key requirements (max 5 items, be specific)
            7. If job is in Dutch/Flemish, add "Language barrier: Job requires Dutch/Flemish" to missing requirements
            
            LANGUAGE INSTRUCTION:
            The user's application is in \(Locale.current.identifier.hasPrefix("fr") ? "FRENCH" : "ENGLISH").
            You MUST provide the "reason" and "missing" fields in \(Locale.current.identifier.hasPrefix("fr") ? "FRENCH" : "ENGLISH").
            
            RESPONSE FORMAT:
            You MUST return ONLY valid JSON. Do not include any other text, explanations, or markdown formatting.
            {
                "score": 85,
                "reason": "\(Locale.current.identifier.hasPrefix("fr") ? "Correspondance forte grâce à l'expérience DevOps" : "Strong match due to DevOps experience")",
                "missing": ["\(Locale.current.identifier.hasPrefix("fr") ? "3+ ans d'expérience" : "3+ years experience")"]
            }
            """
        
        let selectedModel = AIService.getSelectedAIModel()
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("🤖 [AI] Starting \(selectedModel.displayName) CLI for job: \(jobResult.title)")
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: selectedModel.executablePath)
            process.arguments = selectedModel.arguments
            
            // Add prompt to arguments for Gemini only
            if selectedModel == .gemini {
                process.arguments = (process.arguments ?? []) + [prompt]
            }
            
            // For Qwen, write prompt to stdin
            if selectedModel == .qwen {
                let stdinPipe = Pipe()
                process.standardInput = stdinPipe
                if let data = prompt.data(using: String.Encoding.utf8) {
                    // Write asynchronously to avoid blocking if the pipe buffer fills up
                    // although for a single prompt it's usually fine, but good practice
                    try? stdinPipe.fileHandleForWriting.write(contentsOf: data)
                    try? stdinPipe.fileHandleForWriting.close()
                }
            }
            
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            
            // Handle stderr
            let errorPipe: Pipe?
            if selectedModel == .qwen {
                // Suppress stderr for Qwen to avoid pollution
                process.standardError = FileHandle.nullDevice
                errorPipe = nil
            } else {
                let pipe = Pipe()
                process.standardError = pipe
                errorPipe = pipe
            }
            
            do {
                print("🤖 [AI] \(selectedModel.displayName) starting process with args: \(process.arguments ?? [])")
                try process.run()
                print("🤖 [AI] \(selectedModel.displayName) process started, waiting for exit...")
                
                // Add timeout mechanism
                let timeoutTask = DispatchWorkItem {
                    if process.isRunning {
                        print("⚠️ [AI] \(selectedModel.displayName) process timed out, terminating...")
                        process.terminate()
                    }
                }
                // Reduce timeout to 25s to avoid hitting global timeout
                DispatchQueue.global().asyncAfter(deadline: .now() + 25.0, execute: timeoutTask)
                
                process.waitUntilExit()
                timeoutTask.cancel() // Cancel timeout if process finishes in time
                print("🤖 [AI] \(selectedModel.displayName) process finished")
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let errorOutput: String?
                if let pipe = errorPipe {
                    let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                    errorOutput = String(data: errorData, encoding: .utf8)
                } else {
                    errorOutput = nil
                }
                
                print("🤖 [AI] \(selectedModel.displayName) exit code: \(process.terminationStatus)")
                if let output = output {
                    print("🤖 [AI] \(selectedModel.displayName) output: \(output.prefix(200))...")
                }
                if let errorOutput = errorOutput, !errorOutput.isEmpty {
                    // Filter out benign warnings to keep logs clean
                    let filteredError = errorOutput.components(separatedBy: .newlines)
                        .filter { !$0.contains("[WARN]") && !$0.isEmpty }
                        .joined(separator: "\n")
                    
                    if !filteredError.isEmpty {
                        print("⚠️ [AI] \(selectedModel.displayName) stderr: \(filteredError)")
                    }
                }
                
                DispatchQueue.main.async {
                    if process.terminationStatus == 0, let output = output, !output.isEmpty {
                        // Robust JSON extraction: find first '{' and last '}'
                        if let startRange = output.range(of: "{"), let endRange = output.range(of: "}", options: .backwards) {
                            // Ensure valid range order
                            if startRange.lowerBound < endRange.upperBound {
                                let jsonRange = startRange.lowerBound..<endRange.upperBound
                                let jsonString = String(output[jsonRange])
                                
                                // Parse JSON response
                                if let data = jsonString.data(using: .utf8) {
                                    do {
                                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                            let score = json["score"] as? Int
                                            let reason = json["reason"] as? String
                                            let missing = json["missing"] as? [String] ?? []
                                            print("✅ [AI] Successfully parsed: score=\(score ?? -1), reason=\(reason ?? "none")")
                                            completion(score, reason, missing)
                                            return
                                        }
                                    } catch {
                                        print("❌ [AI] Failed to parse AI response JSON: \(error)")
                                        print("   Raw output was: \(output)")
                                    }
                                }
                            } else {
                                print("❌ [AI] Invalid JSON structure (braces in wrong order)")
                            }
                        } else {
                            print("❌ [AI] No JSON object found in output")
                            print("   Raw output was: \(output)")
                        }
                    }
                    
                    // If we're here, something failed
                    completion(nil, nil, [])
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ [AI] Error running \(selectedModel.displayName) CLI: \(error)")
                    completion(nil, nil, [])
                }
            }
        }
    }
    
    // Process multiple jobs in batch
    static func processBatchJobs(
        jobResults: [JobResult],
        profile: Profile?,
        completion: @escaping ([Job]) -> Void
    ) {
        let processedJobs = ThreadSafeArray<Job>()
        let dispatchGroup = DispatchGroup()
        
        // Limit concurrent AI calls to avoid overwhelming the system
        // Limit concurrent AI calls to avoid overwhelming the system
        // Reduced to 1 to prevent resource contention and timeouts on standard hardware
        let maxConcurrent = 1
        let semaphore = DispatchSemaphore(value: maxConcurrent)
        
        // Move the loop to a background thread to avoid blocking the main thread with semaphore.wait()
        DispatchQueue.global(qos: .userInitiated).async {
            for jobResult in jobResults {
                dispatchGroup.enter()
                semaphore.wait()
                
                self.matchJobWithProfile(jobResult: jobResult, profile: profile) { aiScore, matchReason, missingRequirements in
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
                    semaphore.signal()
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                var finalJobs = processedJobs.all
                // Sort by AI score (highest first, jobs without scores at the end)
                finalJobs.sort { job1, job2 in
                    switch (job1.aiScore, job2.aiScore) {
                    case (let score1?, let score2?):
                        return score1 > score2
                    case (nil, _):
                        return false
                    case (_, nil):
                        return true
                    }
                }
                
                completion(finalJobs)
            }
        }
    }

    
    // Helper to calculate total years of experience
    static func calculateTotalExperienceYears(profile: Profile?) -> Int {
        guard let profile = profile else { return 0 }
        
        var totalMonths = 0
        
        for experience in profile.experiences {
            let start = experience.startDate
            let end = experience.endDate ?? Date()
            
            let components = Calendar.current.dateComponents([.month], from: start, to: end)
            if let months = components.month {
                totalMonths += max(0, months)
            }
        }
        
        return max(0, totalMonths / 12)
    }
}

// Helper for thread safety
class ThreadSafeArray<T> {
    private var array: [T] = []
    private let queue = DispatchQueue(label: "com.resumeats.threadSafeArray", attributes: .concurrent)
    
    func append(_ element: T) {
        queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }
    
    var all: [T] {
        queue.sync {
            return array
        }
    }
}