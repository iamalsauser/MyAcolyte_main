import Foundation
import SwiftUI

struct FileItemGridView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    let item: FileSystemItem
    @State private var newName = ""
    @State private var showingPDFViewer = false
    @State private var showingWhiteboard = false
    @State private var selectedPDFId: String?

    var body: some View {
        VStack {
            iconAndSelectionView
            Spacer()
            nameView
        }
        .frame(width: 140, height: 140)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .contextMenu { contextMenuContent }
        .onTapGesture { handleTap() }
        .onLongPressGesture(minimumDuration: 0.5) { handleLongPress() }
        .fullScreenCover(isPresented: $showingPDFViewer) {
            if let pdfId = selectedPDFId {
                PDFViewerView(pdfId: pdfId, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingWhiteboard) {
            WhiteboardView(viewModel: viewModel)
        }
        .onChange(of: selectedPDFId) { _, newValue in
            showingPDFViewer = (newValue != nil)
        }
    }
    
    // MARK: - Sub-Views
    
    private var iconAndSelectionView: some View {
        ZStack {
            FileIcon(item: item, size: 60)
                .padding(.top, 10)
            
            if viewModel.selectionMode {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: viewModel.selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(viewModel.selectedItems.contains(item.id) ? .blue : .gray)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .padding(5)
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var nameView: some View {
        Group {
            if viewModel.editingItem == item.id {
                TextField("Name", text: $newName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 120)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .onAppear {
                        newName = initialNameForEditing()
                    }
                    .onSubmit {
                        viewModel.renameItem(id: item.id, newName: newName)
                    }
            } else {
                Text(item.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 120)
                    .foregroundColor(.primary)
                    .padding(.bottom, 5)
            }
        }
    }
    
    private var contextMenuContent: some View {
        Group {
            Button(action: { viewModel.editingItem = item.id }) {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(action: {
                viewModel.editingItem = item.id
                viewModel.deleteItems()
            }) {
                Label("Delete", systemImage: "trash")
            }
            
            if item.type == .folder {
                Button(action: { viewModel.navigateToFolder(item: item) }) {
                    Label("Open", systemImage: "folder")
                }
            }
            
            if item.type == .file && item.fileType == .pdf {
                Button(action: {
                    openPDF(item: item)
                }) {
                    Label("Open in Full Screen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func initialNameForEditing() -> String {
        if item.type == .file {
            let extensionToRemove = item.fileType == .pdf ? ".pdf" : ".notes"
            return item.name.replacingOccurrences(of: extensionToRemove, with: "")
        } else if item.type == .whiteboard {
            return item.name.replacingOccurrences(of: ".whiteboard", with: "")
        } else {
            return item.name
        }
    }
    
    private func handleTap() {
        if viewModel.selectionMode {
            viewModel.toggleSelection(item: item)
        } else if viewModel.editingItem == nil {
            if item.type == .folder {
                viewModel.navigateToFolder(item: item)
            } else {
                openFile(item: item)
            }
        }
    }
    
    private func handleLongPress() {
        if !viewModel.selectionMode {
            viewModel.toggleSelectionMode()
            viewModel.toggleSelection(item: item)
        }
    }
    
    private func openFile(item: FileSystemItem) {
        if item.type == .file && item.fileType == .pdf {
            openPDF(item: item)
        } else if item.type == .whiteboard {
            if viewModel.getWhiteboardById(id: item.id) != nil {
                viewModel.currentDocument = DocumentItem(id: item.id, title: item.name)
                showingWhiteboard = true
            } else {
                print("❌ Error: Whiteboard file not found!")
            }
        }
    }
    
    private func openPDF(item: FileSystemItem) {
        if viewModel.getPdfById(id: item.id) != nil {
            print("Opening PDF in full screen: \(item.id)")
            selectedPDFId = item.id
            viewModel.openFile(item) // Track in recent files
        } else {
            print("❌ Error: PDF file not found!")
        }
    }
}
