// WhiteboardToolbars.swift
import SwiftUI

// Top toolbar with controls
struct TopToolbar: View {
    @Binding var showingGrid: Bool
    @Binding var showingExportOptions: Bool
    @Binding var showingTemplateSelector: Bool
    let cycleGridType: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            ToolButton(
                systemName: "square.grid.3x3",
                isSelected: showingGrid
            ) {
                cycleGridType()
            }
            
            ToolButton(
                systemName: "square.and.arrow.up",
                isSelected: false
            ) {
                showingExportOptions = true
            }
            
            ToolButton(
                systemName: "doc.on.doc",
                isSelected: false
            ) {
                showingTemplateSelector = true
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// Bottom toolbar with drawing tools
struct BottomToolbar: View {
    @Binding var selectedTool: DrawingTool
    @Binding var selectedColor: Color
    @Binding var selectedThickness: CGFloat
    @Binding var isErasing: Bool
    @Binding var brushOpacity: Double
    @Binding var customColor: Color
    @Binding var showingColorPicker: Bool
    @Binding var shapeType: ShapeType
    @Binding var isDrawingShape: Bool
    
    let updateTool: () -> Void
    let undo: () -> Void
    let redo: () -> Void
    let clearCanvas: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Color palette
            ColorPaletteView(
                selectedColor: $selectedColor,
                customColor: $customColor,
                showingColorPicker: $showingColorPicker,
                updateTool: updateTool
            )
            
            // Tools
            ToolsRow(
                selectedTool: $selectedTool,
                isErasing: $isErasing,
                isDrawingShape: $isDrawingShape,
                updateTool: updateTool
            )
            
            // Thickness slider and controls
            ThicknessControlsRow(
                selectedTool: selectedTool,
                selectedColor: selectedColor,
                selectedThickness: $selectedThickness,
                updateTool: updateTool,
                undo: undo,
                redo: redo,
                clearCanvas: clearCanvas
            )
            
            // Sub-tools row (only shown for specific tools)
            if selectedTool == .shape {
                ShapeToolsRow(shapeType: $shapeType)
            } else if selectedTool == .marker {
                OpacitySlider(brushOpacity: $brushOpacity, updateTool: updateTool)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: -2)
        )
    }
}

// Background color menu
struct BackgroundColorMenu: View {
    @Binding var currentBackgroundColor: Color
    
    var body: some View {
        Menu("Background") {
            Button(action: { currentBackgroundColor = .white }) {
                Label("White", systemImage: "circle.fill")
                    .foregroundColor(.white)
            }
            
            Button(action: { currentBackgroundColor = Color(UIColor.systemGray6) }) {
                Label("Light Gray", systemImage: "circle.fill")
                    .foregroundColor(Color(UIColor.systemGray6))
            }
            
            Button(action: { currentBackgroundColor = Color(UIColor.systemYellow.withAlphaComponent(0.1)) }) {
                Label("Yellow Tint", systemImage: "circle.fill")
                    .foregroundColor(Color(UIColor.systemYellow.withAlphaComponent(0.3)))
            }
            
            Button(action: { currentBackgroundColor = Color(UIColor.black) }) {
                Label("Dark", systemImage: "circle.fill")
                    .foregroundColor(.black)
            }
        }
    }
}

// Minimized tools button
struct MinimizedToolsButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: action) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding()
                        .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.9)))
                        .shadow(color: Color.black.opacity(0.2), radius: 3)
                }
                .padding()
            }
        }
    }
}

// Color palette view
struct ColorPaletteView: View {
    @Binding var selectedColor: Color
    @Binding var customColor: Color
    @Binding var showingColorPicker: Bool
    let updateTool: () -> Void
    
    private let colors: [Color] = [
        .black, .blue, .red, .green, .yellow, .orange, .purple
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    ColorButton(color: color, isSelected: selectedColor == color) {
                        selectedColor = color
                        updateTool()
                    }
                }
                
                ColorButton(color: customColor, isSelected: selectedColor == customColor) {
                    selectedColor = customColor
                    updateTool()
                }
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                        .foregroundColor(customColor.isBright() ? .black : .white)
                )
                .onTapGesture {
                    showingColorPicker = true
                }
            }
            .padding(.horizontal)
        }
    }
}

// Tools row with drawing tool buttons
struct ToolsRow: View {
    @Binding var selectedTool: DrawingTool
    @Binding var isErasing: Bool
    @Binding var isDrawingShape: Bool
    let updateTool: () -> Void
    
    private let tools: [DrawingTool] = [.pen, .marker, .pencil, .eraser, .shape, .text]
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(tools, id: \.self) { tool in
                ToolButton(
                    systemName: tool.iconName,
                    isSelected: selectedTool == tool
                ) {
                    selectedTool = tool
                    isErasing = (tool == .eraser)
                    if tool == .shape {
                        isDrawingShape = true
                    } else {
                        isDrawingShape = false
                    }
                    updateTool()
                }
            }
        }
    }
}

// Thickness controls and other action buttons
struct ThicknessControlsRow: View {
    let selectedTool: DrawingTool
    let selectedColor: Color
    @Binding var selectedThickness: CGFloat
    let updateTool: () -> Void
    let undo: () -> Void
    let redo: () -> Void
    let clearCanvas: () -> Void
    
    var body: some View {
        HStack {
            // Size indicator circle
            Circle()
                .fill(selectedTool == .eraser ? Color.gray : selectedColor)
                .frame(width: min(selectedThickness * 2, 24), height: min(selectedThickness * 2, 24))
            
            // Size slider
            Slider(value: $selectedThickness, in: 1...30, step: 1)
                .frame(width: 150)
                .onChange(of: selectedThickness) { _, _ in
                    updateTool()
                }
            
            Spacer()
            
            Button(action: undo) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundColor(.primary)
                    .padding(8)
            }
            
            Button(action: redo) {
                Image(systemName: "arrow.uturn.forward")
                    .foregroundColor(.primary)
                    .padding(8)
            }
            
            Button(action: clearCanvas) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding(.horizontal)
    }
}

// Shape tools row
struct ShapeToolsRow: View {
    @Binding var shapeType: ShapeType
    
    private let shapes: [ShapeType] = [.line, .rectangle, .oval, .arrow]
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(shapes, id: \.self) { shape in
                ToolButton(
                    systemName: shape.iconName,
                    isSelected: shapeType == shape
                ) {
                    shapeType = shape
                }
            }
        }
        .padding(.top, -4)
    }
}

// Opacity slider for marker tool
struct OpacitySlider: View {
    @Binding var brushOpacity: Double
    let updateTool: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "sun.min")
                .foregroundColor(.secondary)
            
            Slider(value: $brushOpacity, in: 0.1...1.0, step: 0.1)
                .onChange(of: brushOpacity) { _, _ in
                    updateTool()
                }
            
            Image(systemName: "sun.max")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, -4)
    }
}

// Tool button
struct ToolButton: View {
    let systemName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(10)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color(UIColor.tertiarySystemBackground))
                )
        }
    }
}

// Color selection button
struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .shadow(color: Color.black.opacity(0.1), radius: 1)
                
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 30, height: 30)
                }
            }
        }
    }
}
