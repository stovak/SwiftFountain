//
//  ContentView.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import SwiftUI
import SwiftFountain
import CoreData

struct ContentView: View {
    @Binding var document: FountainDocument
    @Environment(\.managedObjectContext) private var viewContext

    @State private var documentEntity: FountainDocumentEntity?
    @State private var isLoading = false

    var body: some View {
        NavigationSplitView {
            List {
                if let entity = documentEntity {
                    Section("Title Page") {
                        if let titlePage = entity.titlePage?.array as? [TitlePageEntry] {
                            ForEach(titlePage) { entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.key)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    ForEach(entry.values, id: \.self) { value in
                                        Text(value)
                                            .font(.body)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    Section("Elements (\(entity.elements?.count ?? 0))") {
                        if let elements = entity.elements?.array as? [FountainElementEntity] {
                            ForEach(elements.prefix(20)) { element in
                                NavigationLink {
                                    ElementDetailView(element: element)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(element.elementType)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(element.elementText)
                                            .font(.body)
                                            .lineLimit(2)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            if elements.count > 20 {
                                Text("... and \(elements.count - 20) more elements")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                } else if isLoading {
                    ProgressView("Loading document...")
                } else {
                    Text("No document loaded")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(document.script.filename ?? "Untitled")
            .toolbar {
                ToolbarItem {
                    Button("Parse to CoreData") {
                        parseDocument()
                    }
                    .disabled(isLoading)
                }
            }
        } detail: {
            if let entity = documentEntity {
                ScriptDetailView(entity: entity)
            } else {
                Text("Select an element to view details")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            parseDocument()
        }
        .onChange(of: document.script) { _ in
            parseDocument()
        }
    }

    private func parseDocument() {
        isLoading = true

        // Clear existing document entity
        if let existing = documentEntity {
            viewContext.delete(existing)
        }

        // Parse the document
        let entity = FountainDocumentParser.parse(script: document.script, in: viewContext)
        documentEntity = entity

        // Save the context
        do {
            try viewContext.save()
            isLoading = false
        } catch {
            print("Failed to save context: \(error)")
            isLoading = false
        }
    }
}

struct ElementDetailView: View {
    let element: FountainElementEntity

    var body: some View {
        Form {
            Section("Element Properties") {
                LabeledContent("Type", value: element.elementType)
                LabeledContent("Text", value: element.elementText)
                LabeledContent("Centered", value: element.isCentered ? "Yes" : "No")
                LabeledContent("Dual Dialogue", value: element.isDualDialogue ? "Yes" : "No")
                if let sceneNumber = element.sceneNumber {
                    LabeledContent("Scene Number", value: sceneNumber)
                }
                if element.sectionDepth > 0 {
                    LabeledContent("Section Depth", value: String(element.sectionDepth))
                }
            }
        }
        .navigationTitle("Element Details")
    }
}

struct ScriptDetailView: View {
    let entity: FountainDocumentEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let filename = entity.filename {
                Text("Filename: \(filename)")
                    .font(.headline)
            }

            Text("Elements: \(entity.elements?.count ?? 0)")
            Text("Title Page Entries: \(entity.titlePage?.count ?? 0)")
            Text("Suppress Scene Numbers: \(entity.suppressSceneNumbers ? "Yes" : "No")")

            Divider()

            if let content = entity.rawContent {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
