//
//  BuildService.swift
//  Resume-ATS
//
//  Created by opencode on 2025-09-26.
//

import Foundation

class BuildService {
    static func runBuild() -> BuildResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", ".specify/scripts/bash/auto-build.sh"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let status: BuildStatus = output.contains("Build succeeded") ? .success : .failure
            
            return BuildResult(status: status, output: output)
        } catch {
            return BuildResult(status: .failure, output: "Error running build: \(error.localizedDescription)")
        }
    }
}