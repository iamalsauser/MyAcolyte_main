import Foundation
import PDFKit
import PencilKit
import UIKit

class PDFAnnotationHandler {
    func savePDFWithAnnotations(pdfUrl: URL, canvasView: PKCanvasView) {
        guard let document = PDFDocument(url: pdfUrl) else { return }
        guard let pdfPage = document.page(at: 0) else { return }

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
                print("Annotated PDF saved successfully.")
            } catch {
                print("Failed to save annotated PDF: \(error)")
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




    // Create an appearance stream for the annotation
    private func createAppearanceStream(image: UIImage, bounds: CGRect) -> PDFAnnotation {
        let annotation = PDFAnnotation(bounds: bounds, forType: .stamp, withProperties: nil)
        let imageView = UIImageView(image: image)
        imageView.frame = bounds

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let renderedImage = renderer.image { context in
            imageView.layer.render(in: context.cgContext)
        }

        annotation.setValue(renderedImage, forAnnotationKey: .appearanceState)
        return annotation
    }
    
//    class PDFImageAnnotation: PDFAnnotation {
//        let image: UIImage
//        
//        init(bounds: CGRect, image: UIImage) {
//            self.image = image
//            super.init(bounds: bounds, forType: .stamp, withProperties: nil)
//        }
//        
//        required init?(coder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//        
//        override func draw(with box: PDFDisplayBox, in context: CGContext) {
//            UIGraphicsPushContext(context)
//            image.draw(in: bounds)
//            UIGraphicsPopContext()
//        }
//    }

