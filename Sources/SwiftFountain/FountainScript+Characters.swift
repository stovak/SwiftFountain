//
//  FountainScript+Characters.swift
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

    /// Extract character information from the script
    /// - Returns: A dictionary mapping character names to their information
    public func extractCharacters() -> CharacterList {
        var characters: CharacterList = [:]
        var currentSceneIndex: Int = -1
        var lastCharacterName: String?

        for element in elements {
            // Track scene changes
            if element.elementType == "Scene Heading" {
                currentSceneIndex += 1
            }

            // Process character dialogue
            if element.elementType == "Character" {
                let characterName = cleanCharacterName(element.elementText)
                lastCharacterName = characterName

                // Initialize character if needed
                if characters[characterName] == nil {
                    characters[characterName] = CharacterInfo()
                }

                // Add scene if not already tracked
                if currentSceneIndex >= 0 && !characters[characterName]!.scenes.contains(currentSceneIndex) {
                    characters[characterName]!.scenes.append(currentSceneIndex)
                }

                // Increment line count for each character appearance
                characters[characterName]!.counts.lineCount += 1
            }

            // Process dialogue content (accumulate word counts)
            // Count words in Dialogue and Parenthetical
            if element.elementType == "Dialogue" || element.elementType == "Parenthetical" {
                if let characterName = lastCharacterName {
                    characters[characterName]!.counts.wordCount += countWords(in: element.elementText)
                }
            }
        }

        return characters
    }

    /// Write character list to a JSON file
    /// - Parameter path: File path to write the JSON to
    /// - Throws: File writing errors
    public func writeCharactersJSON(toFile path: String) throws {
        let characters = extractCharacters()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(characters)
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// Write character list to a JSON file URL
    /// - Parameter url: File URL to write the JSON to
    /// - Throws: File writing errors
    public func writeCharactersJSON(to url: URL) throws {
        let characters = extractCharacters()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(characters)
        try data.write(to: url)
    }

    // MARK: - Private Helpers

    /// Clean character name by removing extensions and parentheticals
    private func cleanCharacterName(_ name: String) -> String {
        var cleaned = name.trimmingCharacters(in: .whitespaces)

        // Remove character extensions like (V.O.), (O.S.), (CONT'D)
        if let openParen = cleaned.firstIndex(of: "(") {
            cleaned = String(cleaned[..<openParen]).trimmingCharacters(in: .whitespaces)
        }

        // Remove dual dialogue marker
        cleaned = cleaned.replacingOccurrences(of: "^", with: "").trimmingCharacters(in: .whitespaces)

        return cleaned.uppercased()
    }

    /// Find the most recent character that spoke before the given element
    private func findMostRecentCharacter(before element: FountainElement) -> String? {
        guard let currentIndex = elements.firstIndex(where: { $0 === element }) else {
            return nil
        }

        // Search backwards for the most recent Character element
        for i in stride(from: currentIndex - 1, through: 0, by: -1) {
            if elements[i].elementType == "Character" {
                return cleanCharacterName(elements[i].elementText)
            }
        }

        return nil
    }

    /// Count words in a string
    private func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
}
