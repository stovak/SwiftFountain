# Changelog

All notable changes to SwiftFountain will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6] - 2025-01-04

### Added
- **Hierarchical Outline System**: Complete parent-child relationships between outline elements
- **Tree Data Structure**: New `OutlineTree` and `OutlineTreeNode` classes for hierarchical navigation
- **END Marker Detection**: Special handling for `## END CHAPTER` markers that don't participate in hierarchy
- **Scene Directive Enhancement**: Enhanced level 3 parsing with directive name extraction (e.g., `MUSIC:`, `SOUND:`)
- **Auto-generated Titles**: Level 1 headers automatically created from script names when missing
- **New Properties on OutlineElement**:
  - `parentId`: ID of parent element in hierarchy
  - `childIds`: Array of child element IDs
  - `isEndMarker`: Boolean indicating END chapter markers
  - `sceneDirective`: Extracted directive name for level 3 elements
  - `sceneDirectiveDescription`: Full description after colon for level 3 elements
- **New Methods on OutlineElement**:
  - `parent(from: OutlineList)`: Get parent element
  - `children(from: OutlineList)`: Get direct children
  - `descendants(from: OutlineList)`: Get all descendants
- **New Methods on OutlineList**:
  - `tree()`: Create hierarchical tree structure
- **New Methods on FountainScript**:
  - `extractOutlineTree()`: Convenience method to get tree structure
- **API Compatibility**: `elementType` property returns "outline" for compatibility with `FountainElement`

### Enhanced
- **Outline Level System**: Clarified level hierarchy:
  - Level 1: Main title (only one allowed, auto-generated if missing)
  - Level 2: Chapter-level headings (`##`) and END markers
  - Level 3: Scene directive headings (`###`) with directive name parsing
  - Level 4+: Scene headers and additional nested levels
- **JSON Output**: Enhanced outline JSON format includes parent-child relationships and new properties
- **Documentation**: Comprehensive README updates with tree usage examples and API documentation

### Fixed
- **Multiple Level 1 Headers**: Subsequent level 1 headers are now demoted to level 2 (chapter level)
- **Consistent Hierarchy**: Outline structure is now consistent across `.fountain`, `.textbundle`, and `.highland` formats

### Changed
- **OutlineElement Constructor**: Added new optional parameters for enhanced functionality (backwards compatible with defaults)
- **Outline Structure**: May include auto-generated level 1 title, potentially increasing element count by 1

### Tests
- **Comprehensive Test Suite**: New `OutlineExtensionTests` with extensive hierarchy validation
- **Functional Tests**: Cross-format testing across all fixture files (`.fountain`, `.textbundle`, `.highland`)
- **API Compatibility Tests**: Ensures `elementType` property works correctly
- **Tree Structure Tests**: Validates tree creation and navigation functionality

## [Previous Versions]
- Previous changelog entries would be documented here in future releases