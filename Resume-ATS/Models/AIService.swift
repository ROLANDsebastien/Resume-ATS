//
//  AIService.swift
//  Resume-ATS
//
//  Created by opencode on //

import Foundation

class AIService {
    static func generateCoverLetter(jobDescription: String, profile: Profile?, completion: @escaping (String?) -> Void) {
        let prompt = """
        Generate a professional cover letter based on the following job description and the candidate's profile.

        Job Description:
        \(jobDescription)

        Candidate Profile:
        \(profile?.summaryString ?? "No summary available")
        Skills: \(profile?.skills.flatMap { $0.skills }.joined(separator: ", ") ?? "No skills listed")
        Experience: \(profile?.experiences.map { "\($0.position ?? "") at \($0.company)" }.joined(separator: "; ") ?? "No experience listed")

        Please write a compelling cover letter that highlights relevant skills and experiences.
        """

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/gemini")
            process.arguments = [prompt]

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
}