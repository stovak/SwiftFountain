//
//  OutlineElement.swift
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

/// An element in the screenplay outline/structure
public struct OutlineElement: Codable {
    public var id: String
    public var index: Int
    public var isCollapsed: Bool
    public var level: Int
    public var range: [Int]
    public var rawString: String
    public var string: String
    public var type: String

    public init(id: String = UUID().uuidString, index: Int, isCollapsed: Bool = false, level: Int, range: [Int], rawString: String, string: String, type: String) {
        self.id = id
        self.index = index
        self.isCollapsed = isCollapsed
        self.level = level
        self.range = range
        self.rawString = rawString
        self.string = string
        self.type = type
    }
}

/// Collection of all outline elements
public typealias OutlineList = [OutlineElement]
