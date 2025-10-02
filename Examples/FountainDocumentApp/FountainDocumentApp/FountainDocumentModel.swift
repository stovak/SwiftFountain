//
//  FountainDocumentModel.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import Foundation
import SwiftData

@Model
final class FountainDocumentModel {
    var filename: String?
    var rawContent: String?
    var suppressSceneNumbers: Bool

    @Relationship(deleteRule: .cascade, inverse: \FountainElementModel.document)
    var elements: [FountainElementModel]

    @Relationship(deleteRule: .cascade, inverse: \TitlePageEntryModel.document)
    var titlePage: [TitlePageEntryModel]

    init(filename: String? = nil, rawContent: String? = nil, suppressSceneNumbers: Bool = false) {
        self.filename = filename
        self.rawContent = rawContent
        self.suppressSceneNumbers = suppressSceneNumbers
        self.elements = []
        self.titlePage = []
    }
}

@Model
final class FountainElementModel {
    var elementText: String
    var elementType: String
    var isCentered: Bool
    var isDualDialogue: Bool
    var sceneNumber: String?
    var sectionDepth: Int

    var document: FountainDocumentModel?

    init(elementText: String, elementType: String, isCentered: Bool = false, isDualDialogue: Bool = false, sceneNumber: String? = nil, sectionDepth: Int = 0) {
        self.elementText = elementText
        self.elementType = elementType
        self.isCentered = isCentered
        self.isDualDialogue = isDualDialogue
        self.sceneNumber = sceneNumber
        self.sectionDepth = sectionDepth
    }
}

@Model
final class TitlePageEntryModel {
    var key: String
    var values: [String]

    var document: FountainDocumentModel?

    init(key: String, values: [String]) {
        self.key = key
        self.values = values
    }
}
