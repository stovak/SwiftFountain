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

public enum ParserType {
    case fast
    case regex
}

public class FountainScript {
    public var filename: String?
    public var elements: [FountainElement] = []
    public var titlePage: [[String: [String]]] = []
    public var suppressSceneNumbers: Bool = false

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
}

extension FountainScript: CustomStringConvertible {
    public var description: String {
        return FountainWriter.document(from: self)
    }
}
