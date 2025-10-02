//
//  FountainParser.swift
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

public class FountainParser {

    // MARK: - Body parsing

    public static func parseBody(ofFile path: String) throws -> [FountainElement] {
        let fileContents = try String(contentsOfFile: path, encoding: .utf8)
        return try parseBody(ofString: fileContents)
    }

    public static func parseBody(ofString string: String) throws -> [FountainElement] {
        var scriptContent = body(ofString: string)

        // Three-pass parsing method.
        // 1st we check for block comments, and manipulate them for regexes
        // 2nd we run regexes against the file to convert it into a marked up format
        // 3rd we split the marked up elements, and loop through them adding each to
        //   an our array of FountainElements.
        //
        // The intermediate marked up format makes subsequent parsing very simple,
        // even if it means less efficiency overall.

        // 1st pass - Block comments
        // The regexes aren't smart enough (yet) to deal with newlines in the
        // comments, so we need to convert them before processing.
        let blockCommentMatches = matches(in: scriptContent, pattern: FountainRegexes.blockCommentPattern, captureGroup: 1)
        for blockComment in blockCommentMatches {
            let modifiedBlock = blockComment.replacingOccurrences(of: "\n", with: FountainRegexes.newlineReplacement)
            scriptContent = scriptContent.replacingOccurrences(of: blockComment, with: modifiedBlock)
        }

        let bracketCommentMatches = matches(in: scriptContent, pattern: FountainRegexes.bracketCommentPattern, captureGroup: 1)
        for bracketComment in bracketCommentMatches {
            let modifiedBlock = bracketComment.replacingOccurrences(of: "\n", with: FountainRegexes.newlineReplacement)
            scriptContent = scriptContent.replacingOccurrences(of: bracketComment, with: modifiedBlock)
        }

        // Sanitize < and > chars for conversion to the markup
        scriptContent = scriptContent.replacingOccurrences(of: "<", with: "&lt;")
        scriptContent = scriptContent.replacingOccurrences(of: ">", with: "&gt;")
        scriptContent = scriptContent.replacingOccurrences(of: "...", with: "::trip::")

        // 2nd pass - Regexes
        // Blast the script with regexes.
        // Make sure pattern and template regexes match up!
        let patterns = [
            FountainRegexes.universalLineBreaksPattern,
            FountainRegexes.blockCommentPattern,
            FountainRegexes.bracketCommentPattern,
            FountainRegexes.synopsisPattern,
            FountainRegexes.pageBreakPattern,
            FountainRegexes.falseTransitionPattern,
            FountainRegexes.forcedTransitionPattern,
            FountainRegexes.sceneHeaderPattern,
            FountainRegexes.firstLineActionPattern,
            FountainRegexes.transitionPattern,
            FountainRegexes.characterCuePattern,
            FountainRegexes.parentheticalPattern,
            FountainRegexes.dialoguePattern,
            FountainRegexes.sectionHeaderPattern,
            FountainRegexes.actionPattern,
            FountainRegexes.cleanupPattern,
            FountainRegexes.newlineReplacement
        ]

        let templates = [
            FountainRegexes.universalLineBreaksTemplate,
            FountainRegexes.blockCommentTemplate,
            FountainRegexes.bracketCommentTemplate,
            FountainRegexes.synopsisTemplate,
            FountainRegexes.pageBreakTemplate,
            FountainRegexes.falseTransitionTemplate,
            FountainRegexes.forcedTransitionTemplate,
            FountainRegexes.sceneHeaderTemplate,
            FountainRegexes.firstLineActionTemplate,
            FountainRegexes.transitionTemplate,
            FountainRegexes.characterCueTemplate,
            FountainRegexes.parentheticalTemplate,
            FountainRegexes.dialogueTemplate,
            FountainRegexes.sectionHeaderTemplate,
            FountainRegexes.actionTemplate,
            FountainRegexes.cleanupTemplate,
            FountainRegexes.newlineRestore
        ]

        // Validate the array counts
        guard patterns.count == templates.count else {
            throw FountainParserError.mismatchedPatternTemplates
        }

        // Run the regular expressions
        for i in 0..<patterns.count {
            scriptContent = replace(in: scriptContent, pattern: patterns[i], with: templates[i])
        }

        // 3rd pass - Array construction
        let tagMatching = "<([a-zA-Z\\s]+)>([^<>]*)<\\/[a-zA-Z\\s]+>"
        let elementText = matches(in: scriptContent, pattern: tagMatching, captureGroup: 2)
        let elementType = matches(in: scriptContent, pattern: tagMatching, captureGroup: 1)

        // Validate the Text and Type counts match
        guard elementText.count == elementType.count else {
            throw FountainParserError.mismatchedTextType
        }

        var elementsArray: [FountainElement] = []

        for i in 0..<elementText.count {
            let element = FountainElement()

            // Convert < and > back to normal
            var cleanedText = elementText[i]
            cleanedText = cleanedText.replacingOccurrences(of: "&lt;", with: "<")
            cleanedText = cleanedText.replacingOccurrences(of: "&gt;", with: ">")
            cleanedText = cleanedText.replacingOccurrences(of: "::trip::", with: "...")

            // Deal with scene numbers if we are in a scene heading
            if elementType[i] == "Scene Heading" {
                if let sceneNumber = firstMatch(in: cleanedText, pattern: FountainRegexes.sceneNumberPattern, captureGroup: 2),
                   let fullSceneNumberText = firstMatch(in: cleanedText, pattern: FountainRegexes.sceneNumberPattern, captureGroup: 1) {
                    element.sceneNumber = sceneNumber
                    cleanedText = cleanedText.replacingOccurrences(of: fullSceneNumberText, with: "")
                }
            }

            element.elementType = elementType[i]
            element.elementText = cleanedText.trimmingCharacters(in: .newlines)

            // More refined processing of elements based on text/type
            if matches(string: element.elementText, pattern: FountainRegexes.centeredTextPattern) {
                element.isCentered = true
                if let centeredText = firstMatch(in: element.elementText, pattern: "(>?)\\s*([^<>\\n]*)\\s*(<?)", captureGroup: 2) {
                    element.elementText = centeredText.trimmingCharacters(in: .whitespaces)
                }
            }

            if element.elementType == "Scene Heading" {
                // Check for a forced scene heading. Remove preceding dot.
                if let cleanedSceneText = firstMatch(in: element.elementText, pattern: "^\\.?(.+)", captureGroup: 1) {
                    element.elementText = cleanedSceneText
                }
            }

            if element.elementType == "Section Heading" {
                // Clean the section text, and get the section depth
                if let depthChars = firstMatch(in: element.elementText, pattern: FountainRegexes.sectionHeaderPattern, captureGroup: 2) {
                    element.sectionDepth = UInt(depthChars.count)
                }
                if let sectionText = firstMatch(in: element.elementText, pattern: FountainRegexes.sectionHeaderPattern, captureGroup: 3) {
                    element.elementText = sectionText
                }
            }

            if i > 1 && element.elementType == "Character" && matches(string: element.elementText, pattern: FountainRegexes.dualDialoguePattern) {
                element.isDualDialogue = true

                // Clean the ^ mark
                element.elementText = replace(in: element.elementText, pattern: "\\s*\\^$", with: "")

                // Find the previous character cue
                var j = i - 1
                let dialogueBlockTypes: Set<String> = ["Dialogue", "Parenthetical"]

                while j >= 0 {
                    let previousElement = elementsArray[j]
                    if previousElement.elementType == "Character" {
                        previousElement.isDualDialogue = true
                        previousElement.elementText = previousElement.elementText.replacingOccurrences(of: "^", with: "")
                        break
                    }
                    if !dialogueBlockTypes.contains(previousElement.elementType) {
                        break
                    }
                    j -= 1
                }
            }

            elementsArray.append(element)
        }

        return elementsArray
    }

    // MARK: - Title page parsing

    public static func parseTitlePage(ofFile path: String) throws -> [[String: [String]]] {
        let fileContents = try String(contentsOfFile: path, encoding: .utf8)
        return try parseTitlePage(ofString: fileContents)
    }

    public static func parseTitlePage(ofString string: String) throws -> [[String: [String]]] {
        let rawTitlePage = titlePage(ofString: string)
        var contents: [[String: [String]]] = []

        // Line by line parsing
        // split the title page using newlines, then walk through the array and determine what is what
        // this allows us to look for very specific things and better handle non-uniform title pages

        let splitTitlePage = rawTitlePage.components(separatedBy: "\n")

        var openDirective: String?
        var directiveData: [String] = []

        for line in splitTitlePage {
            // Is this an inline directive or a multi-line one?
            if matches(string: line, pattern: FountainRegexes.inlineDirectivePattern) {
                // If there's an openDirective with data, save it
                if let directive = openDirective, !directiveData.isEmpty {
                    contents.append([directive: directiveData])
                    directiveData = []
                }
                openDirective = nil

                if var key = firstMatch(in: line, pattern: FountainRegexes.inlineDirectivePattern, captureGroup: 1)?.lowercased(),
                   let val = firstMatch(in: line, pattern: FountainRegexes.inlineDirectivePattern, captureGroup: 2) {

                    // Validation
                    if key == "author" || key == "author(s)" {
                        key = "authors"
                    }

                    contents.append([key: [val]])
                }
            } else if matches(string: line, pattern: FountainRegexes.multiLineDirectivePattern) {
                // If there's an openDirective with data, save it
                if let directive = openDirective, !directiveData.isEmpty {
                    contents.append([directive: directiveData])
                }

                if var directive = firstMatch(in: line, pattern: FountainRegexes.multiLineDirectivePattern, captureGroup: 1)?.lowercased() {
                    // Validation
                    if directive == "author" || directive == "author(s)" {
                        directive = "authors"
                    }
                    openDirective = directive
                    directiveData = []
                }
            } else {
                if let data = firstMatch(in: line, pattern: FountainRegexes.multiLineDataPattern, captureGroup: 2) {
                    directiveData.append(data)
                }
            }
        }

        if let directive = openDirective, !directiveData.isEmpty {
            contents.append([directive: directiveData])
        }

        return contents
    }

    // MARK: - Private Helpers

    private static func body(ofString string: String) -> String {
        var body = string
        body = replace(in: body, pattern: "^\\n+", with: "")

        // Find title page by looking for the first blank line, then checking the
        // text above it. If a title page is found we remove it, leaving only the
        // body content.
        if let firstBlankLine = body.range(of: "\n\n") {
            let beforeBlankRange = body.startIndex..<body.index(after: firstBlankLine.lowerBound)
            let documentTop = String(body[beforeBlankRange]) + "\n"

            // Check if this is a title page
            if matches(string: documentTop, pattern: FountainRegexes.titlePagePattern) {
                body.removeSubrange(beforeBlankRange)
            }
        }

        return "\n\n\(body)\n\n"
    }

    private static func titlePage(ofString string: String) -> String {
        var body = string
        body = replace(in: body, pattern: "^\\n+", with: "")

        // Find title page by looking for the first blank line, then checking the
        // text above it. If a title page is found we return it.
        if let firstBlankLine = body.range(of: "\n\n") {
            let beforeBlankRange = body.startIndex..<body.index(after: firstBlankLine.lowerBound)
            var documentTop = String(body[beforeBlankRange]) + "\n"

            // Check if this is a title page
            if matches(string: documentTop, pattern: FountainRegexes.titlePagePattern) {
                documentTop = replace(in: documentTop, pattern: "^\\n+", with: "")
                documentTop = replace(in: documentTop, pattern: "\\n+$", with: "")
                return documentTop
            }
        }

        // If there's no title page to be found
        return ""
    }

    // MARK: - Regex Helpers

    private static func matches(in text: String, pattern: String, captureGroup: Int) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsText = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        return results.compactMap { match -> String? in
            guard match.numberOfRanges > captureGroup else { return nil }
            let range = match.range(at: captureGroup)
            guard range.location != NSNotFound else { return nil }
            return nsText.substring(with: range)
        }
    }

    private static func firstMatch(in text: String, pattern: String, captureGroup: Int) -> String? {
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

    private static func matches(string: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }

        let nsString = string as NSString
        return regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: nsString.length)) != nil
    }

    private static func replace(in text: String, pattern: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }

        let nsText = text as NSString
        return regex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: nsText.length), withTemplate: template)
    }
}

// MARK: - Error Types

public enum FountainParserError: Error {
    case mismatchedPatternTemplates
    case mismatchedTextType
}
