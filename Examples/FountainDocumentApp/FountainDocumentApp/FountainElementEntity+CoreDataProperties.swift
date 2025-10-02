//
//  FountainElementEntity+CoreDataProperties.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import Foundation
import CoreData

extension FountainElementEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FountainElementEntity> {
        return NSFetchRequest<FountainElementEntity>(entityName: "FountainElementEntity")
    }

    @NSManaged public var elementText: String
    @NSManaged public var elementType: String
    @NSManaged public var isCentered: Bool
    @NSManaged public var isDualDialogue: Bool
    @NSManaged public var sceneNumber: String?
    @NSManaged public var sectionDepth: Int16
    @NSManaged public var document: FountainDocumentEntity?

}

extension FountainElementEntity : Identifiable {

}
