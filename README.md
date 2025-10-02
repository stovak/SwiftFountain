# SwiftFountain

A Swift implementation of the Fountain screenplay markup language parser.

## Overview

SwiftFountain is a Swift conversion of the original Objective-C Fountain parser created by Nima Yousefi & John August. It provides full support for parsing and writing Fountain-formatted screenplays.

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
```

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

Generate a hierarchical outline of the screenplay structure.

```swift
// Extract the outline
let outline: OutlineList = script.extractOutline()

// Access outline elements
for element in outline {
    print("[\(element.level)] \(element.type): \(element.string)")
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
    "level": 2,
    "range": [0, 12],
    "rawString": "## CHAPTER 1",
    "string": "CHAPTER 1",
    "type": "sectionHeader"
  },
  {
    "id": "UUID-STRING",
    "index": 1,
    "isCollapsed": false,
    "level": 4,
    "range": [238, 22],
    "rawString": "INT. STEAM ROOM - DAY",
    "string": "INT. STEAM ROOM - DAY",
    "type": "sceneHeader"
  }
]
```

**Outline Element Types:**
- `sectionHeader`: Section headings (`#`, `##`, `###`, etc.) with corresponding level
- `sceneHeader`: Scene headings (INT/EXT, etc.) at level 4
- `note`: Bracketed notes (`[[NOTE: ...]]`) at level 5
- `blank`: Final element marking end of document (level -1)

## API Reference

### FountainScript

The main class for working with Fountain scripts.

**Initialization:**
- `init()`: Create an empty script
- `init(file:parser:)`: Load a script from a file
- `init(string:parser:)`: Load a script from a string
- `init(textBundleURL:parser:)`: Load from a TextBundle containing a .fountain file

**Loading:**
- `loadFile(_:parser:)`: Load a file into an existing script
- `loadString(_:parser:)`: Load a string into an existing script
- `loadTextBundle(_:parser:)`: Load from a TextBundle URL

**Writing:**
- `stringFromDocument()`: Get the complete document as Fountain text
- `stringFromBody()`: Get just the body (no title page)
- `stringFromTitlePage()`: Get just the title page
- `write(toFile:)`: Write to a file path
- `write(to:)`: Write to a URL
- `writeToTextBundle(destinationURL:fountainFilename:)`: Write to a TextBundle

**Analysis:**
- `extractCharacters()`: Returns `CharacterList` - dictionary of character names to character information
- `writeCharactersJSON(toFile:)`: Write character data to JSON file
- `writeCharactersJSON(to:)`: Write character data to JSON URL
- `extractOutline()`: Returns `OutlineList` - array of outline elements
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

Represents a structural element in the screenplay outline.

**Properties:**
- `id`: `String` - Unique UUID for this element
- `index`: `Int` - Sequential index in the outline
- `isCollapsed`: `Bool` - UI hint for collapsible display (always `false`)
- `level`: `Int` - Hierarchical level (2-5 for headers, -1 for blank end marker)
- `range`: `[Int]` - Character position `[start, length]` in source text
- `rawString`: `String` - Original formatting (e.g., `"## CHAPTER 1"`)
- `string`: `String` - Clean display text (e.g., `"CHAPTER 1"`)
- `type`: `String` - Element type (`"sectionHeader"`, `"sceneHeader"`, `"note"`, `"blank"`)

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
