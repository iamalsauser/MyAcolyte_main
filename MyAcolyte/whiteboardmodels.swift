// WhiteboardModels.swift
import SwiftUI

enum DrawingTool {
    case pen, marker, pencil, eraser, shape, lasso, text
    
    var iconName: String {
        switch self {
        case .pen: return "pencil.tip"
        case .marker: return "highlighter"
        case .pencil: return "pencil"
        case .eraser: return "eraser"
        case .shape: return "square.on.circle"
        case .lasso: return "lasso"
        case .text: return "text.cursor"
        }
    }
    
    var displayName: String {
        switch self {
        case .pen: return "Pen"
        case .marker: return "Marker"
        case .pencil: return "Pencil"
        case .eraser: return "Eraser"
        case .shape: return "Shape"
        case .lasso: return "Lasso"
        case .text: return "Text"
        }
    }
}

enum ShapeType {
    case line, rectangle, oval, arrow
    
    var iconName: String {
        switch self {
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .oval: return "oval"
        case .arrow: return "arrow.right"
        }
    }
    
    var displayName: String {
        switch self {
        case .line: return "Line"
        case .rectangle: return "Rectangle"
        case .oval: return "Oval"
        case .arrow: return "Arrow"
        }
    }
}

enum GridType {
    case lines, dots, none
}

// Extension to check if a color is bright
extension Color {
    func isBright() -> Bool {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness >= 0.7
    }
}
