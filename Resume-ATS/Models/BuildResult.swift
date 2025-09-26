//
//  BuildResult.swift
//  Resume-ATS
//
//  Created by opencode on 2025-09-26.
//

import Foundation

enum BuildStatus {
    case success
    case failure
}

struct BuildResult {
    let status: BuildStatus
    let output: String
}