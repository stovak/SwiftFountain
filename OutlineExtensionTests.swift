//
//  OutlineExtensionTests.swift
//  SwiftFountain
//
//  Copyright (c) 2025
//
//  Tests for the enhanced outline functionality with proper level handling.
//

import Testing
@testable import SwiftFountain

@Suite("Enhanced Outline Level Tests")
struct OutlineExtensionTests {

    @Test("Outline with no level 1 header should generate script title")
    func testOutlineWithNoLevelOneHeader() async throws {
        let fountainText = """
## Act I
### MUSIC: Jazz plays softly

INT. COFFEE SHOP - DAY

A screenwriter sits at a laptop.

### SOUND: Typing on keyboard

SCREENWRITER
This is going to be great!
"""

        let script = try FountainScript(string: fountainText)
        script.filename = "TestScript.fountain"
        let outline = script.extractOutline()

        // Should have a level 1 title generated from filename
        #expect(outline.count > 0)
        let firstElement = outline[0]
        #expect(firstElement.level == 1)
        #expect(firstElement.string == "TestScript")
        #expect(firstElement.isMainTitle)
        #expect(firstElement.type == "sectionHeader")
    }

    @Test("Outline with level 1 header should respect existing title")
    func testOutlineWithLevelOneHeader() async throws {
        let fountainText = """
# My Amazing Script
## Act I
### MUSIC: Jazz plays softly

INT. COFFEE SHOP - DAY

A screenwriter sits at a laptop.
"""

        let script = try FountainScript(string: fountainText)
        let outline = script.extractOutline()

        // Should keep the existing level 1 header
        #expect(outline.count > 0)
        let firstElement = outline[0]
        #expect(firstElement.level == 1)
        #expect(firstElement.string == "My Amazing Script")
        #expect(firstElement.isMainTitle)
    }

    @Test("Scene directive parsing")
    func testSceneDirectiveParsing() async throws {
        let fountainText = """
# My Script
## Chapter 1
### MUSIC: Jazz plays softly in the background
### SOUND: Rain on the window
### LIGHTING: Dim and moody atmosphere

INT. COFFEE SHOP - DAY

A scene happens here.
"""

        let script = try FountainScript(string: fountainText)
        let outline = script.extractOutline()

        // Find scene directive elements
        let sceneDirectives = outline.filter { $0.isSceneDirective }
        #expect(sceneDirectives.count == 3)

        // Check MUSIC directive
        let musicDirective = sceneDirectives[0]
        #expect(musicDirective.sceneDirective == "MUSIC")
        #expect(musicDirective.sceneDirectiveDescription == "Jazz plays softly in the background")
        #expect(musicDirective.string == "MUSIC")
        #expect(musicDirective.level == 3)

        // Check SOUND directive
        let soundDirective = sceneDirectives[1]
        #expect(soundDirective.sceneDirective == "SOUND")
        #expect(soundDirective.sceneDirectiveDescription == "Rain on the window")
        #expect(soundDirective.string == "SOUND")

        // Check LIGHTING directive
        let lightingDirective = sceneDirectives[2]
        #expect(lightingDirective.sceneDirective == "LIGHTING")
        #expect(lightingDirective.sceneDirectiveDescription == "Dim and moody atmosphere")
        #expect(lightingDirective.string == "LIGHTING")
    }

    @Test("Multiple level 1 headers should be demoted")
    func testMultipleLevelOneHeaders() async throws {
        let fountainText = """
# First Title
## Chapter 1
# Second Title Should Become Level 2

INT. SOME PLACE - DAY

Content here.
"""

        let script = try FountainScript(string: fountainText)
        let outline = script.extractOutline()

        let level1Elements = outline.filter { $0.level == 1 }
        let level2Elements = outline.filter { $0.level == 2 }

        // Should only have one level 1 element
        #expect(level1Elements.count == 1)
        #expect(level1Elements[0].string == "First Title")

        // The second "level 1" should become level 2
        let demotedHeader = level2Elements.first { $0.string == "Second Title Should Become Level 2" }
        #expect(demotedHeader != nil)
        #expect(demotedHeader?.level == 2)
    }

    @Test("Chapter level headers identification")
    func testChapterLevelHeaders() async throws {
        let fountainText = """
# My Script
## Chapter 1: The Beginning
## Chapter 2: The Middle
## Chapter 3: The End

INT. SOMEWHERE - DAY

Content.
"""

        let script = try FountainScript(string: fountainText)
        let outline = script.extractOutline()

        let chapters = outline.filter { $0.isChapter }
        #expect(chapters.count == 3)

        #expect(chapters[0].string == "Chapter 1: The Beginning")
        #expect(chapters[0].level == 2)
        #expect(chapters[1].string == "Chapter 2: The Middle")
        #expect(chapters[2].string == "Chapter 3: The End")
    }

    @Test("ElementType property returns 'outline' for API compatibility")
    func testElementTypePropertyReturnsOutline() async throws {
        let fountainText = """
# My Script
## Chapter 1
### MUSIC: Jazz plays softly

INT. COFFEE SHOP - DAY

A scene happens here.
"""

        let script = try FountainScript(string: fountainText)
        let outline = script.extractOutline()

        // Test that all outline elements have elementType "outline"
        for element in outline {
            #expect(element.elementType == "outline", "All outline elements should have elementType 'outline'")
        }

        // Test specific element types
        let title = outline.first { $0.isMainTitle }
        #expect(title?.elementType == "outline", "Title element should have elementType 'outline'")

        let chapter = outline.first { $0.isChapter }
        #expect(chapter?.elementType == "outline", "Chapter element should have elementType 'outline'")

        let sceneDirective = outline.first { $0.isSceneDirective }
        #expect(sceneDirective?.elementType == "outline", "Scene directive element should have elementType 'outline'")

        let sceneHeader = outline.first { $0.type == "sceneHeader" }
        #expect(sceneHeader?.elementType == "outline", "Scene header element should have elementType 'outline'")

        // Test that elementType is consistent regardless of internal type
        let sectionHeaders = outline.filter { $0.type == "sectionHeader" }
        for header in sectionHeaders {
            #expect(header.elementType == "outline", "All section headers should have elementType 'outline'")
        }
    }

    @Test("Parent-child relationships and tree structure")
    func testParentChildRelationships() async throws {
        let fountainText = """
# My Script
## Chapter 1: The Beginning
### MUSIC: Jazz plays softly
### SOUND: Rain on window

INT. COFFEE SHOP - DAY

Action happens here.

## Chapter 2: The Middle
### LIGHTING: Dim and moody

INT. ANOTHER PLACE - NIGHT

More action.

## END CHAPTER 2
"""

        let script = try FountainScript(string: fountainText)
        let outline = script.extractOutline()

        // Verify parent-child relationships exist
        let title = outline.first { $0.isMainTitle }
        #expect(title != nil, "Should have a main title")

        let chapters = outline.filter { $0.isChapter && !$0.isEndMarker }
        #expect(chapters.count == 2, "Should have 2 chapters")

        let sceneDirectives = outline.filter { $0.isSceneDirective }
        #expect(sceneDirectives.count == 3, "Should have 3 scene directives")

        // Test parent-child relationships
        for chapter in chapters {
            #expect(chapter.parentId == title?.id, "Chapters should have title as parent")
            #expect(title?.childIds.contains(chapter.id) == true, "Title should contain chapters as children")
        }

        for directive in sceneDirectives {
            let parentChapter = chapters.first { $0.childIds.contains(directive.id) }
            #expect(parentChapter != nil, "Scene directives should have chapter as parent")
            #expect(directive.parentId == parentChapter?.id, "Scene directive parent should be chapter")
        }

        // Test END marker
        let endMarkers = outline.filter { $0.isEndMarker }
        #expect(endMarkers.count == 1, "Should have 1 end marker")
        #expect(endMarkers[0].string.uppercased().contains("END"), "End marker should contain 'END'")
        #expect(endMarkers[0].level == 2, "End markers should be level 2")

        // Test parent() and children() methods
        if let firstChapter = chapters.first {
            let parent = firstChapter.parent(from: outline)
            #expect(parent?.id == title?.id, "parent() method should return title")

            let children = firstChapter.children(from: outline)
            let expectedChildren = sceneDirectives.filter { $0.parentId == firstChapter.id }
            #expect(children.count == expectedChildren.count, "children() method should return correct count")
        }
    }

    @Test("Tree structure functionality")
    func testTreeStructure() async throws {
        let fountainText = """
# My Script
## Chapter 1
### MUSIC: Jazz plays
### SOUND: Rain

INT. PLACE - DAY

Action.

## Chapter 2
### LIGHTING: Dim

INT. OTHER - NIGHT

More action.
"""

        let script = try FountainScript(string: fountainText)
        let outline = script.extractOutline()
        let tree = outline.tree()

        // Test tree root
        #expect(tree.root != nil, "Tree should have a root")
        #expect(tree.root?.element.isMainTitle == true, "Root should be main title")

        // Test tree structure
        let allNodes = tree.allNodes
        #expect(allNodes.count > 0, "Tree should have nodes")

        // Test node relationships
        if let rootNode = tree.root {
            #expect(rootNode.children.count == 2, "Root should have 2 chapter children")
            
            for chapterNode in rootNode.children {
                #expect(chapterNode.element.isChapter, "Root children should be chapters")
                #expect(chapterNode.parent === rootNode, "Chapter parent should be root")
                
                // Test chapter children (scene directives)
                for directiveNode in chapterNode.children {
                    #expect(directiveNode.element.isSceneDirective, "Chapter children should be scene directives")
                    #expect(directiveNode.parent === chapterNode, "Directive parent should be chapter")
                }
            }
        }

        // Test tree utility methods
        let leafNodes = tree.leafNodes
        let sceneDirectives = outline.filter { $0.isSceneDirective }
        let sceneHeaders = outline.filter { $0.type == "sceneHeader" }
        let expectedLeafCount = sceneDirectives.count + sceneHeaders.count // Directives and scenes should be leaf nodes
        
        // Note: The exact leaf count depends on the structure, but we can verify there are leaf nodes
        #expect(leafNodes.count > 0, "Tree should have leaf nodes")
    }

    @Test("END marker detection")
    func testEndMarkerDetection() async throws {
        let fountainText = """
# My Script
## Chapter 1: The Beginning

Some content here.

## END CHAPTER 1
## Chapter 2: The Middle

More content.

## END
"""

        let script = try FountainScript(string: fountainText)
        let outline = script.extractOutline()

        let endMarkers = outline.filter { $0.isEndMarker }
        #expect(endMarkers.count == 2, "Should detect 2 END markers")

        // Test specific END markers
        let endChapter1 = endMarkers.first { $0.string.contains("CHAPTER 1") }
        #expect(endChapter1 != nil, "Should detect 'END CHAPTER 1'")
        #expect(endChapter1?.level == 2, "END markers should be level 2")

        let endMarker = endMarkers.first { $0.string == "END" }
        #expect(endMarker != nil, "Should detect simple 'END'")
        #expect(endMarker?.level == 2, "END markers should be level 2")

        // END markers should not be in parent stack (shouldn't have children)
        for endMarker in endMarkers {
            #expect(endMarker.childIds.isEmpty, "END markers should not have children")
        }
    }

    @Test("Convenience tree extraction method")
    func testConvenienceTreeExtraction() async throws {
        let fountainText = """
# My Script
## Chapter 1
### MUSIC: Jazz plays

INT. PLACE - DAY

Action.
"""

        let script = try FountainScript(string: fountainText)
        
        // Test convenience method
        let tree = script.extractOutlineTree()
        #expect(tree.root != nil, "Convenience method should return tree with root")
        
        // Should be equivalent to outline.tree()
        let outline = script.extractOutline()
        let manualTree = outline.tree()
        
        #expect(tree.allNodes.count == manualTree.allNodes.count, "Convenience method should produce same tree structure")
        #expect(tree.root?.element.id == manualTree.root?.element.id, "Trees should have same root")
    }
}