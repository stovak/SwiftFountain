# SwiftFountain

[![Tests](https://github.com/stovak/SwiftFountain/actions/workflows/tests.yml/badge.svg)](https://github.com/stovak/SwiftFountain/actions/workflows/tests.yml)

A Swift implementation of the Fountain screenplay markup language parser.

## Overview

SwiftFountain is a Swift conversion of the original Objective-C Fountain parser created by Nima Yousefi & John August using Claude Code 4.5 Sonnet. It provides full support for parsing and writing Fountain-formatted screenplays.

## Features

- Parse Fountain files and strings
- Support for all Fountain elements:
  - Scene Headings
  - Action
  - Character names
  - Dialogue
  - Parentheticals
  - Transitions
  - Dual Dialogue
  - Lyrics
  - Title Pages
  - Section Headings
  - Synopses
  - Notes and Comments
  - Boneyard (omitted content)
  - Page Breaks
  - Scene Numbers
  - Centered text

- Two parser implementations:
  - **FastFountainParser**: Line-by-line parser (recommended)
  - **FountainParser**: Regex-based parser

- Write parsed scripts back to Fountain format

## Installation

Add SwiftFountain to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "path/to/SwiftFountain", from: "1.0.0")
]
```

## Examples

### FountainDocumentApp - Document-Based macOS App with CoreData

A complete example application demonstrating how to build a document-based macOS app that reads `.fountain`, `.highland`, and `.textbundle` files and parses them into CoreData.

**Location:** `Examples/FountainDocumentApp/`

**Features:**
- SwiftUI document-based architecture using `DocumentGroup`
- Full support for `.fountain`, `.highland`, and `.textbundle` file formats
- CoreData integration for structured screenplay data
- Proper UTType declarations and Info.plist configuration
- Parse screenplay elements, title pages, and metadata into CoreData entities
- Browse and view screenplay structure with navigation interface

**See:** [FountainDocumentApp README](Examples/FountainDocumentApp/README.md) for detailed documentation.

## Usage

### Parsing a Fountain file

```swift
import SwiftFountain

// Using the fast parser (default)
let script = try FountainScript(file: "/path/to/screenplay.fountain")

// Using the regex parser
let script = try FountainScript(file: "/path/to/screenplay.fountain", parser: .regex)
```

### Parsing a Fountain string

```swift
let fountainText = """
Title: My Screenplay
Author: Your Name

INT. COFFEE SHOP - DAY

A screenwriter sits at a laptop, typing furiously.

SCREENWRITER
This is going to be great!
"""

let script = try FountainScript(string: fountainText)
```

### Accessing parsed elements

```swift
for element in script.elements {
    print("\(element.elementType): \(element.elementText)")
}

// Access title page
for page in script.titlePage {
    for (key, values) in page {
        print("\(key): \(values.joined(separator: ", "))")
    }
}
```

### Writing to Fountain format

```swift
// Get the full document as a string
let fountainOutput = script.stringFromDocument()

// Write to file
try script.write(toFile: "/path/to/output.fountain")

// Write to URL
let url = URL(fileURLWithPath: "/path/to/output.fountain")
try script.write(to: url)
```

### Getting Content from Any Format

```swift
let script = FountainScript()

// Get content URL for any supported format
let fountainURL = URL(fileURLWithPath: "/path/to/script.fountain")
let contentURL = try script.getContentUrl(from: fountainURL)
// Returns: /path/to/script.fountain

let textbundleURL = URL(fileURLWithPath: "/path/to/script.textbundle")
let contentURL = try script.getContentUrl(from: textbundleURL)
// Returns: /path/to/script.textbundle/script.fountain (or .md if no .fountain exists)

let highlandURL = URL(fileURLWithPath: "/path/to/script.highland")
let contentURL = try script.getContentUrl(from: highlandURL)
// Returns: URL to the .fountain or .md file inside the extracted archive

// Get content as a string
let content = try script.getContent(from: fountainURL)
// For .fountain files: Returns body content without front matter
// For .textbundle/.highland: Returns complete file content

// Get screenplay elements, parsing if needed
let elements = try script.getScreenplayElements()
// Returns existing elements if available, or parses from cached content

// Parse from a URL if elements don't exist
let emptyScript = FountainScript()
let elements = try emptyScript.getScreenplayElements(from: fountainURL)
// Reads content using getContent() and parses it
```

### Working with TextBundles

SwiftFountain supports reading and writing `.fountain` files within TextBundle/TextPack containers.

```swift
import SwiftFountain

// Read a .fountain file from a TextBundle
let script = try FountainScript(textBundleURL: URL(fileURLWithPath: "/path/to/script.textbundle"))

// Write to a new TextBundle with a .fountain file
let outputURL = try script.writeToTextBundle(
    destinationURL: URL(fileURLWithPath: "/path/to/destination"),
    fountainFilename: "screenplay.fountain"
)

// Write to TextBundle with resources (characters.json, outline.json)
let bundleURL = try script.writeToTextBundleWithResources(
    destinationURL: URL(fileURLWithPath: "/path/to/destination"),
    name: "screenplay",
    includeResources: true
)
```

### Working with Highland Files

SwiftFountain supports reading and writing Highland 2 files (`.highland`), which are ZIP archives containing TextBundles with screenplay data and resources.

```swift
import SwiftFountain

// Read a .highland file
let script = try FountainScript(highlandURL: URL(fileURLWithPath: "/path/to/script.highland"))

// Write to a new Highland file with resources
let highlandURL = try script.writeToHighland(
    destinationURL: URL(fileURLWithPath: "/path/to/destination"),
    name: "screenplay",
    includeResources: true
)
```

**Note:** Highland files may contain either `.fountain` files or `text.md`/`text.markdown` files. The loader automatically detects the correct format.

### Using FountainDocument for SwiftUI Document-Based Apps

SwiftFountain includes `FountainDocument`, a `ReferenceFileDocument` implementation that enables you to build document-based apps supporting `.fountain`, `.highland`, and `.textbundle` files.

```swift
import SwiftUI
import SwiftFountain

@main
struct MyApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { FountainDocument() }) { file in
            ContentView(document: file.$document)
        }
    }
}

struct ContentView: View {
    @Binding var document: FountainDocument

    var body: some View {
        VStack {
            Text("Title: \(document.script.filename ?? "Untitled")")
            Text("Elements: \(document.script.elements.count)")

            List(document.script.elements, id: \.elementText) { element in
                VStack(alignment: .leading) {
                    Text(element.elementType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(element.elementText)
                }
            }
        }
    }
}
```

**Document Type Configuration (Info.plist):**

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeExtensions</key>
        <array><string>fountain</string></array>
        <key>CFBundleTypeName</key>
        <string>Fountain Screenplay</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSItemContentTypes</key>
        <array><string>com.quote-unquote.fountain</string></array>
        <key>LSHandlerRank</key>
        <string>Owner</string>
    </dict>
    <!-- Add similar entries for .highland and .textbundle -->
</array>

<key>UTImportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>com.quote-unquote.fountain</string>
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.plain-text</string>
            <string>public.text</string>
        </array>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array><string>fountain</string></array>
        </dict>
    </dict>
    <!-- Add similar entries for .highland and .textbundle -->
</array>
```

**See the complete example:** [FountainDocumentApp](Examples/FountainDocumentApp/) demonstrates full CoreData integration with document parsing.

### Extracting Character Information

Generate a character list with dialogue statistics and scene appearances.

```swift
// Extract all characters from the script
let characters: CharacterList = script.extractCharacters()

// Access character information
for (name, info) in characters {
    print("\(name):")
    print("  Lines: \(info.counts.lineCount)")
    print("  Words: \(info.counts.wordCount)")
    print("  Scenes: \(info.scenes)")
}

// Write characters to JSON
try script.writeCharactersJSON(toFile: "/path/to/characters.json")
try script.writeCharactersJSON(to: URL(fileURLWithPath: "/path/to/characters.json"))
```

**Character JSON Format:**
```json
{
  "CHARACTER NAME": {
    "color": null,
    "counts": {
      "lineCount": 82,
      "wordCount": 558
    },
    "gender": {
      "unspecified": {}
    },
    "scenes": [0, 1, 3, 4, 10, 11]
  }
}
```

### Extracting Outline Structure

Generate a hierarchical outline of the screenplay structure with parent-child relationships.

```swift
// Extract the outline
let outline: OutlineList = script.extractOutline()

// Access outline elements
for element in outline {
    print("[\(element.level)] \(element.type): \(element.string)")
}

// Access parent-child relationships
for element in outline {
    if let parent = element.parent(from: outline) {
        print("\(element.string) is child of \(parent.string)")
    }
    
    let children = element.children(from: outline)
    if !children.isEmpty {
        print("\(element.string) has \(children.count) children")
    }
}

// Create a tree structure for hierarchical processing
let tree = outline.tree()
if let root = tree.root {
    print("Root: \(root.element.string)")
    print("Tree has \(tree.allNodes.count) total nodes")
    print("Tree has \(tree.leafNodes.count) leaf nodes")
}

// Write outline to JSON
try script.writeOutlineJSON(toFile: "/path/to/outline.json")
try script.writeOutlineJSON(to: URL(fileURLWithPath: "/path/to/outline.json"))
```

**Outline JSON Format:**
```json
[
  {
    "id": "UUID-STRING",
    "index": 0,
    "isCollapsed": false,
    "level": 1,
    "range": [0, 12],
    "rawString": "# My Screenplay",
    "string": "My Screenplay",
    "type": "sectionHeader",
    "sceneDirective": null,
    "sceneDirectiveDescription": null,
    "parentId": null,
    "childIds": ["uuid-chapter1", "uuid-chapter2"],
    "isEndMarker": false
  },
  {
    "id": "uuid-chapter1",
    "index": 1,
    "isCollapsed": false,
    "level": 2,
    "range": [238, 22],
    "rawString": "## CHAPTER 1",
    "string": "CHAPTER 1",
    "type": "sectionHeader",
    "sceneDirective": null,
    "sceneDirectiveDescription": null,
    "parentId": "UUID-STRING",
    "childIds": ["uuid-music"],
    "isEndMarker": false
  },
  {
    "id": "uuid-music",
    "index": 2,
    "isCollapsed": false,
    "level": 3,
    "range": [400, 35],
    "rawString": "### MUSIC: Jazz plays softly",
    "string": "MUSIC",
    "type": "sectionHeader",
    "sceneDirective": "MUSIC",
    "sceneDirectiveDescription": "Jazz plays softly",
    "parentId": "uuid-chapter1",
    "childIds": [],
    "isEndMarker": false
  },
  {
    "id": "uuid-end",
    "index": 3,
    "isCollapsed": false,
    "level": 2,
    "range": [600, 18],
    "rawString": "## END CHAPTER 1",
    "string": "END CHAPTER 1",
    "type": "sectionHeader",
    "sceneDirective": null,
    "sceneDirectiveDescription": null,
    "parentId": null,
    "childIds": [],
    "isEndMarker": true
  }
]
```

**Outline Element Types:**
- `sectionHeader`: Section headings with hierarchical levels:
  - **Level 1**: Main title (only one allowed, auto-generated from script name if missing)
  - **Level 2**: Chapter-level headings (`##`) and END markers (`## END ...`)
  - **Level 3**: Scene directive headings (`###`) - first word before colon becomes the directive name
  - **Level 4+**: Additional nested section levels
- `sceneHeader`: Scene headings (INT/EXT, etc.) at level 4
- `note`: Bracketed notes (`[[NOTE: ...]]`) at level 5
- `blank`: Final element marking end of document (level -1)

**Parent-Child Relationships:**
- Level 2 elements (chapters) are children of level 1 (main title)
- Level 3 elements (scene directives) are children of level 2 (chapters)
- Level 4 elements (scene headers) are children of level 3 (scene directives)
- END markers (`## END ...`) do not participate in the parent-child hierarchy

## API Reference

### FountainDocument

SwiftUI document wrapper for `.fountain`, `.highland`, and `.textbundle` files.

**Protocol:** `ReferenceFileDocument`

**Static Properties:**
- `readableContentTypes`: `[UTType]` - Supports `.fountain`, `.highland`, `.textbundle`
- `writableContentTypes`: `[UTType]` - Can write all three formats

**Instance Properties:**
- `script`: `FountainScript` - The underlying FountainScript instance

**Usage:**
```swift
DocumentGroup(newDocument: { FountainDocument() }) { file in
    ContentView(document: file.$document)
}
```

### FountainScript

The main class for working with Fountain scripts.

**Initialization:**
- `init()`: Create an empty script
- `init(file:parser:)`: Load a script from a file
- `init(string:parser:)`: Load a script from a string
- `init(textBundleURL:parser:)`: Load from a TextBundle containing a .fountain file
- `init(highlandURL:parser:)`: Load from a Highland (.highland) file

**Loading:**
- `loadFile(_:parser:)`: Load a file into an existing script
- `loadString(_:parser:)`: Load a string into an existing script
- `loadTextBundle(_:parser:)`: Load from a TextBundle URL
- `loadHighland(_:parser:)`: Load from a Highland file URL

**Writing:**
- `stringFromDocument()`: Get the complete document as Fountain text
- `stringFromBody()`: Get just the body (no title page)
- `stringFromTitlePage()`: Get just the title page
- `write(toFile:)`: Write to a file path
- `write(to:)`: Write to a URL
- `writeToTextBundle(destinationURL:fountainFilename:)`: Write to a TextBundle
- `writeToTextBundleWithResources(destinationURL:name:includeResources:)`: Write to a TextBundle with resources
- `writeToHighland(destinationURL:name:includeResources:)`: Write to a Highland file

**Content Access:**
- `getContentUrl(from:)`: Get the URL to the content file for any supported format (.fountain, .highland, .textbundle)
- `getContent(from:)`: Get content as a string from any supported format (strips front matter from .fountain files)
- `getScreenplayElements(from:parser:)`: Get screenplay elements, parsing if needed (optionally from URL)

**Analysis:**
- `extractCharacters()`: Returns `CharacterList` - dictionary of character names to character information
- `writeCharactersJSON(toFile:)`: Write character data to JSON file
- `writeCharactersJSON(to:)`: Write character data to JSON URL
- `extractOutline()`: Returns `OutlineList` - array of outline elements with parent-child relationships
- `extractOutlineTree()`: Returns `OutlineTree` - hierarchical tree structure of outline elements
- `writeOutlineJSON(toFile:)`: Write outline data to JSON file
- `writeOutlineJSON(to:)`: Write outline data to JSON URL

**Properties:**
- `elements`: `[FountainElement]` - Array of parsed screenplay elements
- `titlePage`: `[[String: [String]]]` - Title page metadata
- `filename`: `String?` - Original filename if loaded from file
- `suppressSceneNumbers`: `Bool` - Whether to suppress scene numbers when writing

### FountainElement

Represents a single element in a screenplay.

**Properties:**
- `elementType`: `String` - The type of element (e.g., "Scene Heading", "Action", "Dialogue", "Character", "Parenthetical", "Transition", "Section Heading", "Comment")
- `elementText`: `String` - The text content
- `isCentered`: `Bool` - Whether the text is centered
- `sceneNumber`: `String?` - Scene number (for scene headings)
- `isDualDialogue`: `Bool` - Whether this is dual dialogue
- `sectionDepth`: `UInt` - Depth of section heading (1 for `#`, 2 for `##`, etc.)

### CharacterInfo

Information about a character extracted from the screenplay.

**Properties:**
- `color`: `String?` - Optional color metadata
- `counts`: `CharacterCounts` - Dialogue statistics
  - `lineCount`: `Int` - Number of dialogue blocks
  - `wordCount`: `Int` - Total words spoken (including parentheticals)
- `gender`: `CharacterGender` - Gender specification (currently always `unspecified`)
- `scenes`: `[Int]` - Array of scene indices where character appears

### OutlineElement

Represents a structural element in the screenplay outline with parent-child relationships.

**Properties:**
- `id`: `String` - Unique UUID for this element
- `index`: `Int` - Sequential index in the outline
- `isCollapsed`: `Bool` - UI hint for collapsible display (always `false`)
- `level`: `Int` - Hierarchical level (1 for main title, 2 for chapters, 3 for scene directives, 4 for scenes, 5 for notes, -1 for blank end marker)
- `range`: `[Int]` - Character position `[start, length]` in source text
- `rawString`: `String` - Original formatting (e.g., `"## CHAPTER 1"` or `"### MUSIC: Jazz plays softly"`)
- `string`: `String` - Clean display text (e.g., `"CHAPTER 1"` or `"MUSIC"`)
- `type`: `String` - Element type (`"sectionHeader"`, `"sceneHeader"`, `"note"`, `"blank"`)
- `sceneDirective`: `String?` - For level 3 scene directives, the directive name (e.g., `"MUSIC"`, `"SOUND"`)
- `sceneDirectiveDescription`: `String?` - For level 3 scene directives, the full description after the colon
- `elementType`: `String` - Always returns `"outline"` for API compatibility with `FountainElement`
- `parentId`: `String?` - ID of the parent element in the hierarchy
- `childIds`: `[String]` - Array of child element IDs
- `isEndMarker`: `Bool` - True if this is an END chapter marker (e.g., `"## END CHAPTER 1"`)

**Computed Properties:**
- `isSceneDirective`: `Bool` - Returns true if this is a scene directive (level 3 section header)
- `isChapter`: `Bool` - Returns true if this is a chapter-level header (level 2)
- `isMainTitle`: `Bool` - Returns true if this is the main title (level 1)

**Methods:**
- `parent(from: OutlineList)`: `OutlineElement?` - Get the parent element from the outline list
- `children(from: OutlineList)`: `[OutlineElement]` - Get all direct children elements from the outline list
- `descendants(from: OutlineList)`: `[OutlineElement]` - Get all descendant elements (children, grandchildren, etc.)

### OutlineTree

Tree structure for hierarchical processing of outline elements.

**Properties:**
- `root`: `OutlineTreeNode?` - The root node of the tree (usually the main title)

**Methods:**
- `init(from: OutlineList)` - Create a tree from an outline list
- `node(for: String)`: `OutlineTreeNode?` - Find a node by element ID
- `allNodes`: `[OutlineTreeNode]` - Get all nodes in the tree (flattened)
- `leafNodes`: `[OutlineTreeNode]` - Get all leaf nodes (nodes without children)

### OutlineTreeNode

Node in the outline tree structure.

**Properties:**
- `element`: `OutlineElement` - The outline element this node represents
- `children`: `[OutlineTreeNode]` - Child nodes
- `parent`: `OutlineTreeNode?` - Parent node (weak reference)

**Computed Properties:**
- `descendants`: `[OutlineTreeNode]` - All descendant nodes
- `hasChildren`: `Bool` - Whether this node has children
- `depth`: `Int` - Depth of this node in the tree (root = 0)

**Methods:**
- `addChild(_: OutlineTreeNode)` - Add a child node

**Usage:**
```swift
// Create tree structure
let outline = script.extractOutline()
let tree = outline.tree()

// Navigate the tree
if let root = tree.root {
    print("Root: \(root.element.string)")
    for chapter in root.children {
        print("  Chapter: \(chapter.element.string)")
        for directive in chapter.children {
            print("    Directive: \(directive.element.string)")
        }
    }
}
```

### ParserType

Enum specifying which parser to use.

- `.fast`: Line-by-line parser (default, recommended)
- `.regex`: Regular expression-based parser (legacy)

## License

MIT License - Copyright (c) 2012-2013 Nima Yousefi & John August

See LICENSE file for details.

## Credits

Original Objective-C implementation by Nima Yousefi & John August
Swift conversion (c) 2025

Fountain specification: https://fountain.io
