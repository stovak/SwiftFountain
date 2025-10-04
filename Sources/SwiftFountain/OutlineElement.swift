//
//  OutlineElement.swift
//  SwiftFountain
//
//  Copyright (c) 2025
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation

/// An element in the screenplay outline/structure
public struct OutlineElement: Codable {
    public var id: String
    public var index: Int
    public var isCollapsed: Bool
    public var level: Int
    public var range: [Int]
    public var rawString: String
    public var string: String
    public var type: String
    public var sceneDirective: String? // For level 3 headers, stores the directive name
    public var sceneDirectiveDescription: String? // For level 3 headers, stores the full description after the colon
    public var parentId: String? // ID of parent element in the hierarchy
    public var childIds: [String] // Array of child element IDs
    public var isEndMarker: Bool // True if this is an END chapter marker

    public init(id: String = UUID().uuidString, index: Int, isCollapsed: Bool = false, level: Int, range: [Int], rawString: String, string: String, type: String, sceneDirective: String? = nil, sceneDirectiveDescription: String? = nil, parentId: String? = nil, childIds: [String] = [], isEndMarker: Bool = false) {
        self.id = id
        self.index = index
        self.isCollapsed = isCollapsed
        self.level = level
        self.range = range
        self.rawString = rawString
        self.string = string
        self.type = type
        self.sceneDirective = sceneDirective
        self.sceneDirectiveDescription = sceneDirectiveDescription
        self.parentId = parentId
        self.childIds = childIds
        self.isEndMarker = isEndMarker
    }
    
    /// Returns "outline" for API compatibility with FountainElement
    public var elementType: String {
        return "outline"
    }
    
    /// Returns true if this is a scene directive (level 3 section header)
    public var isSceneDirective: Bool {
        return level == 3 && type == "sectionHeader"
    }
    
    /// Returns true if this is a chapter-level header (level 2)
    public var isChapter: Bool {
        return level == 2 && type == "sectionHeader"
    }
    
    /// Returns true if this is the main title (level 1)
    public var isMainTitle: Bool {
        return level == 1 && type == "sectionHeader"
    }
    
    /// Get the parent element from the outline list
    /// - Parameter outline: The complete outline list
    /// - Returns: The parent OutlineElement, or nil if no parent exists
    public func parent(from outline: OutlineList) -> OutlineElement? {
        guard let parentId = parentId else { return nil }
        return outline.first { $0.id == parentId }
    }
    
    /// Get all direct children elements from the outline list
    /// - Parameter outline: The complete outline list
    /// - Returns: Array of child OutlineElements
    public func children(from outline: OutlineList) -> [OutlineElement] {
        return outline.filter { childIds.contains($0.id) }
    }
    
    /// Get all descendant elements (children, grandchildren, etc.) from the outline list
    /// - Parameter outline: The complete outline list
    /// - Returns: Array of all descendant OutlineElements
    public func descendants(from outline: OutlineList) -> [OutlineElement] {
        var descendants: [OutlineElement] = []
        let directChildren = children(from: outline)
        
        for child in directChildren {
            descendants.append(child)
            descendants.append(contentsOf: child.descendants(from: outline))
        }
        
        return descendants
    }
}

/// Collection of all outline elements
public typealias OutlineList = [OutlineElement]

/// Tree node representing an outline element with its children
public class OutlineTreeNode {
    public let element: OutlineElement
    public var children: [OutlineTreeNode] = []
    public weak var parent: OutlineTreeNode?
    
    public init(element: OutlineElement) {
        self.element = element
    }
    
    /// Add a child node
    public func addChild(_ child: OutlineTreeNode) {
        children.append(child)
        child.parent = self
    }
    
    /// Get all descendant nodes (children, grandchildren, etc.)
    public var descendants: [OutlineTreeNode] {
        var result: [OutlineTreeNode] = []
        for child in children {
            result.append(child)
            result.append(contentsOf: child.descendants)
        }
        return result
    }
    
    /// Check if this node has children
    public var hasChildren: Bool {
        return !children.isEmpty
    }
    
    /// Get the depth of this node in the tree (root = 0)
    public var depth: Int {
        var depth = 0
        var current = parent
        while current != nil {
            depth += 1
            current = current?.parent
        }
        return depth
    }
}

/// Tree structure for outline elements
public struct OutlineTree {
    public let root: OutlineTreeNode?
    private let nodeMap: [String: OutlineTreeNode]
    
    public init(from outline: OutlineList) {
        var nodeMap: [String: OutlineTreeNode] = [:]
        var rootNode: OutlineTreeNode?
        
        // Create nodes for all elements
        for element in outline {
            let node = OutlineTreeNode(element: element)
            nodeMap[element.id] = node
            
            // Find the root (level 1 or first element)
            if element.level == 1 && rootNode == nil {
                rootNode = node
            }
        }
        
        // Build the tree structure based on parent-child relationships
        for element in outline {
            guard let node = nodeMap[element.id] else { continue }
            
            if let parentId = element.parentId, let parentNode = nodeMap[parentId] {
                parentNode.addChild(node)
            }
        }
        
        self.root = rootNode
        self.nodeMap = nodeMap
    }
    
    /// Find a node by element ID
    public func node(for elementId: String) -> OutlineTreeNode? {
        return nodeMap[elementId]
    }
    
    /// Get all nodes in the tree (flattened)
    public var allNodes: [OutlineTreeNode] {
        guard let root = root else { return [] }
        return [root] + root.descendants
    }
    
    /// Get all leaf nodes (nodes without children)
    public var leafNodes: [OutlineTreeNode] {
        return allNodes.filter { !$0.hasChildren }
    }
}

extension OutlineList {
    /// Create a tree structure from the outline list
    public func tree() -> OutlineTree {
        return OutlineTree(from: self)
    }
}
