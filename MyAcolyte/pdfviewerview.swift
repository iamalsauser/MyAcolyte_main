import SwiftUI
import PDFKit
import PencilKit

struct PDFViewerView: View {
    let pdfId: String
    @ObservedObject var viewModel: FileSystemViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isAnnotating = false
    @State private var canvasView = PKCanvasView()

    var body: some View {
        NavigationView {
            ZStack {
                if let pdfUrl = viewModel.getPdfById(id: pdfId) {
                    Text("📄 Loading PDF from: \(pdfUrl.lastPathComponent)") // Debugging
                                           .foregroundColor(.green) // Debugging line

                    PDFKitRepresentedView(url: pdfUrl, canvasView: $canvasView)
                } else {
                    Text("PDF not found")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("PDF Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAnnotating.toggle()
                    }) {
                        Image(systemName: isAnnotating ? "pencil.slash" : "pencil")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveAnnotatedPDF()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
        }
    }
    
    func saveAnnotatedPDF() {
        if let pdfUrl = viewModel.getPdfById(id: pdfId) {
            PDFAnnotationHandler().savePDFWithAnnotations(pdfUrl: pdfUrl, canvasView: canvasView)
        }
    }
}
