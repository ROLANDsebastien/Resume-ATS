//
//  CoverLetter.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import AppKit
import Foundation
import SwiftData

extension NSAttributedString {
    static func fromMarkdown(_ markdown: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "")

        // Simple regex to find **bold** text
        let pattern = "\\*\\*(.*?)\\*\\*"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])

        var lastRange = markdown.startIndex..<markdown.startIndex

        regex?.enumerateMatches(in: markdown, options: [], range: NSRange(location: 0, length: markdown.count)) { match, _, _ in
            if let match = match {
                // Add text before the match
                let beforeRange = lastRange.lowerBound..<markdown.index(markdown.startIndex, offsetBy: match.range.location)
                if !beforeRange.isEmpty {
                    let beforeText = String(markdown[beforeRange])
                    attributedString.append(NSAttributedString(string: beforeText))
                }

                // Add the bold text
                let boldRange = markdown.index(markdown.startIndex, offsetBy: match.range.location + 2)..<markdown.index(markdown.startIndex, offsetBy: match.range.location + match.range.length - 2)
                let boldText = String(markdown[boldRange])
                let boldAttr = NSAttributedString(string: boldText, attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)])
                attributedString.append(boldAttr)

                lastRange = markdown.index(markdown.startIndex, offsetBy: match.range.location + match.range.length)..<markdown.endIndex
            }
        }

        // Add remaining text
        if lastRange.lowerBound < markdown.endIndex {
            let remainingText = String(markdown[lastRange])
            attributedString.append(NSAttributedString(string: remainingText))
        }

        return attributedString
    }
}

@Model
final class CoverLetter {
    var title: String
    var content: Data
    var creationDate: Date
    @Relationship(inverse: \Application.coverLetter)
    var applications: [Application]

    init(
        title: String, content: Data = Data(), creationDate: Date = Date()
    ) {
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.applications = []
    }

    var contentAttributedString: NSAttributedString {
        get {
            if content.isEmpty {
                return NSAttributedString(string: "")
            }
            return NSAttributedString(rtf: content, documentAttributes: nil)
                ?? NSAttributedString(string: "")
        }
        set {
            content = newValue.rtf(from: NSRange(location: 0, length: newValue.length)) ?? Data()
        }
    }

    var contentString: String {
        contentAttributedString.string
    }

    var normalizedContentAttributedString: NSAttributedString {
        let attr = contentAttributedString.mutableCopy() as! NSMutableAttributedString
        attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length), options: []) {
            value, range, _ in
            if let currentFont = value as? NSFont {
                let descriptor = currentFont.fontDescriptor
                let traits = descriptor.symbolicTraits
                let newDescriptor = NSFontDescriptor(name: "Arial", size: 11).withSymbolicTraits(
                    traits)
                if let newFont = NSFont(descriptor: newDescriptor, size: 11) {
                    attr.addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        return attr
    }
}
