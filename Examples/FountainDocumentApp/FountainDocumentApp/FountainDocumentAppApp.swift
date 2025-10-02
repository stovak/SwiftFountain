//
//  FountainDocumentAppApp.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import SwiftUI
import SwiftFountain
import SwiftData

@main
struct FountainDocumentAppApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { FountainDocument() }) { file in
            ContentView(document: file.$document)
                .modelContainer(for: FountainDocumentModel.self)
        }
    }
}
