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
let prompt = """
            Analyze this job posting against the candidate's profile and provide a comprehensive match assessment.
            
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
            1. Score match from 0-100 (100 = perfect match)
            2. **IMPORTANT**: If job title or description appears to be in Dutch/Flemish (not French or English), reduce the score by at least 50 points
            3. **EXPERIENCE LEVEL**: Consider that candidate is suitable for Junior to 2+ years experience positions. Don't penalize for "2+ years" or "Junior/Intermediate" requirements.
            4. **SKILLS MATCHING**: Give extra points for:
               - DevOps/Cloud roles (AWS, Azure, Kubernetes, Docker, CI/CD)
               - QA/Automation roles (Test Automation, QA Automation, Automation tools)
               - IT Support roles (Helpdesk, Service Desk, Technical Support)
               - Entry-level to 2 years experience positions
            5. Explain why this is a good match (2-3 sentences max)
            6. List missing key requirements (max 5 items, be specific)
            7. If job is in Dutch/Flemish, add "Language barrier: Job requires Dutch/Flemish" to missing requirements
            
            RESPONSE FORMAT (JSON only):
            {
                "score": 85,
                "reason": "Strong match due to DevOps experience with AWS and cloud technologies",
                "missing": ["3+ years experience", "Advanced Kubernetes"]
            }
            """
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("🤖 [AI] Starting Gemini CLI for job: \(jobResult.title)")
            
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
                
                print("🤖 [AI] Gemini exit code: \(process.terminationStatus)")
                if let output = output {
                    print("🤖 [AI] Gemini output: \(output.prefix(200))...")
                }
                if let errorOutput = errorOutput, !errorOutput.isEmpty {
                    // Filter out benign warnings to keep logs clean
                    let filteredError = errorOutput.components(separatedBy: .newlines)
                        .filter { !$0.contains("[WARN]") && !$0.isEmpty }
                        .joined(separator: "\n")
                    
                    if !filteredError.isEmpty {
                        print("⚠️ [AI] Gemini stderr: \(filteredError)")
                    }
                }
                
                DispatchQueue.main.async {
                    if process.terminationStatus == 0, var output = output, !output.isEmpty {
                        // Sanitize output: remove markdown code blocks if present
                        if output.contains("```json") {
                            output = output.replacingOccurrences(of: "```json", with: "")
                        }
                        if output.contains("```") {
                            output = output.replacingOccurrences(of: "```", with: "")
                        }
                        output = output.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Parse JSON response
                        if let data = output.data(using: .utf8) {
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
                    }
                    
                    // If we're here, something failed
                    completion(nil, nil, [])
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ [AI] Error running Gemini CLI: \(error)")
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
        // Increased to 5 for M3 Mac performance - reduces analysis time significantly
        let maxConcurrent = 5
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