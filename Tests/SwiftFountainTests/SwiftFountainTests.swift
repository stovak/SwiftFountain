import Testing
import Foundation
@testable import SwiftFountain

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

@Test func testLoadFromTextBundle() async throws {
    // Get the path to the test bundle directly
    let testBundleURL = URL(fileURLWithPath: "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.textbundle")

    let script = try FountainScript(textBundleURL: testBundleURL)

    #expect(!script.elements.isEmpty)
    #expect(script.filename == "test.fountain")
}

@Test func testWriteToTextBundle() async throws {
    let script = FountainScript()
    script.filename = "test-output.fountain"

    // Create a simple script with title page and some elements
    script.titlePage = [
        ["title": ["Test Script"]],
        ["authors": ["John Doe"]]
    ]

    let element = FountainElement()
    element.elementType = "Scene Heading"
    element.elementText = "INT. TEST ROOM - DAY"
    script.elements.append(element)

    let tempDir = FileManager.default.temporaryDirectory
    let outputURL = try script.writeToTextBundle(destinationURL: tempDir, fountainFilename: "test-output.fountain")

    #expect(FileManager.default.fileExists(atPath: outputURL.path))

    // Verify the .fountain file exists inside the bundle
    let fountainFileURL = outputURL.appendingPathComponent("test-output.fountain")
    #expect(FileManager.default.fileExists(atPath: fountainFileURL.path))

    // Clean up
    try? FileManager.default.removeItem(at: outputURL)
}

@Test func testExtractCharacters() async throws {
    let testFountainPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.fountain"
    let script = try FountainScript(file: testFountainPath)

    let characters = script.extractCharacters()

    // Verify some known characters exist
    #expect(characters["BERNARD"] != nil)
    #expect(characters["KILLIAN"] != nil)
    #expect(characters["SYLVIA"] != nil)

    // Verify BERNARD has reasonable data
    if let bernard = characters["BERNARD"] {
        #expect(bernard.counts.lineCount == 82, "BERNARD should have 82 dialogue lines")
        #expect(bernard.counts.wordCount > 500, "BERNARD should have substantial word count")
        #expect(bernard.scenes.count > 20, "BERNARD should appear in many scenes")
    }

    // Verify structure is correct for all characters
    for (name, info) in characters {
        #expect(!name.isEmpty, "Character name should not be empty")
        #expect(info.counts.lineCount > 0, "\(name) should have at least one line")
        #expect(info.counts.wordCount > 0, "\(name) should have words")
        #expect(info.gender.unspecified != nil, "\(name) should have gender field")
    }
}

@Test func testWriteCharactersJSON() async throws {
    let testFountainPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.fountain"
    let script = try FountainScript(file: testFountainPath)

    let tempDir = FileManager.default.temporaryDirectory
    let outputPath = tempDir.appendingPathComponent("test-characters.json")

    try script.writeCharactersJSON(to: outputPath)

    #expect(FileManager.default.fileExists(atPath: outputPath.path))

    // Verify the JSON can be read back
    let data = try Data(contentsOf: outputPath)
    let decoder = JSONDecoder()
    let characters = try decoder.decode(CharacterList.self, from: data)

    #expect(!characters.isEmpty, "Should have extracted characters")

    // Verify the structure is correct by checking the decoded characters
    #expect(characters.values.allSatisfy { $0.gender.unspecified != nil }, "All characters should have gender.unspecified")
    #expect(characters.values.allSatisfy { !$0.scenes.isEmpty }, "All characters should have scenes")

    // Also write to a permanent location for inspection
    let permanentPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/generated-characters.json"
    try script.writeCharactersJSON(toFile: permanentPath)

    // Clean up temp file
    try? FileManager.default.removeItem(at: outputPath)
}

@Test func testExtractOutline() async throws {
    let testFountainPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.fountain"
    let script = try FountainScript(file: testFountainPath)

    let outline = script.extractOutline()

    // Verify we have outline elements
    #expect(!outline.isEmpty, "Outline should not be empty")

    // Verify we have different types
    let types = Set(outline.map { $0.type })
    #expect(types.contains("sectionHeader"), "Should have section headers")
    #expect(types.contains("sceneHeader"), "Should have scene headers")

    // Verify structure
    let sectionHeaders = outline.filter { $0.type == "sectionHeader" }
    #expect(!sectionHeaders.isEmpty, "Should have section headers")

    // Verify first element is CHAPTER 1
    if let firstElement = outline.first {
        #expect(firstElement.type == "sectionHeader", "First element should be section header")
        #expect(firstElement.string.contains("CHAPTER"), "First element should be a chapter")
        #expect(firstElement.level == 2, "Chapter headers should be level 2")
    }

    // Verify indexes are sequential
    for (i, element) in outline.enumerated() {
        #expect(element.index == i, "Index should match position in array")
    }
}

@Test func testWriteOutlineJSON() async throws {
    let testFountainPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.fountain"
    let script = try FountainScript(file: testFountainPath)

    let tempDir = FileManager.default.temporaryDirectory
    let outputPath = tempDir.appendingPathComponent("test-outline.json")

    try script.writeOutlineJSON(to: outputPath)

    #expect(FileManager.default.fileExists(atPath: outputPath.path))

    // Verify the JSON can be read back
    let data = try Data(contentsOf: outputPath)
    let decoder = JSONDecoder()
    let outline = try decoder.decode(OutlineList.self, from: data)

    #expect(!outline.isEmpty, "Should have extracted outline elements")

    // Verify structure
    for element in outline {
        #expect(!element.id.isEmpty, "Each element should have an ID")
        #expect(element.range.count == 2, "Range should have 2 elements")
        #expect(!element.type.isEmpty, "Each element should have a type")
    }

    // Also write to a permanent location for inspection
    let permanentPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/generated-outline.json"
    try script.writeOutlineJSON(toFile: permanentPath)

    // Clean up temp file
    try? FileManager.default.removeItem(at: outputPath)
}
