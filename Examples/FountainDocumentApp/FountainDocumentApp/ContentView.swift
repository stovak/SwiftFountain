//
//  ContentView.swift
//  FountainDocumentApp
//
//  Copyright (c) 2025
//

import SwiftUI
import SwiftFountain
import SwiftData

struct ContentView: View {
    @Binding var document: FountainDocument
    @Environment(\.modelContext) private var modelContext

    @State private var documentModel: FountainDocumentModel?
    @State private var isLoading = false

    var body: some View {
        NavigationSplitView {
            List {
                if let model = documentModel {
                    Section("Title Page") {
                        ForEach(model.titlePage) { entry in
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

                    Section("Elements (\(model.elements.count))") {
                        ForEach(model.elements.prefix(20)) { element in
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
                        if model.elements.count > 20 {
                            Text("... and \(model.elements.count - 20) more elements")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
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
                    Button("Parse to SwiftData") {
                        parseDocument()
                    }
                    .disabled(isLoading)
                }
            }
        } detail: {
            if let model = documentModel {
                ScriptDetailView(model: model)
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

        // Clear existing document model
        if let existing = documentModel {
            modelContext.delete(existing)
        }

        // Parse the document
        let model = FountainDocumentParserSwiftData.parse(script: document.script, in: modelContext)
        documentModel = model

        // Save the context
        do {
            try modelContext.save()
            isLoading = false
        } catch {
            print("Failed to save context: \(error)")
            isLoading = false
        }
    }
}

struct ElementDetailView: View {
    let element: FountainElementModel

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
    let model: FountainDocumentModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let filename = model.filename {
                Text("Filename: \(filename)")
                    .font(.headline)
            }

            Text("Elements: \(model.elements.count)")
            Text("Title Page Entries: \(model.titlePage.count)")
            Text("Suppress Scene Numbers: \(model.suppressSceneNumbers ? "Yes" : "No")")

            Divider()

            if let content = model.rawContent {
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
