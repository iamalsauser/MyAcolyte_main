import Foundation
import SwiftUI

struct FileItemGridView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    let item: FileSystemItem
    @State private var newName = ""
    @State private var showingPDFViewer = false
    @State private var selectedPDFId: String? = nil

    var body: some View {
        VStack {
            ZStack {
                // Icon
                FileIcon(item: item, size: 60)
                    .padding(.top, 10)
                
                // Selection indicator
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
            
            Spacer()
            
            // Name/Rename field
            if viewModel.editingItem == item.id {
                TextField("Name", text: $newName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 120)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .onAppear {
                        if item.type == .file {
                            let nameWithoutExtension = item.name.replacingOccurrences(
                                of: item.fileType == .pdf ? ".pdf" : ".notes",
                                with: ""
                            )
                            newName = nameWithoutExtension
                        } else {
                            newName = item.name
                        }
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
        .frame(width: 140, height: 140)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .contextMenu {
            Button(action: {
                viewModel.editingItem = item.id
            }) {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(action: {
                viewModel.editingItem = item.id
                viewModel.deleteItems()
            }) {
                Label("Delete", systemImage: "trash")
            }
            
            if item.type == .folder {
                Button(action: {
                    viewModel.navigateToFolder(item: item)
                }) {
                    Label("Open", systemImage: "folder")
                }
            }
        }
        .onTapGesture {
            if viewModel.selectionMode {
                viewModel.toggleSelection(item: item)
            } else if viewModel.editingItem == nil {
                if item.type == .folder {
                    viewModel.navigateToFolder(item: item)
                } else if item.type == .file {
                    openFile(item: item)
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            if !viewModel.selectionMode {
                viewModel.toggleSelectionMode()
                viewModel.toggleSelection(item: item)
            }
        }
        .sheet(isPresented: $showingPDFViewer) {
            if let pdfId = selectedPDFId {
                PDFViewerView(pdfId: pdfId, viewModel: viewModel)
            }
        }
        .onChange(of: selectedPDFId) { oldValue, newValue in
            showingPDFViewer = (newValue != nil)
        }

    }
    
    private func openFile(item: FileSystemItem) {
        if item.fileType == .pdf {
            if let pdfUrl = viewModel.getPdfById(id: item.id) {
                print("PDF URL: \(pdfUrl.absoluteString)") // Debugging line
                selectedPDFId = item.id
                showingPDFViewer = true
            } else {
                print("❌ Error: PDF file not found!")
            }
        }
    }

}
