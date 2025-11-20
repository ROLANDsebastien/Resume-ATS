
import SwiftUI
import AppKit

struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedString: NSAttributedString
    @Binding var selectedRange: NSRange

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        if #available(macOS 15.0, *) {
            textView.writingToolsBehavior = .default
        }
        textView.usesRuler = false
        textView.usesInspectorBar = false
        textView.delegate = context.coordinator
        textView.textColor = NSColor.labelColor
        textView.font = NSFont.systemFont(ofSize: 20.0)
        textView.typingAttributes = [
            .foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 20.0),
        ]
        textView.drawsBackground = false
        textView.backgroundColor = NSColor.clear

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = NSColor.clear

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.attributedString() != attributedString {
                let mutable = NSMutableAttributedString(attributedString: attributedString)
                mutable.addAttribute(
                    .foregroundColor, value: NSColor.labelColor,
                    range: NSRange(location: 0, length: mutable.length))
                textView.textStorage?.setAttributedString(mutable)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                let newString = textView.attributedString()
                let mutable = NSMutableAttributedString(attributedString: newString)
                mutable.addAttribute(
                    .foregroundColor, value: NSColor.labelColor,
                    range: NSRange(location: 0, length: mutable.length))
                DispatchQueue.main.async {
                    self.parent.attributedString = mutable
                }
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                let newRange = textView.selectedRange()
                DispatchQueue.main.async {
                    self.parent.selectedRange = newRange
                }
            }
        }
    }
}

struct RichTextToolbar: View {
    @Binding var attributedString: NSAttributedString
    @Binding var selectedRange: NSRange

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { toggleBold() }) {
                Image(systemName: "bold")
            }
            .buttonStyle(.bordered)

            Button(action: { toggleItalic() }) {
                Image(systemName: "italic")
            }
            .buttonStyle(.bordered)

            Button(action: { toggleUnderline() }) {
                Image(systemName: "underline")
            }
            .buttonStyle(.bordered)

            if #available(macOS 15.0, *) {
                Button(action: {
                    NSApp.sendAction(
                        #selector(NSResponder.showWritingTools(_:)), to: nil, from: nil)
                }) {
                    Image(systemName: "wand.and.stars")
                }
                .buttonStyle(.bordered)
            }

            Button(action: { insertBullet() }) {
                Image(systemName: "list.bullet")
            }
            .buttonStyle(.bordered)

            Button(action: { insertLineBreak() }) {
                Image(systemName: "arrow.right.to.line")
            }
            .buttonStyle(.bordered)
        }
        .padding(4)
        .background(.thinMaterial)
        .cornerRadius(6)
    }

    private func toggleBold() {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fontManager = NSFontManager.shared
        let validRange = NSRange(
            location: min(selectedRange.location, attributedString.length),
            length: min(
                selectedRange.length,
                attributedString.length - min(selectedRange.location, attributedString.length)))
        let range = validRange.length > 0 ? validRange : NSRange(location: 0, length: mutableString.length)

        // Ensure the range has a font attribute
        mutableString.addAttribute(.font, value: NSFont.systemFont(ofSize: NSFont.systemFontSize), range: range)

        // Then convert the fonts in the range
        mutableString.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            if let font = value as? NSFont {
                let trait = NSFontTraitMask.boldFontMask
                let hasTrait = fontManager.traits(of: font).contains(trait)
                let newFont = hasTrait ? fontManager.convert(font, toNotHaveTrait: trait) : fontManager.convert(font, toHaveTrait: trait)
                mutableString.addAttribute(.font, value: newFont, range: subrange)
            }
        }
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func toggleItalic() {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fontManager = NSFontManager.shared
        let validRange = NSRange(
            location: min(selectedRange.location, attributedString.length),
            length: min(
                selectedRange.length,
                attributedString.length - min(selectedRange.location, attributedString.length)))
        let range = validRange.length > 0 ? validRange : NSRange(location: 0, length: mutableString.length)

        // Ensure the range has a font attribute
        mutableString.addAttribute(.font, value: NSFont.systemFont(ofSize: NSFont.systemFontSize), range: range)

        // Then convert the fonts in the range
        mutableString.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            if let font = value as? NSFont {
                let trait = NSFontTraitMask.italicFontMask
                let hasTrait = fontManager.traits(of: font).contains(trait)
                let newFont = hasTrait ? fontManager.convert(font, toNotHaveTrait: trait) : fontManager.convert(font, toHaveTrait: trait)
                mutableString.addAttribute(.font, value: newFont, range: subrange)
            }
        }
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func toggleUnderline() {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let validRange = NSRange(
            location: min(selectedRange.location, attributedString.length),
            length: min(
                selectedRange.length,
                attributedString.length - min(selectedRange.location, attributedString.length)))
        let range = validRange.length > 0 ? validRange : NSRange(location: 0, length: mutableString.length)
        mutableString.enumerateAttribute(.underlineStyle, in: range, options: []) { value, range, _ in
            let currentStyle = (value as? NSNumber)?.intValue ?? 0
            let newStyle = currentStyle == 0 ? NSUnderlineStyle.single.rawValue : 0
            mutableString.addAttribute(.underlineStyle, value: newStyle, range: range)
        }
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func insertBullet() {
        let bullet = "• "
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let location = min(selectedRange.location, attributedString.length)
        mutableString.insert(NSAttributedString(string: bullet), at: location)
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }

    private func insertLineBreak() {
        let lineBreak = "\n"
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let location = min(selectedRange.location, attributedString.length)
        mutableString.insert(NSAttributedString(string: lineBreak), at: location)
        DispatchQueue.main.async {
            attributedString = mutableString
        }
    }
}

struct RichTextEditorWithToolbar: View {
    @Binding var attributedString: NSAttributedString

    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)

    var body: some View {
        VStack(spacing: 0) {
            RichTextToolbar(attributedString: $attributedString, selectedRange: $selectedRange)
            RichTextEditor(attributedString: $attributedString, selectedRange: $selectedRange)
                .frame(minHeight: 100)
                .background(.thinMaterial)
                .cornerRadius(8)
        }
    }
}
