import SwiftUI
import PDFKit
import PencilKit

struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)

        // PDF View
        let pdfView = PDFView(frame: containerView.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical // Changed for better navigation
        pdfView.usePageViewController(true)

        if let document = PDFDocument(url: url) {
            print("✅ Successfully loaded PDF in PDFView") // Debugging
            pdfView.document = document
        } else {
            print("❌ Failed to load PDF in PDFView") // Debugging
        }

        // PencilKit Canvas View
        canvasView.frame = pdfView.bounds
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .default

        // Add both views
        containerView.addSubview(pdfView)
        containerView.addSubview(canvasView)

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let pdfView = uiView.subviews.first(where: { $0 is PDFView }) as? PDFView else {
            print("❌ PDFView not found in updateUIView")
            return
        }

        if let document = PDFDocument(url: url) {
            print("🔄 Reloading PDF in updateUIView") // Debugging
            pdfView.document = document
        } else {
            print("❌ Failed to reload PDF in updateUIView") // Debugging
        }
    }
}
