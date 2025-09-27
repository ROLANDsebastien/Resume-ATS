//
//  RoundedImageView.swift
//  Resume-ATS
//
//  Created by Assistant on 2023-10-01.
//

import SwiftUI

struct RoundedImageView: NSViewRepresentable {
    let imageData: Data
    let size: CGSize
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSView {
        let view = RoundedImageNSView(frame: NSRect(origin: .zero, size: size))
        view.imageData = imageData
        view.cornerRadius = cornerRadius
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let roundedView = nsView as? RoundedImageNSView else { return }
        roundedView.imageData = imageData
        roundedView.cornerRadius = cornerRadius
        roundedView.needsDisplay = true
    }
}

class RoundedImageNSView: NSView {
    var imageData: Data?
    var cornerRadius: CGFloat = 8.0

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
            let imageData = imageData,
            let image = NSImage(data: imageData)
        else {
            return
        }

        // Save the current graphics state
        context.saveGState()

        // Create a rounded rectangle path for clipping
        let roundedPath = CGPath(
            roundedRect: dirtyRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius,
            transform: nil)

        // Add the path to the context and clip to it
        context.addPath(roundedPath)
        context.clip()

        // Draw the image within the clipped area
        image.draw(in: dirtyRect)

        // Restore the graphics state
        context.restoreGState()
    }
}
