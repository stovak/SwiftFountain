//
//  FountainScript.swift
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
import ZIPFoundation

public enum ParserType {
    case fast
    case regex
}

public class FountainScript {
    public var filename: String?
    public var elements: [FountainElement] = []
    public var titlePage: [[String: [String]]] = []
    public var suppressSceneNumbers: Bool = false
    private var cachedContent: String?

    public init() {}

    public convenience init(file path: String, parser: ParserType = .fast) throws {
        self.init()
        try loadFile(path, parser: parser)
    }

    public convenience init(string: String, parser: ParserType = .fast) throws {
        self.init()
        try loadString(string, parser: parser)
    }

    public func loadFile(_ path: String, parser: ParserType = .fast) throws {
        filename = URL(fileURLWithPath: path).lastPathComponent

        // Cache the file content for potential re-parsing
        cachedContent = try String(contentsOfFile: path, encoding: .utf8)

        switch parser {
        case .fast:
            let fountainParser = try FastFountainParser(file: path)
            elements = fountainParser.elements
            titlePage = fountainParser.titlePage
        case .regex:
            elements = try FountainParser.parseBody(ofFile: path)
            titlePage = try FountainParser.parseTitlePage(ofFile: path)
        }
    }

    public func loadString(_ string: String, parser: ParserType = .fast) throws {
        filename = nil

        // Cache the string content for potential re-parsing
        cachedContent = string

        switch parser {
        case .fast:
            let fountainParser = FastFountainParser(string: string)
            elements = fountainParser.elements
            titlePage = fountainParser.titlePage
        case .regex:
            elements = try FountainParser.parseBody(ofString: string)
            titlePage = try FountainParser.parseTitlePage(ofString: string)
        }
    }

    public func stringFromDocument() -> String {
        return FountainWriter.document(from: self)
    }

    public func stringFromTitlePage() -> String {
        return FountainWriter.titlePage(from: self)
    }

    public func stringFromBody() -> String {
        return FountainWriter.body(from: self)
    }

    public func write(toFile path: String) throws {
        let document = FountainWriter.document(from: self)
        try document.write(toFile: path, atomically: true, encoding: .utf8)
    }

    public func write(to url: URL) throws {
        let document = FountainWriter.document(from: self)
        try document.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Get screenplay elements, parsing the document if needed
    /// - Parameters:
    ///   - fileURL: URL to a .fountain, .highland, or .textbundle file (optional)
    ///   - parser: The parser type to use if parsing is needed (default: .fast)
    /// - Returns: Array of FountainElement objects
    /// - Throws: Errors if the document needs to be parsed but contains no content
    public func getScreenplayElements(from fileURL: URL? = nil, parser: ParserType = .fast) throws -> [FountainElement] {
        // If we already have elements, return them
        if !elements.isEmpty {
            return elements
        }

        // If a URL is provided, use getContent to retrieve the content
        if let url = fileURL {
            let content = try getContent(from: url)
            try loadString(content, parser: parser)
            return elements
        }

        // If no URL but we have cached content, re-parse it
        if let content = cachedContent, !content.isEmpty {
            try loadString(content, parser: parser)
            return elements
        }

        // Try to get content from the current state (title page + elements)
        let documentString = stringFromDocument()
        if !documentString.isEmpty {
            try loadString(documentString, parser: parser)
            return elements
        }

        // No elements and no content to parse
        throw FountainScriptError.noContentToParse
    }

    /// Get the content URL for a Fountain file
    /// - Parameter fileURL: URL to a .fountain, .highland, or .textbundle file
    /// - Returns: URL to the content file
    /// - Throws: Errors if the file type is unsupported or content cannot be found
    public func getContentUrl(from fileURL: URL) throws -> URL {
        let fileExtension = fileURL.pathExtension.lowercased()

        switch fileExtension {
        case "fountain":
            // For .fountain files, return the URL as-is
            return fileURL

        case "highland":
            // For .highland files, extract and find the content file
            return try getContentUrlFromHighland(fileURL)

        case "textbundle":
            // For .textbundle files, find the content file in the bundle
            return try getContentURL(from: fileURL)

        default:
            throw FountainScriptError.unsupportedFileType
        }
    }

    /// Get content from a Fountain file
    /// - Parameter fileURL: URL to a .fountain, .highland, or .textbundle file
    /// - Returns: Content string (for .fountain files, this excludes the front matter)
    /// - Throws: Errors if the file cannot be read
    public func getContent(from fileURL: URL) throws -> String {
        let fileExtension = fileURL.pathExtension.lowercased()

        switch fileExtension {
        case "fountain":
            // For .fountain files, return content without front matter
            let fullContent = try String(contentsOf: fileURL, encoding: .utf8)
            return bodyContent(ofString: fullContent)

        case "textbundle":
            // For .textbundle, get the content file URL and read it
            let contentURL = try getContentURL(from: fileURL)
            return try String(contentsOf: contentURL, encoding: .utf8)

        case "highland":
            // For .highland files, we need to extract and read before cleanup
            return try getContentFromHighland(fileURL)

        default:
            throw FountainScriptError.unsupportedFileType
        }
    }

    // MARK: - Private Helpers

    private func bodyContent(ofString string: String) -> String {
        var body = string
        body = body.replacingOccurrences(of: "^\\n+", with: "", options: .regularExpression)

        // Find title page by looking for the first blank line
        if let firstBlankLine = body.range(of: "\n\n") {
            let beforeBlankRange = body.startIndex..<body.index(after: firstBlankLine.lowerBound)
            let documentTop = String(body[beforeBlankRange]) + "\n"

            // Check if this is a title page using a simple pattern
            // Title pages have key:value pairs
            let titlePagePattern = "^[^\\t\\s][^:]+:\\s*"
            if let regex = try? NSRegularExpression(pattern: titlePagePattern, options: []) {
                let nsDocumentTop = documentTop as NSString
                if regex.firstMatch(in: documentTop, options: [], range: NSRange(location: 0, length: nsDocumentTop.length)) != nil {
                    body.removeSubrange(beforeBlankRange)
                }
            }
        }

        return body.trimmingCharacters(in: .newlines)
    }

    private func getContentUrlFromHighland(_ highlandURL: URL) throws -> URL {
        let fileManager = FileManager.default

        // Create a temporary directory to extract the highland file
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        // Extract the highland (zip) file
        try fileManager.unzipItem(at: highlandURL, to: tempDir)

        // Find the .textbundle directory inside
        let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        guard let textBundleURL = contents.first(where: { $0.pathExtension == "textbundle" }) else {
            throw HighlandError.noTextBundleFound
        }

        // Use the shared getContentURL logic to find .fountain or .md files
        return try getContentURL(from: textBundleURL)
    }

    private func getContentFromHighland(_ highlandURL: URL) throws -> String {
        let fileManager = FileManager.default

        // Create a temporary directory to extract the highland file
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        // Extract the highland (zip) file
        try fileManager.unzipItem(at: highlandURL, to: tempDir)

        // Find the .textbundle directory inside
        let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        guard let textBundleURL = contents.first(where: { $0.pathExtension == "textbundle" }) else {
            throw HighlandError.noTextBundleFound
        }

        // Use the shared getContentURL logic to find .fountain or .md files
        let contentURL = try getContentURL(from: textBundleURL)

        // Read the content before the temp directory is cleaned up
        return try String(contentsOf: contentURL, encoding: .utf8)
    }
}

extension FountainScript: CustomStringConvertible {
    public var description: String {
        return FountainWriter.document(from: self)
    }
}

// MARK: - Error Types

public enum FountainScriptError: Error {
    case unsupportedFileType
    case noContentToParse
}
