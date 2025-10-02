//
//  FountainScript+Outline.swift
//  SwiftFountain
//
//  Copyright (c) 2025
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation

extension FountainScript {

    /// Extract outline elements from the script
    /// - Returns: An array of outline elements representing the script structure
    public func extractOutline() -> OutlineList {
        var outline: OutlineList = []
        var outlineIndex = 0
        var characterPosition = 0

        for element in elements {
            var shouldInclude = false
            var outlineType = ""
            var level = -1

            // Determine if this element should be in the outline
            switch element.elementType {
            case "Section Heading":
                shouldInclude = true
                outlineType = "sectionHeader"
                // Level is based on the section depth (# = 1, ## = 2, ### = 3, etc.)
                level = Int(element.sectionDepth)

            case "Scene Heading":
                shouldInclude = true
                outlineType = "sceneHeader"
                // Scene headings are typically level 4 in the hierarchy
                level = 4

            case "Comment":
                // Include notes (comments in brackets)
                if element.elementText.hasPrefix("NOTE:") || element.elementText.hasPrefix(" NOTE:") {
                    shouldInclude = true
                    outlineType = "note"
                    level = 5
                }

            default:
                break
            }

            if shouldInclude {
                let rawString = rawStringForElement(element)
                let cleanString = cleanStringForElement(element, type: outlineType)
                let length = rawString.count

                let outlineElement = OutlineElement(
                    index: outlineIndex,
                    level: level,
                    range: [characterPosition, length],
                    rawString: rawString,
                    string: cleanString,
                    type: outlineType
                )

                outline.append(outlineElement)
                outlineIndex += 1
            }

            // Track character position
            characterPosition += approximateElementLength(element)
        }

        // Add a final blank element if we have content
        if !outline.isEmpty {
            outline.append(OutlineElement(
                index: outlineIndex,
                level: -1,
                range: [characterPosition, 0],
                rawString: "",
                string: "",
                type: "blank"
            ))
        }

        return outline
    }

    /// Write outline to a JSON file
    /// - Parameter path: File path to write the JSON to
    /// - Throws: File writing errors
    public func writeOutlineJSON(toFile path: String) throws {
        let outline = extractOutline()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(outline)
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// Write outline to a JSON file URL
    /// - Parameter url: File URL to write the JSON to
    /// - Throws: File writing errors
    public func writeOutlineJSON(to url: URL) throws {
        let outline = extractOutline()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(outline)
        try data.write(to: url)
    }

    // MARK: - Private Helpers

    /// Get the raw string representation of an element (as it appears in source)
    private func rawStringForElement(_ element: FountainElement) -> String {
        switch element.elementType {
        case "Section Heading":
            // Reconstruct with # marks based on depth
            let hashes = String(repeating: "#", count: Int(element.sectionDepth))
            // Check if element text already starts with space, if not add one
            let text = element.elementText
            let separator = text.hasPrefix(" ") ? "" : " "
            return "\(hashes)\(separator)\(text)"

        case "Scene Heading":
            return element.elementText

        case "Comment":
            // Restore note format
            if element.elementText.hasPrefix("NOTE:") || element.elementText.hasPrefix(" NOTE:") {
                return "[[\(element.elementText)]]"
            }
            return element.elementText

        default:
            return element.elementText
        }
    }

    /// Clean the string for display (remove formatting markers)
    private func cleanStringForElement(_ element: FountainElement, type: String) -> String {
        var cleaned = element.elementText.trimmingCharacters(in: .whitespaces)

        if type == "note" {
            // Remove NOTE: prefix if present
            if cleaned.hasPrefix("NOTE:") {
                cleaned = String(cleaned.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if cleaned.hasPrefix(" NOTE:") {
                cleaned = String(cleaned.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            }
        }

        return cleaned
    }

    /// Approximate the character length of an element in the source text
    private func approximateElementLength(_ element: FountainElement) -> Int {
        // This is an approximation - the actual fountain source would need to be parsed
        // for exact positions, but this gives reasonable ranges
        let baseLength = element.elementText.count

        switch element.elementType {
        case "Section Heading":
            // Add # marks and spaces
            return Int(element.sectionDepth) + 1 + baseLength + 2 // hashes + space + text + newlines

        case "Scene Heading":
            return baseLength + 2 // text + newlines

        case "Character":
            return baseLength + 2

        case "Dialogue":
            return baseLength + 2

        case "Action":
            return baseLength + 2

        case "Comment":
            return baseLength + 6 // [[ ]] + newlines

        default:
            return baseLength + 2
        }
    }
}
