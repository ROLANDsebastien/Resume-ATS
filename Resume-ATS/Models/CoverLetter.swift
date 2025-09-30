//
//  CoverLetter.swift
//  Resume-ATS
//
//  Created by ROLAND Sébastien on 27/09/2025.
//

import AppKit
import Foundation
import SwiftData

@Model
final class CoverLetter {
    var title: String
    var content: Data
    var creationDate: Date

    init(
        title: String, content: Data = Data(), creationDate: Date = Date()
    ) {
        self.title = title
        self.content = content
        self.creationDate = creationDate
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
