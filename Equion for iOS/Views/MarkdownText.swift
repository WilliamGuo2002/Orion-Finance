import SwiftUI

/// Renders a Markdown string with support for bold, italic, code, links,
/// plus basic handling of headers and bullet lists that SwiftUI Text doesn't natively support.
struct MarkdownText: View {
    let text: String

    var body: some View {
        let cleaned = preprocessMarkdown(text)
        if let attributed = try? AttributedString(markdown: cleaned, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
        } else {
            // Fallback: plain text
            Text(text)
        }
    }

    /// Convert block-level Markdown (headers, bullets) into something
    /// that AttributedString inline parsing can handle nicely.
    private func preprocessMarkdown(_ input: String) -> String {
        var lines = input.components(separatedBy: "\n")

        for i in lines.indices {
            var line = lines[i]

            // Convert headers to bold text
            if let match = line.range(of: #"^#{1,6}\s+"#, options: .regularExpression) {
                line = "**" + line[match.upperBound...].trimmingCharacters(in: .whitespaces) + "**"
            }

            // Convert bullet points: "- item" or "* item" → "• item"
            if let match = line.range(of: #"^\s*[-*]\s+"#, options: .regularExpression) {
                line = "• " + line[match.upperBound...]
            }

            // Convert numbered lists: "1. item" → "1. item" (already fine, just trim leading spaces)
            if let match = line.range(of: #"^\s*\d+\.\s+"#, options: .regularExpression) {
                let prefix = String(line[match])
                    .trimmingCharacters(in: .whitespaces)
                line = prefix + String(line[match.upperBound...])
            }

            lines[i] = line
        }

        return lines.joined(separator: "\n")
    }
}
