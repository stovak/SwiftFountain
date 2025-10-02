//
//  FountainScript+TextBundle.swift
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
import TextBundle

extension FountainScript {


    /// Initialize FountainScript from a TextBundle file URL
    /// - Parameters:
    ///   - textBundleURL: URL to the .textbundle or .textpack file
    ///   - parser: The parser type to use (default: .fast)
    /// - Throws: FountainTextBundleError or TextBundle errors
    public convenience init(textBundleURL: URL, parser: ParserType = .fast) throws {
        self.init()
        try loadTextBundle(textBundleURL, parser: parser)
    }

    /// Load a FountainScript from a TextBundle URL
    /// - Parameters:
    ///   - textBundleURL: URL to the .textbundle or .textpack file
    ///   - parser: The parser type to use (default: .fast)
    /// - Throws: FountainTextBundleError if no .fountain file is found
    public func loadTextBundle(_ textBundleURL: URL, parser: ParserType = .fast) throws {
        // Look for a .fountain file in the TextBundle's root directory
        let fileManager = FileManager.default

        let contents = try fileManager.contentsOfDirectory(
            at: textBundleURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )

        var fountainURL: URL?

        for fileURL in contents {
            if fileURL.pathExtension.lowercased() == "fountain" {
                fountainURL = fileURL
                break
            }
        }

        guard let url = fountainURL else {
            throw FountainTextBundleError.noFountainFileFound
        }

        try loadFile(url.path, parser: parser)
        filename = url.lastPathComponent
    }

    /// Write the current FountainScript to a TextBundle
    /// - Parameters:
    ///   - destinationURL: The URL where the TextBundle should be created
    ///   - fountainFilename: Optional custom filename for the .fountain file (default: uses script's filename or "script.fountain")
    /// - Returns: The URL of the created TextBundle
    /// - Throws: Writing errors
    @discardableResult
    public func writeToTextBundle(destinationURL: URL, fountainFilename: String? = nil) throws -> URL {
        let fountainContent = FountainWriter.document(from: self)
        let name = fountainFilename ?? filename ?? "script.fountain"
        let bundleName = name.replacingOccurrences(of: ".fountain", with: "")

        // Create the TextBundle with the fountain content as text
        let textBundle = TextBundle(name: bundleName, contents: fountainContent, assetURLs: nil)

        var bundleURL: URL?
        try textBundle.bundle(destinationURL: destinationURL) { url in
            bundleURL = url
        }

        guard let finalURL = bundleURL else {
            throw FountainTextBundleError.failedToCreateBundle
        }

        // Rename text.markdown to .fountain file
        let fileManager = FileManager.default
        let textMarkdownURL = finalURL.appendingPathComponent("text.markdown")
        let fountainURL = finalURL.appendingPathComponent(name)

        if fileManager.fileExists(atPath: textMarkdownURL.path) {
            try fileManager.moveItem(at: textMarkdownURL, to: fountainURL)
        }

        return finalURL
    }
}

// MARK: - Error Types

public enum FountainTextBundleError: Error {
    case noFountainFileFound
    case cannotEnumerateBundle
    case failedToCreateBundle
}
