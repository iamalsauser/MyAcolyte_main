import Foundation
import SwiftUI

struct MyPDFView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var showingPDFViewer = false
    @State private var selectedDocument: DocumentItem?

    var body: some View {
        VStack(spacing: 0) {
            // Show Recent Files
            RecentFilesView(viewModel: viewModel, showFullScreen: $showingPDFViewer, selectedDocument: $selectedDocument)

            // Show path navigation if inside a folder
            if !viewModel.currentPath.isEmpty {
                PathView(viewModel: viewModel)
            }

            // Show Grid or List View
            if viewModel.viewMode == .grid {
                FileGridView(viewModel: viewModel, showFullScreen: $showingPDFViewer, selectedDocument: $selectedDocument)
            } else {
                FileListView(viewModel: viewModel, showFullScreen: $showingPDFViewer, selectedDocument: $selectedDocument)
            }
        }
        .navigationTitle("My PDF")
        .toolbar {
            FileSystemToolbar(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            DocumentPicker(showPicker: $viewModel.showDocumentPicker) { url in
                viewModel.importPDF(url: url)
            }
        }
        .fullScreenCover(item: $selectedDocument) { document in
            if let item = viewModel.fileSystem.first(where: { $0.id == document.id }) {
                if item.fileType == .pdf {
                    PDFViewerView(pdfId: item.id, viewModel: viewModel)
                } else {
                    Text("Error: Document Not Found")
                }
            }
        }
        .onAppear {
            viewModel.loadFileSystem()
        }
    }
}
