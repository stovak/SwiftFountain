//
//  FountainDocumentEntity+CoreDataProperties.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import Foundation
import CoreData

extension FountainDocumentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FountainDocumentEntity> {
        return NSFetchRequest<FountainDocumentEntity>(entityName: "FountainDocumentEntity")
    }

    @NSManaged public var filename: String?
    @NSManaged public var rawContent: String?
    @NSManaged public var suppressSceneNumbers: Bool
    @NSManaged public var elements: NSOrderedSet?
    @NSManaged public var titlePage: NSOrderedSet?

}

// MARK: Generated accessors for elements
extension FountainDocumentEntity {

    @objc(insertObject:inElementsAtIndex:)
    @NSManaged public func insertIntoElements(_ value: FountainElementEntity, at idx: Int)

    @objc(removeObjectFromElementsAtIndex:)
    @NSManaged public func removeFromElements(at idx: Int)

    @objc(insertElements:atIndexes:)
    @NSManaged public func insertIntoElements(_ values: [FountainElementEntity], at indexes: NSIndexSet)

    @objc(removeElementsAtIndexes:)
    @NSManaged public func removeFromElements(at indexes: NSIndexSet)

    @objc(replaceObjectInElementsAtIndex:withObject:)
    @NSManaged public func replaceElements(at idx: Int, with value: FountainElementEntity)

    @objc(replaceElementsAtIndexes:withElements:)
    @NSManaged public func replaceElements(at indexes: NSIndexSet, with values: [FountainElementEntity])

    @objc(addElementsObject:)
    @NSManaged public func addToElements(_ value: FountainElementEntity)

    @objc(removeElementsObject:)
    @NSManaged public func removeFromElements(_ value: FountainElementEntity)

    @objc(addElements:)
    @NSManaged public func addToElements(_ values: NSOrderedSet)

    @objc(removeElements:)
    @NSManaged public func removeFromElements(_ values: NSOrderedSet)

}

// MARK: Generated accessors for titlePage
extension FountainDocumentEntity {

    @objc(insertObject:inTitlePageAtIndex:)
    @NSManaged public func insertIntoTitlePage(_ value: TitlePageEntry, at idx: Int)

    @objc(removeObjectFromTitlePageAtIndex:)
    @NSManaged public func removeFromTitlePage(at idx: Int)

    @objc(insertTitlePage:atIndexes:)
    @NSManaged public func insertIntoTitlePage(_ values: [TitlePageEntry], at indexes: NSIndexSet)

    @objc(removeTitlePageAtIndexes:)
    @NSManaged public func removeFromTitlePage(at indexes: NSIndexSet)

    @objc(replaceObjectInTitlePageAtIndex:withObject:)
    @NSManaged public func replaceTitlePage(at idx: Int, with value: TitlePageEntry)

    @objc(replaceTitlePageAtIndexes:withTitlePage:)
    @NSManaged public func replaceTitlePage(at indexes: NSIndexSet, with values: [TitlePageEntry])

    @objc(addTitlePageObject:)
    @NSManaged public func addToTitlePage(_ value: TitlePageEntry)

    @objc(removeTitlePageObject:)
    @NSManaged public func removeFromTitlePage(_ value: TitlePageEntry)

    @objc(addTitlePage:)
    @NSManaged public func addToTitlePage(_ values: NSOrderedSet)

    @objc(removeTitlePage:)
    @NSManaged public func removeFromTitlePage(_ values: NSOrderedSet)

}

extension FountainDocumentEntity : Identifiable {

}
