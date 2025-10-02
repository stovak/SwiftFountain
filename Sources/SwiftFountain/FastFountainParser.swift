//
//  FastFountainParser.swift
//  SwiftFountain
//
//  Copyright (c) 2012-2013 Nima Yousefi & John August
//  Swift conversion (c) 2025
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

public class FastFountainParser {
    public var elements: [FountainElement] = []
    public var titlePage: [[String: [String]]] = []

    private static let inlinePattern = "^([^\\t\\s][^:]+):\\s*([^\\t\\s].*$)"
    private static let directivePattern = "^([^\\t\\s][^:]+):([\\t\\s]*$)"

    public init(file filePath: String) throws {
        let contents = try String(contentsOfFile: filePath, encoding: .utf8)
        parseContents(contents)
    }

    public init(string: String) {
        parseContents(string)
    }

    private func parseContents(_ contents: String) {
        // Trim leading newlines from the document
        var processedContents = contents.replacingOccurrences(of: "^\\s*", with: "", options: .regularExpression)
        processedContents = processedContents.replacingOccurrences(of: "\\r\\n|\\r|\\n", with: "\n", options: .regularExpression)
        processedContents = "\(processedContents)\n\n"

        // Find the first newline
        guard let firstBlankLineRange = processedContents.range(of: "\n\n") else { return }
        let topOfDocument = String(processedContents[..<firstBlankLineRange.lowerBound])

        // ----------------------------------------------------------------------
        // TITLE PAGE
        // ----------------------------------------------------------------------
        var foundTitlePage = false
        var openKey = ""
        var openValues: [String] = []
        let topLines = topOfDocument.components(separatedBy: "\n")

        for line in topLines {
            if line.isEmpty || matches(string: line, pattern: Self.directivePattern) {
                foundTitlePage = true
                // If a key was open we want to close it
                if !openKey.isEmpty {
                    titlePage.append([openKey: openValues])
                }

                if var key = firstMatch(in: line, pattern: Self.directivePattern, captureGroup: 1)?.lowercased() {
                    if key == "author" {
                        key = "authors"
                    }
                    openKey = key
                    openValues = []
                }
            } else if matches(string: line, pattern: Self.inlinePattern) {
                foundTitlePage = true
                // If a key was open we want to close it
                if !openKey.isEmpty {
                    titlePage.append([openKey: openValues])
                    openKey = ""
                    openValues = []
                }

                if var key = firstMatch(in: line, pattern: Self.inlinePattern, captureGroup: 1)?.lowercased(),
                   let value = firstMatch(in: line, pattern: Self.inlinePattern, captureGroup: 2) {
                    if key == "author" {
                        key = "authors"
                    }
                    titlePage.append([key: [value]])
                    openKey = ""
                    openValues = []
                }
            } else if foundTitlePage {
                openValues.append(line.trimmingCharacters(in: .whitespaces))
            }
        }

        if foundTitlePage {
            if openKey.isEmpty && openValues.isEmpty && titlePage.isEmpty {
                // do nothing
            } else {
                // Close any remaining directives
                if !openKey.isEmpty {
                    titlePage.append([openKey: openValues])
                    openKey = ""
                    openValues = []
                }
                processedContents = processedContents.replacingOccurrences(of: topOfDocument, with: "")
            }
        }

        // ----------------------------------------------------------------------
        // BODY
        // ----------------------------------------------------------------------
        processedContents = "\n\(processedContents)"
        let lines = processedContents.components(separatedBy: .newlines)

        var newlinesBefore = 0
        var index = -1
        var isCommentBlock = false
        var isInsideDialogueBlock = false
        var commentText = ""

        for line in lines {
            index += 1

            // Lyrics
            if !line.isEmpty && line.first == "~" {
                if let lastElement = elements.last, lastElement.elementType == "Lyrics" && newlinesBefore > 0 {
                    elements.append(FountainElement(type: "Lyrics", text: " "))
                }

                elements.append(FountainElement(type: "Lyrics", text: line))
                newlinesBefore = 0
                continue
            }

            // Forced action
            if !line.isEmpty && line.first == "!" {
                elements.append(FountainElement(type: "Action", text: line))
                newlinesBefore = 0
                continue
            }

            // Forced character
            if !line.isEmpty && line.first == "@" {
                elements.append(FountainElement(type: "Character", text: line))
                newlinesBefore = 0
                isInsideDialogueBlock = true
                continue
            }

            // Empty lines within dialogue -- denoted by two spaces inside a dialogue block
            if matches(string: line, pattern: "^\\s{2}$") && isInsideDialogueBlock {
                newlinesBefore = 0
                if let lastIndex = elements.indices.last {
                    let previousElement = elements[lastIndex]
                    if previousElement.elementType == "Dialogue" {
                        previousElement.elementText = "\(previousElement.elementText)\n\(line)"
                    } else {
                        elements.append(FountainElement(type: "Dialogue", text: line))
                    }
                } else {
                    elements.append(FountainElement(type: "Dialogue", text: line))
                }
                continue
            }

            // Multiple spaces (action)
            if matches(string: line, pattern: "^\\s{2,}$") {
                elements.append(FountainElement(type: "Action", text: line))
                newlinesBefore = 0
                continue
            }

            // Blank line
            if line.isEmpty && !isCommentBlock {
                isInsideDialogueBlock = false
                newlinesBefore += 1
                continue
            }

            // Open Boneyard
            if matches(string: line, pattern: "^\\/\\*") {
                if matches(string: line, pattern: "\\*\\/\\s*$") {
                    let text = line
                        .replacingOccurrences(of: "/*", with: "")
                        .replacingOccurrences(of: "*/", with: "")
                    isCommentBlock = false
                    elements.append(FountainElement(type: "Boneyard", text: text))
                    newlinesBefore = 0
                } else {
                    isCommentBlock = true
                    commentText.append("\n")
                }
                continue
            }

            // Close Boneyard
            if matches(string: line, pattern: "\\*\\/\\s*$") {
                let text = line.replacingOccurrences(of: "*/", with: "")
                if !text.isEmpty && !matches(string: text, pattern: "^\\s*$") {
                    commentText.append(text.trimmingCharacters(in: .whitespaces))
                }
                isCommentBlock = false
                elements.append(FountainElement(type: "Boneyard", text: commentText))
                commentText = ""
                newlinesBefore = 0
                continue
            }

            // Inside the Boneyard
            if isCommentBlock {
                commentText.append(line)
                commentText.append("\n")
                continue
            }

            // Page Breaks
            if matches(string: line, pattern: "^={3,}\\s*$") {
                elements.append(FountainElement(type: "Page Break", text: line))
                newlinesBefore = 0
                continue
            }

            // Synopsis
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if !trimmedLine.isEmpty && trimmedLine.first == "=" {
                if let markupRange = line.range(of: "^\\s*={1}", options: .regularExpression) {
                    let text = String(line[markupRange.upperBound...])
                    elements.append(FountainElement(type: "Synopsis", text: text))
                    continue
                }
            }

            // Comment
            if newlinesBefore > 0 && matches(string: line, pattern: "^\\s*\\[{2}\\s*([^\\]\\n])+\\s*\\]{2}\\s*$") {
                let text = line
                    .replacingOccurrences(of: "[[", with: "")
                    .replacingOccurrences(of: "]]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                elements.append(FountainElement(type: "Comment", text: text))
                continue
            }

            // Section heading
            if !trimmedLine.isEmpty && trimmedLine.first == "#" {
                newlinesBefore = 0

                if let markupRange = line.range(of: "^\\s*#+", options: .regularExpression) {
                    let depth = line.distance(from: markupRange.lowerBound, to: markupRange.upperBound)
                    let text = String(line[markupRange.upperBound...])

                    if !text.isEmpty {
                        let element = FountainElement(type: "Section Heading", text: text)
                        element.sectionDepth = UInt(depth)
                        elements.append(element)
                        continue
                    }
                }
            }

            // Forced scene heading
            if line.count > 1 && line.first == "." && line[line.index(line.startIndex, offsetBy: 1)] != "." {
                newlinesBefore = 0
                var sceneNumber: String?
                var text = ""

                if matches(string: line, pattern: "#([^\\n#]*?)#\\s*$") {
                    sceneNumber = firstMatch(in: line, pattern: "#([^\\n#]*?)#\\s*$", captureGroup: 1)
                    text = line.replacingOccurrences(of: "#([^\\n#]*?)#\\s*$", with: "", options: .regularExpression)
                    text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
                } else {
                    text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                }

                let element = FountainElement(type: "Scene Heading", text: text)
                element.sceneNumber = sceneNumber
                elements.append(element)
                continue
            }

            // Scene Headings
            if newlinesBefore > 0 && matches(string: line, pattern: "^(INT|EXT|EST|(I|INT)\\.?\\/(E|EXT)\\.?)[\\.\\-\\s][^\\n]+$", caseInsensitive: true) {
                newlinesBefore = 0
                var sceneNumber: String?
                var text = ""

                if matches(string: line, pattern: "#([^\\n#]*?)#\\s*$") {
                    sceneNumber = firstMatch(in: line, pattern: "#([^\\n#]*?)#\\s*$", captureGroup: 1)
                    text = line.replacingOccurrences(of: "#([^\\n#]*?)#\\s*$", with: "", options: .regularExpression)
                } else {
                    text = line
                }

                let element = FountainElement(type: "Scene Heading", text: text)
                element.sceneNumber = sceneNumber
                elements.append(element)
                continue
            }

            // Transitions
            if matches(string: line, pattern: "[^a-z]*TO:$") {
                newlinesBefore = 0
                elements.append(FountainElement(type: "Transition", text: line))
                continue
            }

            let lineWithTrimmedLeading = line.replacingOccurrences(of: "^\\s*", with: "", options: .regularExpression)
            let transitions: Set<String> = ["FADE OUT.", "CUT TO BLACK.", "FADE TO BLACK."]
            if transitions.contains(lineWithTrimmedLeading) {
                newlinesBefore = 0
                elements.append(FountainElement(type: "Transition", text: line))
                continue
            }

            // Forced transitions and centered text
            if !line.isEmpty && line.first == ">" {
                if line.count > 1 && line.last == "<" {
                    var text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                    text = String(text.dropLast()).trimmingCharacters(in: .whitespaces)

                    let element = FountainElement(type: "Action", text: text)
                    element.isCentered = true
                    elements.append(element)
                    newlinesBefore = 0
                    continue
                } else {
                    let text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                    elements.append(FountainElement(type: "Transition", text: text))
                    newlinesBefore = 0
                    continue
                }
            }

            // Character
            if newlinesBefore > 0 && matches(string: line, pattern: "^[^a-z]+(\\(cont'd\\))?$") {
                // Look ahead to see if the next line is blank
                let nextIndex = index + 1
                if nextIndex < lines.count {
                    let nextLine = lines[nextIndex]
                    if !nextLine.isEmpty {
                        newlinesBefore = 0
                        let element = FountainElement(type: "Character", text: line)

                        if matches(string: line, pattern: "\\^\\s*$") {
                            element.isDualDialogue = true
                            element.elementText = element.elementText.replacingOccurrences(of: "\\s*\\^\\s*$", with: "", options: .regularExpression)

                            var foundPreviousCharacter = false
                            var idx = elements.count - 1
                            while idx >= 0 && !foundPreviousCharacter {
                                let previousElement = elements[idx]
                                if previousElement.elementType == "Character" {
                                    previousElement.isDualDialogue = true
                                    foundPreviousCharacter = true
                                }
                                idx -= 1
                            }
                        }

                        elements.append(element)
                        isInsideDialogueBlock = true
                        continue
                    }
                }
            }

            // Dialogue and Parentheticals
            if isInsideDialogueBlock {
                if newlinesBefore == 0 && matches(string: line, pattern: "^\\s*\\(") {
                    elements.append(FountainElement(type: "Parenthetical", text: line))
                    continue
                } else {
                    if let lastIndex = elements.indices.last {
                        let previousElement = elements[lastIndex]
                        if previousElement.elementType == "Dialogue" {
                            previousElement.elementText = "\(previousElement.elementText)\n\(line)"
                        } else {
                            elements.append(FountainElement(type: "Dialogue", text: line))
                        }
                    } else {
                        elements.append(FountainElement(type: "Dialogue", text: line))
                    }
                    continue
                }
            }

            // Merge with previous action if no blank line
            if newlinesBefore == 0 && !elements.isEmpty {
                let lastIndex = elements.count - 1
                let previousElement = elements[lastIndex]

                // Scene Heading must be surrounded by blank lines
                if previousElement.elementType == "Scene Heading" {
                    previousElement.elementType = "Action"
                }

                previousElement.elementText = "\(previousElement.elementText)\n\(line)"
                newlinesBefore = 0
                continue
            } else {
                elements.append(FountainElement(type: "Action", text: line))
                newlinesBefore = 0
                continue
            }
        }
    }

    // MARK: - Regex Helpers

    private func matches(string: String, pattern: String, caseInsensitive: Bool = false) -> Bool {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }

        let nsString = string as NSString
        return regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: nsString.length)) != nil
    }

    private func firstMatch(in text: String, pattern: String, captureGroup: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) else {
            return nil
        }

        guard match.numberOfRanges > captureGroup else { return nil }
        let range = match.range(at: captureGroup)
        guard range.location != NSNotFound else { return nil }
        return nsText.substring(with: range)
    }
}
