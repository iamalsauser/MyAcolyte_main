import SwiftUI
import PencilKit
import UIKit

struct WhiteboardView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State  var canvasView = PKCanvasView()
    @State  var selectedColor: Color = .black
    @State  var selectedThickness: CGFloat = 2.0
    @State  var isErasing: Bool = false
    @State  var whiteboardId: String?
    @State  var showingTools: Bool = true
    @State  var showingTemplateSelector: Bool = false
    @State  var showingExportOptions: Bool = false
    @State  var showingColorPicker: Bool = false
    @State  var customColor: Color = .black
    @State  var selectedTool: DrawingTool = .pen
    @State  var showingGrid: Bool = false
    @State  var gridType: GridType = .lines
    @State  var currentBackgroundColor: Color = .white
    @State  var showingSaveAlert: Bool = false
    @State  var documentTitle: String = "New Whiteboard"
    @State  var showingToolsPanel: Bool = true
    @State  var toolsPanelPosition: ToolPanelPosition = .bottom
    @State  var activeColorPalette: [Color] = [.black, .blue, .red, .green, .orange, .purple]
    @State  var showingLayersPanel: Bool = false
    @State  var currentZoomScale: CGFloat = 1.0
    @State  var currentPosition: CGSize = .zero
    @Environment(\.presentationMode) var presentationMode
    
    // New state variables for enhanced tools
    @State   var brushOpacity: Double = 1.0
    @State   var brushBlendMode: PKInkingTool.InkType = .pen
    @State   var shapeType: ShapeType = .line
    @State   var isDrawingShape: Bool = false
    @State   var shapeStartPoint: CGPoint?
    @State   var shapeEndPoint: CGPoint?
    @State   var isUndoDisabled: Bool = true
    @State   var isRedoDisabled: Bool = true
    @State   var selectedTextFont: String = "Helvetica"
    @State   var showingTextInputSheet: Bool = false
    @State   var textInput: String = ""
    @State   var lastSaved: Date? = nil
    @State  var showSavedNotification: Bool = false
    
    enum ToolPanelPosition {
        case left, right, top, bottom
    }
    
    var body: some View {
        ZStack {
            // Background color
            currentBackgroundColor
                .ignoresSafeArea()
            
            // Grid overlay
            if showingGrid {
                GridBackground(type: gridType)
                    .ignoresSafeArea()
            }
            
            // Canvas
            CanvasViewRepresentable(canvasView: $canvasView)
                .ignoresSafeArea()
                .scaleEffect(currentZoomScale)
                .offset(currentPosition)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / currentZoomScale
                            currentZoomScale *= delta
                            currentZoomScale = min(max(currentZoomScale, 0.5), 3.0)
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if selectedTool == .pen {
                                currentPosition = CGSize(
                                    width: currentPosition.width + value.translation.width,
                                    height: currentPosition.height + value.translation.height
                                )
                            }
                        }
                )
            
            // Shape drawing overlay
            if isDrawingShape,
               let start = shapeStartPoint,
               let end = shapeEndPoint {
                ShapeOverlay(
                    startPoint: start,
                    endPoint: end,
                    shapeType: shapeType,
                    color: selectedColor,
                    lineWidth: selectedThickness
                )
                .ignoresSafeArea()
            }
            
            // Modern floating toolbar
            if showingTools {
                VStack {
                    // Top toolbar
                    HStack {
                        // Back button
                        Button(action: {
                            saveWhiteboard()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        // Title with edit button
                        Button(action: {
                            showingSaveAlert = true
                        }) {
                            HStack {
                                Text(documentTitle)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Actions menu
                        Menu {
                            Button(action: {
                                withAnimation {
                                    showingGrid.toggle()
                                    if !showingGrid {
                                        gridType = .none
                                    } else {
                                        gridType = .lines
                                    }
                                }
                            }) {
                                Label(
                                    showingGrid ? "Hide Grid" : "Show Grid",
                                    systemImage: "grid"
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingTemplateSelector = true
                            }) {
                                Label("Templates", systemImage: "doc.on.doc")
                            }
                            
                            Button(action: {
                                showingExportOptions = true
                            }) {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                withAnimation {
                                    resetView()
                                }
                            }) {
                                Label("Reset View", systemImage: "arrow.counterclockwise")
                            }
                            
                            // Background color submenu
                            Menu("Background Color") {
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
                            
                            Divider()
                            
                            Button(action: {
                                saveWhiteboard()
                            }) {
                                Label("Save", systemImage: "arrow.down.doc")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    // Bottom toolbar with modern design
                    VStack(spacing: 16) {
                        // Color palette with active colors
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(activeColorPalette, id: \.self) { color in
                                    ModernColorButton(
                                        color: color,
                                        isSelected: selectedColor == color,
                                        action: {
                                            selectedColor = color
                                            updateTool()
                                        }
                                    )
                                }
                                
                                // Custom color button
                                Button(action: {
                                    showingColorPicker = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                            .background(Circle().fill(Color.white.opacity(0.2)))
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(height: 40)
                        
                        // Modern tools grid
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 70), spacing: 10)
                        ], spacing: 10) {
                            // Pen tool
                            ModernToolButton(
                                icon: "pencil.tip",
                                name: "Pen",
                                isSelected: selectedTool == .pen && !isErasing,
                                action: {
                                    selectedTool = .pen
                                    isErasing = false
                                    updateTool()
                                }
                            )
                            
                            // Marker tool
                            ModernToolButton(
                                icon: "highlighter",
                                name: "Marker",
                                isSelected: selectedTool == .marker && !isErasing,
                                action: {
                                    selectedTool = .marker
                                    isErasing = false
                                    updateTool()
                                }
                            )
                            
                            // Pencil tool
                            ModernToolButton(
                                icon: "pencil",
                                name: "Pencil",
                                isSelected: selectedTool == .pencil && !isErasing,
                                action: {
                                    selectedTool = .pencil
                                    isErasing = false
                                    updateTool()
                                }
                            )
                            
                            // Eraser tool
                            ModernToolButton(
                                icon: "eraser",
                                name: "Eraser",
                                isSelected: isErasing,
                                action: {
                                    selectedTool = .eraser
                                    isErasing = true
                                    updateTool()
                                }
                            )
                            
                            // Shapes tool
                            ModernToolButton(
                                icon: shapeType.iconName,
                                name: "Shape",
                                isSelected: selectedTool == .shape,
                                action: {
                                    selectedTool = .shape
                                    isDrawingShape = true
                                    isErasing = false
                                    showShapeSelector()
                                }
                            )
                            
                            // Text tool
                            ModernToolButton(
                                icon: "text.cursor",
                                name: "Text",
                                isSelected: selectedTool == .text,
                                action: {
                                    selectedTool = .text
                                    isErasing = false
                                    showingTextInputSheet = true
                                }
                            )
                            
                            // Pan tool
                            ModernToolButton(
                                icon: "hand.draw",
                                name: "Pan",
                                isSelected: selectedTool == .pen,
                                action: {
                                    selectedTool = .pen
                                    isErasing = false
                                }
                            )
                            
                            // Lasso tool
                            ModernToolButton(
                                icon: "lasso",
                                name: "Select",
                                isSelected: selectedTool == .lasso,
                                action: {
                                    selectedTool = .lasso
                                    isErasing = false
                                    updateTool()
                                }
                            )
                        }
                        .padding(.horizontal)
                        
                        // Thickness slider with undo/redo
                        HStack {
                            // Thickness indicator
                            Circle()
                                .fill(selectedTool == .eraser ? Color.gray : selectedColor)
                                .frame(width: min(selectedThickness * 2, 24), height: min(selectedThickness * 2, 24))
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                                )
                            
                            // Size slider
                            Slider(value: $selectedThickness, in: 1...30, step: 1)
                                .accentColor(.white)
                                .frame(width: 100)
                                .onChange(of: selectedThickness) { _, _ in
                                    updateTool()
                                }
                            
                            Spacer()
                            
                            // Undo button
                            Button(action: undo) {
                                Image(systemName: "arrow.uturn.backward")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(isUndoDisabled ? Color.gray.opacity(0.3) : Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .disabled(isUndoDisabled)
                            
                            // Redo button
                            Button(action: redo) {
                                Image(systemName: "arrow.uturn.forward")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(isRedoDisabled ? Color.gray.opacity(0.3) : Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .disabled(isRedoDisabled)
                            
                            // Clear canvas
                            Button(action: {
                                clearCanvas()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.red.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(20)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -5)
                }
            } else {
                // Minimal toolbar when tools are hidden
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation {
                                showingTools = true
                            }
                        }) {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 3)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Save button
                        Button(action: {
                            saveWhiteboard()
                        }) {
                            Image(systemName: "arrow.down.doc")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 3)
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            
            // Last saved notification
            if showSavedNotification {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Whiteboard saved")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(20)
                            .padding(.trailing)
                            .padding(.bottom, showingTools ? 100 : 20)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }}
