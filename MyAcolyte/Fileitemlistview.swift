import Foundation
import SwiftUI

struct FileItemListView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    let item: FileSystemItem
    @State private var newName = ""
    @State private var showingPDFViewer = false
    @State private var showingNoteEditor = false
    
    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            
            // Main content
            HStack(spacing: 16) {
                // Selection indicator or file type icon
                ZStack {
                    Circle()
                        .fill(item.type == .folder ? Color.yellow.opacity(0.2) :
                              item.fileType == .pdf ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if viewModel.selectionMode {
                        Image(systemName: viewModel.selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(viewModel.selectedItems.contains(item.id) ? .blue : .gray)
                    } else {
                        FileIcon(item: item, size: 25)
                    }
                }
                .padding(.leading, 12)
                
                // File information
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.editingItem == item.id {
                        TextField("Name", text: $newName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.headline)
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
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    if !viewModel.selectionMode && viewModel.editingItem == nil {
                        HStack {
                            if item.type == .file && item.fileType == .pdf {
                                Text("PDF Document")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if item.type == .file && item.fileType == .note {
                                Text("Note")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Folder")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(item.dateModified.formatted(.dateTime.month().day().year()))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                if !viewModel.selectionMode && viewModel.editingItem == nil {
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.editingItem = item.id
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: {
                            viewModel.editingItem = item.id
                            viewModel.deleteItems()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        if item.type == .folder {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                    .padding(.trailing, 12)
                }
            }
            .frame(height: 70)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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
            if viewModel.getPdfById(id: item.id) != nil {
                PDFViewerView(pdfId: item.id, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            NoteEditorView(noteId: item.id, viewModel: viewModel)
        }
    }
    
    private func openFile(item: FileSystemItem) {
        if item.fileType == .pdf {
            if let _ = viewModel.getPdfById(id: item.id) {
                // Set the current document in the ViewModel
                viewModel.currentDocument = DocumentItem(id: item.id, title: item.name)
                
                // Or use the local state approach
                showingPDFViewer = true
            }
        } else if item.fileType == .note {
            if let _ = viewModel.getNoteById(id: item.id) {
                // Set the current document in the ViewModel
                viewModel.currentDocument = DocumentItem(id: item.id, title: item.name)
                
                // Or use the local state approach
                showingNoteEditor = true
            }
        }
    }
}
