import SwiftUI
import PencilKit
import UIKit

// MARK: - WhiteboardView Extension for Drawing Tools and Canvas Actions
extension WhiteboardView {
    // Update the active drawing tool
    func updateTool() {
        switch selectedTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: selectedThickness)
        case .marker:
            let markerColor = UIColor(selectedColor).withAlphaComponent(CGFloat(brushOpacity))
            canvasView.tool = PKInkingTool(.marker, color: markerColor, width: selectedThickness)
        case .pencil:
            canvasView.tool = PKInkingTool(.pencil, color: UIColor(selectedColor), width: selectedThickness)
        case .eraser:
            canvasView.tool = PKEraserTool(.vector, width: selectedThickness)
        case .lasso:
            canvasView.tool = PKLassoTool()
        case .shape, .text, .pen:
            // These tools require separate handling elsewhere
            break
        }
    }
    
    // Show shape selector and begin shape drawing
    func showShapeSelector() {
        // Present a UI to choose shapeType (line, rectangle, ellipse, etc.)
        // This method should update your View's state via a Binding or delegate
        // Example stub:
        shapeType = .line
        isDrawingShape = true
    }

    // Undo last action
    func undo() {
        guard let manager = canvasView.undoManager, manager.canUndo else { return }
        manager.undo()
        updateUndoRedoState()
    }
    
    // Redo last undone action
    func redo() {
        guard let manager = canvasView.undoManager, manager.canRedo else { return }
        manager.redo()
        updateUndoRedoState()
    }
    
    // Clear the canvas entirely
    func clearCanvas() {
        canvasView.drawing = PKDrawing()
        updateUndoRedoState()
    }
    
    // Reset zoom and pan to defaults
    func resetView() {
        currentZoomScale = 1.0
        currentPosition = .zero
    }
    
    // Save the whiteboard drawing and show notification
    func saveWhiteboard() {
        guard let id = whiteboardId else { return }
        viewModel.storageService.saveWhiteboard(id: id, drawing: canvasView.drawing)
        lastSaved = Date()
        withAnimation {
            showSavedNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSavedNotification = false
            }
        }
        NotificationManager.shared.sendNotification(
            title: "Whiteboard Saved",
            message: "Your whiteboard has been saved."
        )
    }
    
    // Update undo/redo button states based on the undo manager
    func updateUndoRedoState() {
        guard let manager = canvasView.undoManager else { return }
        isUndoDisabled = !manager.canUndo
        isRedoDisabled = !manager.canRedo
    }
}
