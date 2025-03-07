import PDFKit
import UIKit

class PDFImageAnnotation: PDFAnnotation {
    let image: UIImage

    init(bounds: CGRect, image: UIImage) {
        self.image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }

    required init?(coder: NSCoder) {
        return nil // PDFAnnotation does not support NSCoding, so we return nil
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        UIGraphicsPushContext(context)
        image.draw(in: bounds)
        UIGraphicsPopContext()
    }
}
