import Foundation

enum BuildStatus {
    case success
    case failure
}

struct BuildResult {
    let status: BuildStatus
    let output: String
}