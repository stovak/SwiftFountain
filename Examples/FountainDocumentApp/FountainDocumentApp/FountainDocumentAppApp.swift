//
//  FountainDocumentAppApp.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import SwiftUI
import SwiftFountain

@main
struct FountainDocumentAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        DocumentGroup(newDocument: { FountainDocument() }) { file in
            ContentView(document: file.$document)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
