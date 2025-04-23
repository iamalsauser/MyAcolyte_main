import SwiftUI
import PDFKit
import PencilKit

struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL
    @Binding var canvasView: PKCanvasView
    @Binding var viewMode: PDFDisplayMode
    
    // Add binding for current page
    @Binding var currentPage: Int
    @Binding var totalPages: Int

    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFKitRepresentedView
        
        init(parent: PDFKitRepresentedView) {
            self.parent = parent
        }
        
        func pdfViewPageChanged(_ pdfView: PDFView) {
            if let currentPage = pdfView.currentPage,
               let document = pdfView.document {
                // Get the page index directly since it's not optional
                let pageIndex = document.index(for: currentPage)
                DispatchQueue.main.async {
                    self.parent.currentPage = pageIndex
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)

        let pdfView = PDFView(frame: containerView.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        pdfView.displayMode = viewMode
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(viewMode == .twoUp, withViewOptions: nil)
        pdfView.delegate = context.coordinator

        // Enhanced zooming
        pdfView.minScaleFactor = 1.0
        pdfView.maxScaleFactor = 6.0
        pdfView.scaleFactor = 1.0

        if let document = PDFDocument(url: url) {
            print("✅ Successfully loaded PDF in PDFView")
            pdfView.document = document
            DispatchQueue.main.async {
                self.totalPages = document.pageCount
            }
        } else {
            print("❌ Failed to load PDF in PDFView")
        }

        // Configure canvas for annotations
        canvasView.frame = pdfView.bounds
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .default
        
        // Create a tool picker for better control
        let toolPicker = PKToolPicker()
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        
        // Set initial tool
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2.0)

        containerView.addSubview(pdfView)
        containerView.addSubview(canvasView)

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let pdfView = uiView.subviews.first(where: { $0 is PDFView }) as? PDFView,
              let document = pdfView.document else {
            print("❌ PDFView or document not found in updateUIView")
            return
        }
        
        // Update view mode if changed
        if pdfView.displayMode != viewMode {
            print("🔄 Applying View Mode: \(viewMode == .singlePage ? "Single Page" : "Two Page")")
            pdfView.displayMode = viewMode
            pdfView.usePageViewController(viewMode == .twoUp, withViewOptions: nil)
        }
        
        // Update current page if navigation happened externally
        if let currentPageInDoc = document.page(at: currentPage),
           pdfView.currentPage != currentPageInDoc {
            pdfView.go(to: currentPageInDoc)
        }
        
        // Ensure canvas is properly sized
        if let canvasView = uiView.subviews.first(where: { $0 is PKCanvasView }) as? PKCanvasView {
            canvasView.frame = pdfView.bounds
        }
    }
}
