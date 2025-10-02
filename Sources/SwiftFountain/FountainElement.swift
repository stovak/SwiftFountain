//
//  FountainElement.swift
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

public class FountainElement {
    public var elementType: String
    public var elementText: String
    public var isCentered: Bool

    // Type specific properties
    public var sceneNumber: String?
    public var isDualDialogue: Bool
    public var sectionDepth: UInt

    public init(elementType: String = "", elementText: String = "") {
        self.elementType = elementType
        self.elementText = elementText
        self.isCentered = false
        self.sceneNumber = nil
        self.isDualDialogue = false
        self.sectionDepth = 0
    }

    public convenience init(type: String, text: String) {
        self.init(elementType: type, elementText: text)
    }
}

extension FountainElement: CustomStringConvertible {
    public var description: String {
        var typeOutput = elementType

        if isCentered {
            typeOutput += " (centered)"
        } else if isDualDialogue {
            typeOutput += " (dual dialogue)"
        } else if sectionDepth > 0 {
            typeOutput += " (\(sectionDepth))"
        }

        return "\(typeOutput): \(elementText)"
    }
}
