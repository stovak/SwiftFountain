# FountainDocumentApp Example

This example demonstrates how to use SwiftFountain with CoreData in a document-based macOS application that supports `.fountain`, `.highland`, and `.textbundle` file formats.

## Features

- **Multiple File Format Support**: Opens and edits `.fountain`, `.highland`, and `.textbundle` documents
- **CoreData Integration**: Parses Fountain documents into CoreData entities for structured data access
- **Document-Based Architecture**: Uses SwiftUI's `DocumentGroup` for native document handling
- **UTType Support**: Properly configured Uniform Type Identifiers for all supported formats

## Architecture

### Core Components

1. **FountainDocument** (`Sources/SwiftFountain/FountainDocument.swift`)
   - Implements `ReferenceFileDocument` protocol
   - Handles reading/writing of `.fountain`, `.highland`, and `.textbundle` files
   - Provides UTType declarations for all supported formats

2. **CoreData Model** (`FountainModel.xcdatamodeld`)
   - **FountainDocumentEntity**: Stores document metadata and references to elements
   - **FountainElementEntity**: Represents individual Fountain elements (scenes, dialogue, action, etc.)
   - **TitlePageEntry**: Stores title page key-value pairs

3. **FountainDocumentParser** (`FountainDocumentParser.swift`)
   - Converts `FountainScript` objects to CoreData entities
   - Bidirectional conversion support (CoreData ↔ FountainScript)
   - Handles all three file formats through unified API

4. **PersistenceController** (`PersistenceController.swift`)
   - Manages CoreData stack
   - Provides shared instance and background contexts
   - Handles saving and merging changes

### UI Components

- **ContentView**: Main document view with navigation split view
  - Lists title page entries and elements
  - Provides "Parse to CoreData" button to refresh data
  - Shows document statistics and raw content

- **ElementDetailView**: Detailed view of individual Fountain elements
  - Displays all element properties (type, text, scene number, etc.)

- **ScriptDetailView**: Overview of the entire parsed document
  - Shows document metadata
  - Displays raw Fountain content

## Usage

### Opening Documents

The app automatically handles opening of:
- `.fountain` files (plain text Fountain format)
- `.highland` files (ZIP archives containing TextBundle)
- `.textbundle` packages (directories with Fountain content)

### Parsing to CoreData

1. Open any supported document
2. The document is automatically parsed on load
3. Click "Parse to CoreData" to manually refresh the parsed data
4. Browse elements in the sidebar
5. View details by selecting an element

### File Type Support

| Format | Extension | Description |
|--------|-----------|-------------|
| Fountain | `.fountain` | Plain text screenplay format |
| Highland | `.highland` | ZIP archive containing TextBundle with resources |
| TextBundle | `.textbundle` | Package format with Fountain file and assets |

## Building

1. Open `FountainDocumentApp.xcodeproj` in Xcode
2. Ensure SwiftFountain package is properly referenced (local package at `../..`)
3. Build and run (⌘R)

## Code Example

### Loading and Parsing a Document

```swift
// Load from URL
let documentEntity = try FountainDocumentParser.loadAndParse(
    from: url,
    in: persistenceController.container.viewContext
)

// Or parse an existing FountainScript
let script = try FountainScript(file: "/path/to/script.fountain")
let entity = FountainDocumentParser.parse(
    script: script,
    in: context
)
```

### Converting Back to FountainScript

```swift
let script = FountainDocumentParser.toFountainScript(from: entity)
try script.write(to: outputURL)
```

### Accessing Parsed Data

```swift
// Access elements
if let elements = documentEntity.elements?.array as? [FountainElementEntity] {
    for element in elements {
        print("\(element.elementType): \(element.elementText)")
    }
}

// Access title page
if let titlePage = documentEntity.titlePage?.array as? [TitlePageEntry] {
    for entry in titlePage {
        print("\(entry.key): \(entry.values.joined(separator: ", "))")
    }
}
```

## Info.plist Configuration

The app's `Info.plist` declares support for all three document types with proper UTType declarations:

- `com.quote-unquote.fountain` - Fountain files
- `com.highland.highland` - Highland documents
- `org.textbundle.package` - TextBundle packages

## Requirements

- macOS 14.0+
- Xcode 15.0+
- Swift 6.0+
- SwiftFountain package

## License

Same license as SwiftFountain (MIT License)
