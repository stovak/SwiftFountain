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

@Test func testWriteToTextBundleWithResources() async throws {
    let testFountainPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.fountain"
    let script = try FountainScript(file: testFountainPath)

    let tempDir = FileManager.default.temporaryDirectory
    let outputURL = try script.writeToTextBundleWithResources(
        destinationURL: tempDir,
        name: "test-output",
        includeResources: true
    )

    // Verify the TextBundle was created
    #expect(FileManager.default.fileExists(atPath: outputURL.path))

    // Verify the .fountain file exists
    let fountainURL = outputURL.appendingPathComponent("test-output.fountain")
    #expect(FileManager.default.fileExists(atPath: fountainURL.path))

    // Verify resources directory exists
    let resourcesDir = outputURL.appendingPathComponent("resources")
    #expect(FileManager.default.fileExists(atPath: resourcesDir.path))

    // Verify characters.json exists and is valid
    let charactersURL = resourcesDir.appendingPathComponent("characters.json")
    #expect(FileManager.default.fileExists(atPath: charactersURL.path))

    let charactersData = try Data(contentsOf: charactersURL)
    let characters = try JSONDecoder().decode(CharacterList.self, from: charactersData)
    #expect(!characters.isEmpty, "Characters JSON should have content")

    // Verify outline.json exists and is valid
    let outlineURL = resourcesDir.appendingPathComponent("outline.json")
    #expect(FileManager.default.fileExists(atPath: outlineURL.path))

    let outlineData = try Data(contentsOf: outlineURL)
    let outline = try JSONDecoder().decode(OutlineList.self, from: outlineData)
    #expect(!outline.isEmpty, "Outline JSON should have content")

    // Clean up
    try? FileManager.default.removeItem(at: outputURL)
}

@Test func testLoadFromHighland() async throws {
    let highlandURL = URL(fileURLWithPath: "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.highland")

    let script = try FountainScript(highlandURL: highlandURL)

    #expect(!script.elements.isEmpty, "Highland file should contain elements")
    // Highland files may use text.md instead of .fountain extension
    #expect(script.filename != nil, "Should extract filename")
}

@Test func testWriteToHighland() async throws {
    let testFountainPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.fountain"
    let script = try FountainScript(file: testFountainPath)

    let tempDir = FileManager.default.temporaryDirectory
    let highlandURL = try script.writeToHighland(
        destinationURL: tempDir,
        name: "test-output",
        includeResources: true
    )

    // Verify the Highland file was created
    #expect(FileManager.default.fileExists(atPath: highlandURL.path))
    #expect(highlandURL.pathExtension == "highland")

    // Verify we can load it back
    let loadedScript = try FountainScript(highlandURL: highlandURL)
    #expect(!loadedScript.elements.isEmpty, "Loaded script should have elements")

    // Clean up
    try? FileManager.default.removeItem(at: highlandURL)
}

@Test func testHighlandRoundTrip() async throws {
    let testFountainPath = "/Users/stovak/Projects/tablereader/swift/SwiftFountain/Tests/SwiftFountainTests/test.fountain"
    let originalScript = try FountainScript(file: testFountainPath)

    let tempDir = FileManager.default.temporaryDirectory

    // Write to Highland with resources
    let highlandURL = try originalScript.writeToHighland(
        destinationURL: tempDir,
        name: "roundtrip-test",
        includeResources: true
    )

    // Load it back
    let loadedScript = try FountainScript(highlandURL: highlandURL)

    // Verify the content is reasonable (element count may differ slightly due to formatting)
    #expect(loadedScript.elements.count > 0, "Loaded script should have elements")
    #expect(loadedScript.titlePage.count == originalScript.titlePage.count, "Title page should match")

    // Verify resources can be extracted
    let characters = loadedScript.extractCharacters()
    #expect(!characters.isEmpty, "Should be able to extract characters from loaded script")

    let outline = loadedScript.extractOutline()
    #expect(!outline.isEmpty, "Should be able to extract outline from loaded script")

    // Clean up
    try? FileManager.default.removeItem(at: highlandURL)
}
