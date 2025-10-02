//
//  FountainDocumentParser.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import CoreData
import SwiftFountain

class FountainDocumentParser {

    /// Parse a FountainScript into CoreData entities
    /// - Parameters:
    ///   - script: The FountainScript to parse
    ///   - context: The NSManagedObjectContext to use
    /// - Returns: The created FountainDocumentEntity
    static func parse(script: FountainScript, in context: NSManagedObjectContext) -> FountainDocumentEntity {
        let documentEntity = FountainDocumentEntity(context: context)

        // Set basic properties
        documentEntity.filename = script.filename
        documentEntity.rawContent = script.stringFromDocument()
        documentEntity.suppressSceneNumbers = script.suppressSceneNumbers

        // Parse title page
        for titlePageDict in script.titlePage {
            for (key, values) in titlePageDict {
                let titlePageEntry = TitlePageEntry(context: context)
                titlePageEntry.key = key
                titlePageEntry.values = values
                documentEntity.addToTitlePage(titlePageEntry)
            }
        }

        // Parse elements
        for element in script.elements {
            let elementEntity = FountainElementEntity(context: context)
            elementEntity.elementType = element.elementType
            elementEntity.elementText = element.elementText
            elementEntity.isCentered = element.isCentered
            elementEntity.isDualDialogue = element.isDualDialogue
            elementEntity.sceneNumber = element.sceneNumber
            elementEntity.sectionDepth = Int16(element.sectionDepth)
            documentEntity.addToElements(elementEntity)
        }

        return documentEntity
    }

    /// Load a Fountain document from URL and parse into CoreData
    /// - Parameters:
    ///   - url: The URL of the document
    ///   - context: The NSManagedObjectContext to use
    /// - Returns: The created FountainDocumentEntity
    /// - Throws: Parsing errors
    static func loadAndParse(from url: URL, in context: NSManagedObjectContext) throws -> FountainDocumentEntity {
        let script = FountainScript()

        // Determine file type and load accordingly
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "highland":
            try script.loadHighland(url)
        case "textbundle":
            try script.loadTextBundle(url)
        case "fountain":
            try script.loadFile(url.path)
        default:
            throw FountainDocumentParserError.unsupportedFileType(pathExtension)
        }

        return parse(script: script, in: context)
    }

    /// Convert a CoreData entity back to a FountainScript
    /// - Parameter entity: The FountainDocumentEntity to convert
    /// - Returns: A FountainScript instance
    static func toFountainScript(from entity: FountainDocumentEntity) -> FountainScript {
        let script = FountainScript()

        // Set basic properties
        script.filename = entity.filename
        script.suppressSceneNumbers = entity.suppressSceneNumbers

        // Convert title page
        if let titlePageSet = entity.titlePage?.array as? [TitlePageEntry] {
            var titlePageArray: [[String: [String]]] = []
            for entry in titlePageSet {
                titlePageArray.append([entry.key: entry.values])
            }
            script.titlePage = titlePageArray
        }

        // Convert elements
        if let elementsSet = entity.elements?.array as? [FountainElementEntity] {
            for elementEntity in elementsSet {
                let element = FountainElement(
                    elementType: elementEntity.elementType,
                    elementText: elementEntity.elementText
                )
                element.isCentered = elementEntity.isCentered
                element.isDualDialogue = elementEntity.isDualDialogue
                element.sceneNumber = elementEntity.sceneNumber
                element.sectionDepth = UInt(elementEntity.sectionDepth)
                script.elements.append(element)
            }
        }

        return script
    }
}

// MARK: - Error Types

enum FountainDocumentParserError: Error {
    case unsupportedFileType(String)
    case parsingFailed(String)
}
