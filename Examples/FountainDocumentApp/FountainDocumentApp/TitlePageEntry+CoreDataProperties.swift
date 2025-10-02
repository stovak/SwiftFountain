//
//  TitlePageEntry+CoreDataProperties.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import Foundation
import CoreData

extension TitlePageEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TitlePageEntry> {
        return NSFetchRequest<TitlePageEntry>(entityName: "TitlePageEntry")
    }

    @NSManaged public var key: String
    @NSManaged public var values: [String]
    @NSManaged public var document: FountainDocumentEntity?

}

extension TitlePageEntry : Identifiable {

}
