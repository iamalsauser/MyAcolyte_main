// WhiteboardView.swift
import SwiftUI
import PencilKit
import UIKit

struct WhiteboardView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var canvasView = PKCanvasView()
    @State private var selectedColor: Color = .black
    @State private var selectedThickness: CGFloat = 2.0
    @State private var isErasing: Bool = false
    @State private var whiteboardId: String?
    @State private var showingTools: Bool = true
    @State private var showingTemplateSelector: Bool = false
    @State private var showingExportOptions: Bool = false
    @State private var showingColorPicker: Bool = false
    @State private var customColor: Color = .black
    @State private var selectedTool: DrawingTool = .pen
    @State private var showingGrid: Bool = false
    @State private var gridType: GridType = .lines
    @State private var currentBackgroundColor: Color = .white
    @State private var showingSaveAlert: Bool = false
    @State private var documentTitle: String = "New Whiteboard"
    
    // New state variables for enhanced tools
    @State private var brushOpacity: Double = 1.0
    @State private var brushBlendMode: PKInkingTool.InkType = .pen
    @State private var shapeType: ShapeType = .line
    @State private var isDrawingShape: Bool = false
    @State private var shapeStartPoint: CGPoint?
    @State private var shapeEndPoint: CGPoint?
    
    var body: some View {
        NavigationView {
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
                
                // Tools Overlay
                if showingTools {
                    VStack {
                        // Top toolbar
                        TopToolbar(
                            showingGrid: $showingGrid,
                            showingExportOptions: $showingExportOptions,
                            showingTemplateSelector: $showingTemplateSelector,
                            cycleGridType: cycleGridType
                        )
                        
                        Spacer()
                        
                        // Bottom toolbar
                        BottomToolbar(
                            selectedTool: $selectedTool,
                            selectedColor: $selectedColor,
                            selectedThickness: $selectedThickness,
                            isErasing: $isErasing,
                            brushOpacity: $brushOpacity,
                            customColor: $customColor,
                            showingColorPicker: $showingColorPicker,
                            shapeType: $shapeType,
                            isDrawingShape: $isDrawingShape,
                            updateTool: updateTool,
                            undo: undo,
                            redo: redo,
                            clearCanvas: clearCanvas
                        )
                    }
                } else {
                    // Show a minimized toggle when tools are hidden
                    MinimizedToolsButton {
                        withAnimation {
                            showingTools = true
                        }
                    }
                }
            }
            .navigationTitle(documentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWhiteboard()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: {
                            createNewWhiteboard()
                        }) {
                            Label("New Whiteboard", systemImage: "plus")
                        }
                        
                        Button(action: {
                            showingSaveAlert = true
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        BackgroundColorMenu(currentBackgroundColor: $currentBackgroundColor)
                        
                        Button(action: {
                            withAnimation {
                                showingTools.toggle()
                            }
                        }) {
                            Label(showingTools ? "Hide Tools" : "Show Tools",
                                  systemImage: showingTools ? "chevron.down" : "chevron.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadWhiteboard()
            }
            .alert("Save Whiteboard", isPresented: $showingSaveAlert) {
                TextField("Title", text: $documentTitle)
                
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if let index = viewModel.fileSystem.firstIndex(where: { $0.id == whiteboardId }) {
                        let newName = documentTitle.hasSuffix(".whiteboard") ?
                            documentTitle : "\(documentTitle).whiteboard"
                        viewModel.fileSystem[index].name = newName
                        viewModel.saveFileSystem()
                    }
                    saveWhiteboard()
                }
            } message: {
                Text("Enter a name for your whiteboard")
            }
            .sheet(isPresented: $showingTemplateSelector) {
                TemplateSelector(canvasView: $canvasView)
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(canvasView: canvasView)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPicker("Select a color", selection: $customColor)
                    .padding()
                    .presentationDetents([.height(200)])
                    .onDisappear {
                        if selectedColor == customColor {
                            updateTool()
                        }
                    }
            }
            .onTapGesture { location in
                if isDrawingShape {
                    if shapeStartPoint == nil {
                        shapeStartPoint = location
                    } else if shapeEndPoint == nil {
                        shapeEndPoint = location
                        drawShape()
                        shapeStartPoint = nil
                        shapeEndPoint = nil
                    }
                }
            }
        }
    }
    
    private func updateTool() {
        switch selectedTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: selectedThickness)
        case .marker:
            // Create a new tool instance with the alpha component already set
            let markerColor = UIColor(selectedColor).withAlphaComponent(CGFloat(brushOpacity))
            canvasView.tool = PKInkingTool(.marker, color: markerColor, width: selectedThickness)
        case .pencil:
            canvasView.tool = PKInkingTool(.pencil, color: UIColor(selectedColor), width: selectedThickness)
        case .eraser:
            canvasView.tool = PKEraserTool(.vector, width: selectedThickness)
        case .lasso:
            canvasView.tool = PKLassoTool()
        case .text, .shape:
            // These tools are handled differently
            canvasView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: 0.1)
        }
    }
    
    private func drawShape() {
        guard let start = shapeStartPoint, let end = shapeEndPoint else { return }
        
        // Use PencilKit's native tools to draw the shape
        // Create a temporary PKDrawing and add it to the current drawing
        let inkingTool = PKInkingTool(.pen, color: UIColor(selectedColor), width: selectedThickness)
        let stroke: PKStroke
        
        switch shapeType {
        case .line:
            stroke = createStroke(from: [start, end], with: inkingTool)
        case .rectangle:
            let rect = CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            stroke = createRectangleStroke(rect: rect, with: inkingTool)
        case .oval:
            let rect = CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            stroke = createOvalStroke(rect: rect, with: inkingTool)
        case .arrow:
            let angle = atan2(end.y - start.y, end.x - start.x)
            let arrowLength = selectedThickness * 4
            let arrowAngle = CGFloat.pi / 6 // 30 degrees
            
            let arrowPoint1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )
            
            let arrowPoint2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )
            
            // Create main line and arrowhead as separate strokes
            let mainLine = createStroke(from: [start, end], with: inkingTool)
            let arrowHead1 = createStroke(from: [end, arrowPoint1], with: inkingTool)
            let arrowHead2 = createStroke(from: [end, arrowPoint2], with: inkingTool)
            
            // Add all three strokes to the drawing
            var newDrawing = canvasView.drawing
            newDrawing.strokes.append(mainLine)
            newDrawing.strokes.append(arrowHead1)
            newDrawing.strokes.append(arrowHead2)
            canvasView.drawing = newDrawing
            return
        }
        
        // Add the stroke to the drawing
        var newDrawing = canvasView.drawing
        newDrawing.strokes.append(stroke)
        canvasView.drawing = newDrawing
    }
    
    private func createStroke(from points: [CGPoint], with tool: PKInkingTool) -> PKStroke {
        // Create control points from the input points
        let controlPoints = points.map { point in
            PKStrokePoint(
                location: point,
                timeOffset: 0,
                size: CGSize(width: selectedThickness, height: selectedThickness),
                opacity: 1,
                force: 1,
                azimuth: 0,
                altitude: 0
            )
        }
        
        // Create a path from the control points
        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())
        
        // Create a stroke with the path and tool ink
        return PKStroke(ink: tool.ink, path: path)
    }
    
    private func createRectangleStroke(rect: CGRect, with tool: PKInkingTool) -> PKStroke {
        // Create points for the four corners of the rectangle
        let points = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.minY) // Close the shape
        ]
        
        return createStroke(from: points, with: tool)
    }
    
    private func createOvalStroke(rect: CGRect, with tool: PKInkingTool) -> PKStroke {
        // Approximate an oval with a series of points
        let count = 36
        var points: [CGPoint] = []
        
        for i in 0...count {
            let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(count)
            let x = rect.midX + rect.width / 2 * cos(angle)
            let y = rect.midY + rect.height / 2 * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return createStroke(from: points, with: tool)
    }
    
    private func cycleGridType() {
        if !showingGrid {
            showingGrid = true
            gridType = .lines
        } else if gridType == .lines {
            gridType = .dots
        } else if gridType == .dots {
            showingGrid = false
            gridType = .none
        }
    }
    
    private func undo() {
        if let manager = canvasView.undoManager, manager.canUndo {
            manager.undo()
        }
    }
    
    private func redo() {
        if let manager = canvasView.undoManager, manager.canRedo {
            manager.redo()
        }
    }
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
    
    private func saveWhiteboard() {
        if let id = whiteboardId {
            viewModel.storageService.saveWhiteboard(id: id, drawing: canvasView.drawing)
            NotificationManager.shared.sendNotification(
                title: "Whiteboard Saved",
                message: "Your whiteboard has been saved."
            )
        }
    }
    
    private func createNewWhiteboard() {
        let newId = UUID().uuidString
        let newWhiteboard = FileSystemItem(
            id: newId,
            name: "New Whiteboard.whiteboard",
            type: .whiteboard,
            fileType: nil,
            parentId: viewModel.currentFolder
        )
        viewModel.fileSystem.append(newWhiteboard)
        viewModel.saveFileSystem()
        whiteboardId = newId
        canvasView.drawing = PKDrawing()
        documentTitle = "New Whiteboard"
    }
    
    private func loadWhiteboard() {
        if let document = viewModel.currentDocument,
           let drawing = viewModel.storageService.getWhiteboardById(id: document.id) {
            whiteboardId = document.id
            canvasView.drawing = drawing
            documentTitle = document.title.replacingOccurrences(of: ".whiteboard", with: "")
        } else {
            createNewWhiteboard()
        }
        
        // Set initial tool
        updateTool()
    }
}
