# FountainDocumentApp Example

This example demonstrates how to use SwiftFountain with SwiftData in a document-based macOS application that supports `.fountain`, `.highland`, and `.textbundle` file formats.

## Features

- **Multiple File Format Support**: Opens and edits `.fountain`, `.highland`, and `.textbundle` documents
- **SwiftData Integration**: Parses Fountain documents into SwiftData models for structured data access
- **Document-Based Architecture**: Uses SwiftUI's `DocumentGroup` for native document handling
- **UTType Support**: Properly configured Uniform Type Identifiers for all supported formats

## Architecture

### Core Components

1. **FountainDocument** (`Sources/SwiftFountain/FountainDocument.swift`)
   - Implements `ReferenceFileDocument` protocol
   - Handles reading/writing of `.fountain`, `.highland`, and `.textbundle` files
   - Provides UTType declarations for all supported formats

2. **SwiftData Models** (`FountainDocumentModel.swift`)
   - **FountainDocumentModel**: Stores document metadata and references to elements
   - **FountainElementModel**: Represents individual Fountain elements (scenes, dialogue, action, etc.)
   - **TitlePageEntryModel**: Stores title page key-value pairs

3. **FountainDocumentParserSwiftData** (`FountainDocumentParserSwiftData.swift`)
   - Converts `FountainScript` objects to SwiftData models
   - Bidirectional conversion support (SwiftData ↔ FountainScript)
   - Handles all three file formats through unified API

### UI Components

- **ContentView**: Main document view with navigation split view
  - Lists title page entries and elements
  - Provides "Parse to SwiftData" button to refresh data
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

### Parsing to SwiftData

1. Open any supported document
2. The document is automatically parsed on load
3. Click "Parse to SwiftData" to manually refresh the parsed data
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

## Code Examples

### Loading and Parsing a Document

```swift
import SwiftData
import SwiftFountain

// Set up ModelContainer in your App
@main
struct FountainDocumentAppApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { FountainDocument() }) { file in
            ContentView(document: file.$document)
                .modelContainer(for: [
                    FountainDocumentModel.self,
                    FountainElementModel.self,
                    TitlePageEntryModel.self
                ])
        }
    }
}

// In your view, access the ModelContext
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    func parseDocument(url: URL) throws {
        // Load and parse from URL
        let documentModel = try FountainDocumentParserSwiftData.loadAndParse(
            from: url,
            in: modelContext
        )

        // Save to SwiftData
        try modelContext.save()
    }
}
```

### Parsing an Existing FountainScript

```swift
import SwiftData
import SwiftFountain

@Environment(\.modelContext) private var modelContext

func parseScript(_ script: FountainScript) {
    // Parse an existing FountainScript
    let model = FountainDocumentParserSwiftData.parse(
        script: script,
        in: modelContext
    )

    // Save the context
    try? modelContext.save()
}
```

### Converting Back to FountainScript

```swift
// Convert SwiftData model back to FountainScript
let script = FountainDocumentParserSwiftData.toFountainScript(from: model)

// Write to file
try script.write(to: outputURL)
```

### Accessing Parsed SwiftData Objects

#### From .fountain Files

```swift
import SwiftData
import SwiftFountain

func loadFountainFile(url: URL) throws {
    let modelContext = ModelContext(modelContainer)

    // Parse .fountain file
    let documentModel = try FountainDocumentParserSwiftData.loadAndParse(
        from: url,
        in: modelContext
    )

    // Access elements
    for element in documentModel.elements {
        print("\(element.elementType): \(element.elementText)")
        if let sceneNumber = element.sceneNumber {
            print("  Scene #\(sceneNumber)")
        }
    }

    // Access title page
    for entry in documentModel.titlePage {
        print("\(entry.key): \(entry.values.joined(separator: ", "))")
    }

    try modelContext.save()
}
```

#### From .highland Files

```swift
import SwiftData
import SwiftFountain

func loadHighlandFile(url: URL) throws {
    let modelContext = ModelContext(modelContainer)

    // Parse .highland file (automatically handles ZIP extraction)
    let documentModel = try FountainDocumentParserSwiftData.loadAndParse(
        from: url,
        in: modelContext
    )

    print("Filename: \(documentModel.filename ?? "Untitled")")
    print("Elements: \(documentModel.elements.count)")
    print("Suppress scene numbers: \(documentModel.suppressSceneNumbers)")

    try modelContext.save()
}
```

#### From .textbundle Files

```swift
import SwiftData
import SwiftFountain

func loadTextBundleFile(url: URL) throws {
    let modelContext = ModelContext(modelContainer)

    // Parse .textbundle file (automatically handles package format)
    let documentModel = try FountainDocumentParserSwiftData.loadAndParse(
        from: url,
        in: modelContext
    )

    // Filter by element type
    let scenes = documentModel.elements.filter { $0.elementType == "Scene Heading" }
    let dialogue = documentModel.elements.filter { $0.elementType == "Dialogue" }

    print("Scenes: \(scenes.count)")
    print("Dialogue blocks: \(dialogue.count)")

    try modelContext.save()
}
```

### Querying SwiftData Models

```swift
import SwiftData

// Fetch all documents
@Query private var allDocuments: [FountainDocumentModel]

// Fetch with predicate
@Query(filter: #Predicate<FountainDocumentModel> { doc in
    doc.suppressSceneNumbers == false
}) private var documentsWithSceneNumbers: [FountainDocumentModel]

// Fetch sorted
@Query(sort: \FountainDocumentModel.filename)
private var sortedDocuments: [FountainDocumentModel]

// Using ModelContext directly
func findDocumentsByFilename(_ name: String) throws -> [FountainDocumentModel] {
    let descriptor = FetchDescriptor<FountainDocumentModel>(
        predicate: #Predicate { doc in
            doc.filename?.contains(name) ?? false
        }
    )
    return try modelContext.fetch(descriptor)
}
```

## Info.plist Configuration

The app's `Info.plist` declares support for all three document types with proper UTType declarations:

- `com.quote-unquote.fountain` - Fountain files
- `com.highland.highland` - Highland documents
- `org.textbundle.package` - TextBundle packages

## Requirements

- macOS 14.0+ (for SwiftData support)
- Xcode 15.0+
- Swift 6.0+
- SwiftFountain package

## License

Same license as SwiftFountain (MIT License)
