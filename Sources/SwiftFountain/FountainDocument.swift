//
//  FountainDocument.swift
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

import SwiftUI
import UniformTypeIdentifiers

/// UTType extensions for Fountain document types
@available(macOS 11.0, iOS 14.0, *)
public extension UTType {
    static var fountain: UTType {
        UTType(importedAs: "com.quote-unquote.fountain")
    }

    static var highland: UTType {
        UTType(importedAs: "com.highland.highland")
    }

    static var textBundle: UTType {
        UTType(importedAs: "org.textbundle.package")
    }
}

/// Document wrapper for SwiftUI document-based apps
@available(macOS 11.0, iOS 14.0, *)
public final class FountainDocument: ReferenceFileDocument {
    public static var readableContentTypes: [UTType] {
        [.fountain, .highland, .textBundle]
    }

    public static var writableContentTypes: [UTType] {
        [.fountain, .highland, .textBundle]
    }

    public var script: FountainScript

    public init() {
        self.script = FountainScript()
    }

    public init(configuration: ReadConfiguration) throws {
        guard let fileURL = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(configuration.contentType.preferredFilenameExtension ?? "fountain")

        try fileURL.write(to: tempURL)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let script = FountainScript()

        // Determine file type and load accordingly
        if configuration.contentType == .highland {
            try script.loadHighland(tempURL)
        } else if configuration.contentType == .textBundle {
            try script.loadTextBundle(tempURL)
        } else {
            // Default to .fountain
            try script.loadFile(tempURL.path)
        }

        self.script = script
    }

    public func snapshot(contentType: UTType) throws -> Data {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        if contentType == .highland {
            let highlandURL = try script.writeToHighland(
                destinationURL: tempURL,
                name: script.filename ?? "script"
            )
            return try Data(contentsOf: highlandURL)
        } else if contentType == .textBundle {
            let textBundleURL = try script.writeToTextBundleWithResources(
                destinationURL: tempURL,
                name: script.filename ?? "script"
            )
            return try Data(contentsOf: textBundleURL)
        } else {
            // Default to .fountain
            let fountainContent = script.stringFromDocument()
            return Data(fountainContent.utf8)
        }
    }

    public func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        try snapshot.write(to: tempURL)

        if configuration.contentType == .highland || configuration.contentType == .textBundle {
            // These are directories, so we need to return a directory file wrapper
            return try FileWrapper(url: tempURL, options: .immediate)
        } else {
            // .fountain is a simple file
            return FileWrapper(regularFileWithContents: snapshot)
        }
    }
}
