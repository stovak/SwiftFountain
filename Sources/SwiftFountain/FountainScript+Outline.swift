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
        var hasLevelOneHeader = false
        var parentStack: [OutlineElement] = [] // Stack to track parent elements
        
        // First pass: check if we have any level 1 headers and validate
        var levelOneCount = 0
        for element in elements {
            if element.elementType == "Section Heading" && element.sectionDepth == 1 {
                levelOneCount += 1
            }
        }
        
        // Ensure we have at most one level 1 header
        if levelOneCount > 1 {
            // Log warning or handle multiple level 1 headers (keep only the first one)
            print("Warning: Multiple level 1 headers found. Only the first one will be treated as level 1.")
        }
        
        // If no level 1 header exists, add the script title as level 1
        if levelOneCount == 0 {
            let scriptTitle = getScriptTitle()
            let titleElement = OutlineElement(
                index: outlineIndex,
                level: 1,
                range: [0, scriptTitle.count],
                rawString: "# \(scriptTitle)",
                string: scriptTitle,
                type: "sectionHeader",
                sceneDirective: nil,
                sceneDirectiveDescription: nil,
                parentId: nil,
                childIds: [],
                isEndMarker: false
            )
            outline.append(titleElement)
            parentStack.append(titleElement)
            outlineIndex += 1
        }

        var foundFirstLevelOne = false
        
        for element in elements {
            var shouldInclude = false
            var outlineType = ""
            var level = -1

            // Determine if this element should be in the outline
            switch element.elementType {
            case "Section Heading":
                shouldInclude = true
                outlineType = "sectionHeader"
                
                let sectionLevel = Int(element.sectionDepth)
                
                // Handle level 1 headers specially
                if sectionLevel == 1 {
                    if !foundFirstLevelOne {
                        level = 1
                        foundFirstLevelOne = true
                        hasLevelOneHeader = true
                    } else {
                        // Treat subsequent level 1 headers as level 2 (chapter level)
                        level = 2
                    }
                } else {
                    level = sectionLevel
                }

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
                var cleanString = cleanStringForElement(element, type: outlineType, level: level)
                let length = rawString.count
                
                var sceneDirective: String? = nil
                var sceneDirectiveDescription: String? = nil
                var isEndMarker = false
                
                // Check if this is an END marker for level 2 (chapter) elements
                if level == 2 && outlineType == "sectionHeader" {
                    let trimmedText = element.elementText.trimmingCharacters(in: .whitespaces).uppercased()
                    if trimmedText.hasPrefix("END") {
                        // Check if it's just "END" or "END" followed by words
                        let words = trimmedText.components(separatedBy: .whitespaces)
                        if words.first == "END" {
                            isEndMarker = true
                        }
                    }
                }
                
                // For level 3 section headers, extract scene directive information
                if level == 3 && outlineType == "sectionHeader" {
                    let fullText = element.elementText.trimmingCharacters(in: .whitespaces)
                    if let colonIndex = fullText.firstIndex(of: ":") {
                        let beforeColon = String(fullText[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                        let afterColon = String(fullText[fullText.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                        
                        // Get the first word before the colon as the directive name
                        if let firstWordEnd = beforeColon.firstIndex(of: " ") {
                            sceneDirective = String(beforeColon[..<firstWordEnd])
                        } else {
                            sceneDirective = beforeColon
                        }
                        
                        sceneDirectiveDescription = afterColon
                        cleanString = sceneDirective ?? cleanString
                    }
                }
                
                // Determine parent-child relationships
                var parentId: String? = nil
                
                // Update parent stack based on current level
                while !parentStack.isEmpty && parentStack.last!.level >= level {
                    parentStack.removeLast()
                }
                
                // Set parent if there's a suitable parent in the stack
                if !parentStack.isEmpty {
                    let parent = parentStack.last!
                    // Only set parent if it's one level up (proper hierarchical relationship)
                    if parent.level == level - 1 {
                        parentId = parent.id
                    }
                }

                let outlineElement = OutlineElement(
                    index: outlineIndex,
                    level: level,
                    range: [characterPosition, length],
                    rawString: rawString,
                    string: cleanString,
                    type: outlineType,
                    sceneDirective: sceneDirective,
                    sceneDirectiveDescription: sceneDirectiveDescription,
                    parentId: parentId,
                    childIds: [],
                    isEndMarker: isEndMarker
                )

                outline.append(outlineElement)
                
                // Add this element to parent's children if it has a parent
                if let parentId = parentId,
                   let parentIndex = outline.firstIndex(where: { $0.id == parentId }) {
                    outline[parentIndex].childIds.append(outlineElement.id)
                }
                
                // Add to parent stack if it's a structural element (not end marker)
                if !isEndMarker {
                    parentStack.append(outlineElement)
                }
                
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
                type: "blank",
                sceneDirective: nil,
                sceneDirectiveDescription: nil,
                parentId: nil,
                childIds: [],
                isEndMarker: false
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

    /// Extract outline and return as a tree structure
    /// - Returns: An OutlineTree representing the hierarchical structure
    public func extractOutlineTree() -> OutlineTree {
        let outline = extractOutline()
        return outline.tree()
    }

    // MARK: - Private Helpers
    
    /// Get the script title from filename or title page
    private func getScriptTitle() -> String {
        // First, try to get title from title page
        for titlePageSection in titlePage {
            if let title = titlePageSection["Title"] ?? titlePageSection["title"] {
                if let firstTitle = title.first, !firstTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    return firstTitle.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        // If no title page title, use filename without extension
        if let filename = filename {
            let url = URL(fileURLWithPath: filename)
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            return nameWithoutExtension
        }
        
        // Default fallback
        return "Untitled Script"
    }

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
    private func cleanStringForElement(_ element: FountainElement, type: String, level: Int = -1) -> String {
        var cleaned = element.elementText.trimmingCharacters(in: .whitespaces)

        if type == "note" {
            // Remove NOTE: prefix if present
            if cleaned.hasPrefix("NOTE:") {
                cleaned = String(cleaned.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if cleaned.hasPrefix(" NOTE:") {
                cleaned = String(cleaned.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            }
        } else if type == "sectionHeader" && level == 3 {
            // Level 3 headers are scene directive level - extract directive name
            if let colonIndex = cleaned.firstIndex(of: ":") {
                // Extract just the first word before the colon as the directive name
                let beforeColon = String(cleaned[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                if let firstWordEnd = beforeColon.firstIndex(of: " ") {
                    let firstWord = String(beforeColon[..<firstWordEnd])
                    cleaned = firstWord
                } else {
                    cleaned = beforeColon
                }
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
