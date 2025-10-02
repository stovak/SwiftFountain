//
//  FountainScript+Highland.swift
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
import ZIPFoundation

extension FountainScript {

    /// Initialize FountainScript from a Highland file (.highland)
    /// Highland files are ZIP archives containing a TextBundle
    /// - Parameters:
    ///   - highlandURL: URL to the .highland file
    ///   - parser: The parser type to use (default: .fast)
    /// - Throws: Highland import errors
    public convenience init(highlandURL: URL, parser: ParserType = .fast) throws {
        self.init()
        try loadHighland(highlandURL, parser: parser)
    }

    /// Load a FountainScript from a Highland file
    /// - Parameters:
    ///   - highlandURL: URL to the .highland file
    ///   - parser: The parser type to use (default: .fast)
    /// - Throws: Highland import errors
    public func loadHighland(_ highlandURL: URL, parser: ParserType = .fast) throws {
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

        // Highland files may have text.md or text.markdown instead of .fountain
        // Try to find a .fountain file first, then fall back to text.md/text.markdown
        let textBundleContents = try fileManager.contentsOfDirectory(
            at: textBundleURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )

        var sourceURL: URL?

        // First, try to find a .fountain file
        for fileURL in textBundleContents {
            if fileURL.pathExtension.lowercased() == "fountain" {
                sourceURL = fileURL
                break
            }
        }

        // If no .fountain file, try text.md or text.markdown
        if sourceURL == nil {
            for fileURL in textBundleContents {
                let filename = fileURL.lastPathComponent
                if filename == "text.md" || filename == "text.markdown" {
                    sourceURL = fileURL
                    break
                }
            }
        }

        guard let url = sourceURL else {
            throw FountainTextBundleError.noFountainFileFound
        }

        try loadFile(url.path, parser: parser)
        filename = url.lastPathComponent
    }

    /// Write the current FountainScript to a Highland file (.highland)
    /// Highland files are ZIP archives containing a TextBundle with resources
    /// - Parameters:
    ///   - destinationURL: The directory where the Highland file should be created
    ///   - name: The base name for the Highland file (without extension)
    ///   - includeResources: Whether to include characters.json and outline.json in resources
    /// - Returns: The URL of the created Highland file
    /// - Throws: Writing errors
    @discardableResult
    public func writeToHighland(
        destinationURL: URL,
        name: String,
        includeResources: Bool = true
    ) throws -> URL {
        let fileManager = FileManager.default

        // Create a temporary directory for the textbundle
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        // Create the textbundle with resources
        let textBundleURL = try createTextBundleWithResources(
            destinationURL: tempDir,
            name: name,
            includeResources: includeResources
        )

        // Create the highland (zip) file
        let highlandFileName = "\(name).highland"
        let highlandURL = destinationURL.appendingPathComponent(highlandFileName)

        // Remove existing file if present
        try? fileManager.removeItem(at: highlandURL)

        // Zip the textbundle into a .highland file
        try fileManager.zipItem(at: textBundleURL, to: highlandURL)

        return highlandURL
    }
}

// MARK: - Error Types

public enum HighlandError: Error {
    case noTextBundleFound
    case extractionFailed
}
