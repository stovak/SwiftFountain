//
//  FountainDocumentParserSwiftData.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import SwiftData
import SwiftFountain

class FountainDocumentParserSwiftData {

    /// Parse a FountainScript into SwiftData models
    /// - Parameters:
    ///   - script: The FountainScript to parse
    ///   - modelContext: The ModelContext to use
    /// - Returns: The created FountainDocumentModel
    static func parse(script: FountainScript, in modelContext: ModelContext) -> FountainDocumentModel {
        let documentModel = FountainDocumentModel(
            filename: script.filename,
            rawContent: script.stringFromDocument(),
            suppressSceneNumbers: script.suppressSceneNumbers
        )

        // Parse title page
        for titlePageDict in script.titlePage {
            for (key, values) in titlePageDict {
                let titlePageEntry = TitlePageEntryModel(key: key, values: values)
                titlePageEntry.document = documentModel
                documentModel.titlePage.append(titlePageEntry)
            }
        }

        // Parse elements
        for element in script.elements {
            let elementModel = FountainElementModel(
                elementText: element.elementText,
                elementType: element.elementType,
                isCentered: element.isCentered,
                isDualDialogue: element.isDualDialogue,
                sceneNumber: element.sceneNumber,
                sectionDepth: Int(element.sectionDepth)
            )
            elementModel.document = documentModel
            documentModel.elements.append(elementModel)
        }

        modelContext.insert(documentModel)
        return documentModel
    }

    /// Load a Fountain document from URL and parse into SwiftData
    /// - Parameters:
    ///   - url: The URL of the document
    ///   - modelContext: The ModelContext to use
    /// - Returns: The created FountainDocumentModel
    /// - Throws: Parsing errors
    static func loadAndParse(from url: URL, in modelContext: ModelContext) throws -> FountainDocumentModel {
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

        return parse(script: script, in: modelContext)
    }

    /// Convert a SwiftData model back to a FountainScript
    /// - Parameter model: The FountainDocumentModel to convert
    /// - Returns: A FountainScript instance
    static func toFountainScript(from model: FountainDocumentModel) -> FountainScript {
        let script = FountainScript()

        // Set basic properties
        script.filename = model.filename
        script.suppressSceneNumbers = model.suppressSceneNumbers

        // Convert title page
        var titlePageArray: [[String: [String]]] = []
        for entry in model.titlePage {
            titlePageArray.append([entry.key: entry.values])
        }
        script.titlePage = titlePageArray

        // Convert elements
        for elementModel in model.elements {
            let element = FountainElement(
                elementType: elementModel.elementType,
                elementText: elementModel.elementText
            )
            element.isCentered = elementModel.isCentered
            element.isDualDialogue = elementModel.isDualDialogue
            element.sceneNumber = elementModel.sceneNumber
            element.sectionDepth = UInt(elementModel.sectionDepth)
            script.elements.append(element)
        }

        return script
    }
}
