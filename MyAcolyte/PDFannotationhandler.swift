import Foundation
import PDFKit
import PencilKit
import UIKit

class PDFAnnotationHandler {
    func savePDFWithAnnotations(pdfUrl: URL, canvasView: PKCanvasView) {
        guard let document = PDFDocument(url: pdfUrl) else {
            print("❌ Error: Could not create PDF document from URL")
            return
        }
        
        guard let pdfPage = document.page(at: 0) else {
            print("❌ Error: Could not get page from PDF document")
            return
        }

        // Convert PKCanvasView drawing to an image
        let annotationImage = getImageFromCanvas(canvasView: canvasView)

        // Get PDF page bounds
        let pdfBounds = pdfPage.bounds(for: .mediaBox)

        // Create and add image annotation
        let annotation = PDFImageAnnotation(bounds: pdfBounds, image: annotationImage)
        pdfPage.addAnnotation(annotation)

        // Save modified PDF
        if let data = document.dataRepresentation() {
            do {
                try data.write(to: pdfUrl)
                print("✅ Annotated PDF saved successfully.")
            } catch {
                print("❌ Failed to save annotated PDF: \(error)")
            }
        }
    }

    // Convert PKCanvasView drawing to UIImage
    private func getImageFromCanvas(canvasView: PKCanvasView) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: canvasView.bounds)
        return renderer.image { context in
            canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        }
    }
}
