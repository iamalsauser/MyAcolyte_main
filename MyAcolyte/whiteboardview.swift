import SwiftUI
import PencilKit
import UIKit

struct WhiteboardView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State var canvasView = PKCanvasView()
    @State var selectedColor: Color = .black
    @State var selectedThickness: CGFloat = 2.0
    @State var isErasing: Bool = false
    @State var whiteboardId: String?
    @State var showingTools: Bool = true
    @State var showingTemplateSelector: Bool = false
    @State var showingExportOptions: Bool = false
    @State var showingColorPicker: Bool = false
    @State var customColor: Color = .black
    @State var selectedTool: DrawingTool = .pen
    @State var showingGrid: Bool = false
    @State var gridType: GridType = .lines
    @State var currentBackgroundColor: Color = .white
    @State var documentTitle: String = "New Whiteboard"
    @State var brushOpacity: Double = 1.0
    @State var shapeType: ShapeType = .line
    @State var isDrawingShape: Bool = false
    @State var shapeStartPoint: CGPoint?
    @State var shapeEndPoint: CGPoint?
    @State var isUndoDisabled: Bool = true
    @State var isRedoDisabled: Bool = true
    @State var lastSaved: Date? = nil
    @State var showSavedNotification: Bool = false
    @State  var currentZoomScale: CGFloat = 1.0
    @State  var currentPosition: CGSize = .zero
    @Environment(\.presentationMode) var presentationMode
    
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
                        Text(documentTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        
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
                        }
                        .padding(.trailing)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    // Bottom toolbar
                    VStack(spacing: 16) {
                        // Color palette with active colors
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach([Color.black, Color.blue, Color.red, Color.green, Color.orange, Color.purple], id: \.self) { color in
                                    ColorButton(
                                        color: color,
                                        isSelected: selectedColor == color,
                                        action: {
                                            selectedColor = color
                                            updateTool()
                                        }
                                    )
                                }
                                
                                // Add custom color button
                                Button(action: {
                                    showingColorPicker = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(height: 40)
                        
                        // Drawing tools
                        HStack(spacing: 20) {
                            ToolButton(
                                systemName: "pencil.tip",
                                isSelected: selectedTool == .pen && !isErasing,
                                action: {
                                    selectedTool = .pen
                                    isErasing = false
                                    updateTool()
                                }
                            )
                            
                            ToolButton(
                                systemName: "highlighter",
                                isSelected: selectedTool == .marker && !isErasing,
                                action: {
                                    selectedTool = .marker
                                    isErasing = false
                                    updateTool()
                                }
                            )
                            
                            ToolButton(
                                systemName: "pencil",
                                isSelected: selectedTool == .pencil && !isErasing,
                                action: {
                                    selectedTool = .pencil
                                    isErasing = false
                                    updateTool()
                                }
                            )
                            
                            ToolButton(
                                systemName: "eraser",
                                isSelected: isErasing,
                                action: {
                                    selectedTool = .eraser
                                    isErasing = true
                                    updateTool()
                                }
                            )
                            
                            ToolButton(
                                systemName: shapeType.iconName,
                                isSelected: selectedTool == .shape,
                                action: {
                                    selectedTool = .shape
                                    isDrawingShape = true
                                    isErasing = false
                                    showShapeSelector()
                                }
                            )
                            
                            // Show grid toggle
                            ToolButton(
                                systemName: "grid",
                                isSelected: showingGrid,
                                action: {
                                    withAnimation {
                                        showingGrid.toggle()
                                        if !showingGrid {
                                            gridType = .none
                                        } else {
                                            gridType = .lines
                                        }
                                    }
                                }
                            )
                        }
                        .padding(.horizontal)
                        
                        // Thickness slider with undo/redo
                        HStack {
                            // Thickness indicator
                            Circle()
                                .fill(selectedTool == .eraser ? Color.gray : selectedColor)
                                .frame(width: min(selectedThickness, 20), height: min(selectedThickness, 20))
                            
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
                            }
                            .disabled(isUndoDisabled)
                            
                            // Redo button
                            Button(action: redo) {
                                Image(systemName: "arrow.uturn.forward")
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            .disabled(isRedoDisabled)
                            
                            // Clear canvas
                            Button(action: {
                                clearCanvas()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(8)
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
                }
            } else {
                // Show tools button when tools are hidden
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
                        }
                        .padding()
                        
                        Spacer()
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
        .navigationBarHidden(true)
        .gesture(
            TapGesture()
                .onEnded { _ in
                    if !showingTools {
                        withAnimation {
                            showingTools = true
                        }
                    }
                }
        )
        .sheet(isPresented: $showingTemplateSelector) {
            TemplateSelector(canvasView: $canvasView)
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(canvasView: canvasView)
        }
        .sheet(isPresented: $showingColorPicker) {
            // Color picker sheet
            NavigationView {
                VStack {
                    ColorPicker("Select a color", selection: $customColor)
                        .padding()
                    
                    Button("Done") {
                        selectedColor = customColor
                        updateTool()
                        showingColorPicker = false
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .navigationTitle("Custom Color")
                .navigationBarItems(
                    trailing: Button("Cancel") {
                        showingColorPicker = false
                    }
                )
            }
        }
        .onAppear {
            // Initialize the whiteboard
            configureWhiteboard()
        }
    }
    
    func configureWhiteboard() {
        // Set whiteboard ID from viewModel if available
        if let currentDoc = viewModel.currentDocument {
            whiteboardId = currentDoc.id
            documentTitle = currentDoc.title
            
            // Load existing drawing if available
            if let drawing = viewModel.getWhiteboardById(id: currentDoc.id) {
                canvasView.drawing = drawing
            }
        } else {
            // Create a new whiteboard if none exists
            viewModel.createNewWhiteboard()
            if let newDoc = viewModel.currentDocument {
                whiteboardId = newDoc.id
                documentTitle = newDoc.title
            }
        }
        
        // Setup canvas
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = UIColor.clear
        updateTool()
    }
    
    //    func updateTool() {
    //        switch selectedTool {
    //        case .pen:
    //            canvasView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: selectedThickness)
    //        case .marker:
    //            let markerColor = UIColor(selectedColor).withAlphaComponent(CGFloat(brushOpacity))
    //            canvasView.tool = PKInkingTool(.marker, color: markerColor, width: selectedThickness)
    //        case .pencil:
    //            canvasView.tool = PKInkingTool(.pencil, color: UIColor(selectedColor), width: selectedThickness)
    //        case .eraser:
    //            canvasView.tool = PKEraserTool(.vector, width: selectedThickness)
    //        case .lasso:
    //            canvasView.tool = PKLassoTool()
    //        case .shape, .text:
    //            // These tools require separate handling
    //            break
    //        }
    //
    //        // Update undo/redo state
    //        updateUndoRedoState()
    //    }
    //
    //    func showShapeSelector() {
    //        // Present a UI to choose shapeType
    //        shapeType = .line
    //        isDrawingShape = true
    //    }
    //
    //    func undo() {
    //        guard let manager = canvasView.undoManager, manager.canUndo else { return }
    //        manager.undo()
    //        updateUndoRedoState()
    //    }
    //
    //    func redo() {
    //        guard let manager = canvasView.undoManager, manager.canRedo else { return }
    //        manager.redo()
    //        updateUndoRedoState()
    //    }
    //
    //    func clearCanvas() {
    //        canvasView.drawing = PKDrawing()
    //        updateUndoRedoState()
    //    }
    //
    //    func saveWhiteboard() {
    //        guard let id = whiteboardId else { return }
    //        viewModel.storageService.saveWhiteboard(id: id, drawing: canvasView.drawing)
    //        lastSaved = Date()
    //        withAnimation {
    //            showSavedNotification = true
    //        }
    //        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    //            withAnimation {
    //                showSavedNotification = false
    //            }
    //        }
    //        NotificationManager.shared.sendNotification(
    //            title: "Whiteboard Saved",
    //            message: "Your whiteboard has been saved."
    //        )
    //    }
    //
    //    func updateUndoRedoState() {
    //        guard let manager = canvasView.undoManager else { return }
    //        isUndoDisabled = !manager.canUndo
    //        isRedoDisabled = !manager.canRedo
    //    }
    //}
    //
    //// MARK: - Supporting Views
    //
    //struct ToolButton: View {
    //    let systemName: String
    //    let isSelected: Bool
    //    let action: () -> Void
    //
    //    var body: some View {
    //        Button(action: action) {
    //            Image(systemName: systemName)
    //                .font(.system(size: 16))
    //                .foregroundColor(isSelected ? .white : .gray)
    //                .padding(10)
    //                .background(
    //                    Circle()
    //                        .fill(isSelected ? Color.green : Color.clear)
    //                )
    //        }
    //    }
    //}
    //
    //struct ColorButton: View {
    //    let color: Color
    //    let isSelected: Bool
    //    let action: () -> Void
    //
    //    var body: some View {
    //        Button(action: action) {
    //            ZStack {
    //                Circle()
    //                    .fill(color)
    //                    .frame(width: 30, height: 30)
    //                    .shadow(color: Color.black.opacity(0.1), radius: 1)
    //
    //                if isSelected {
    //                    Circle()
    //                        .strokeBorder(Color.white, lineWidth: 2)
    //                        .frame(width: 30, height: 30)
    //                }
    //            }
    //        }
    //    }
    //}
}
