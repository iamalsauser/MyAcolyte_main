//
//  filesystemview.swift
//  MyAcolyte
//
//  Created by admin17 on 07/03/25.
//

//
//  FileSystemView.swift
//  MyAcolyte
//
//  Created by admin17 on 07/03/25.
//

import Foundation
import SwiftUI

struct FileSystemView: View {
    @StateObject private var viewModel = FileSystemViewModel()
    @State private var showingPDFViewer = false
    @State private var showingNoteEditor = false
    @State private var selectedFileId: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !viewModel.currentPath.isEmpty {
                    PathView(viewModel: viewModel)
                }
                
                if viewModel.viewMode == .grid {
                    // Grid View
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 140), spacing: 16)
                        ], spacing: 16) {
                            // New Folder button (if not in selection mode)
                            if !viewModel.selectionMode {
                                Button(action: {
                                    viewModel.createFolder()
                                }) {
                                    VStack {
                                        Image(systemName: "folder.badge.plus")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 60, height: 60)
                                            .foregroundColor(.blue)
                                            .padding(.top, 10)
                                        
                                        Spacer()
                                        
                                        Text("New Folder")
                                            .font(.system(size: 14))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .frame(maxWidth: 120)
                                            .foregroundColor(.primary)
                                            .padding(.bottom, 5)
                                    }
                                    .frame(width: 140, height: 140)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                                }
                            }
                            
                            // File items
                            ForEach(viewModel.getCurrentItems()) { item in
                                FileItemGridView(viewModel: viewModel, item: item)
                            }
                        }
                        .padding()
                    }
                } else {
                    // List View
                    List {
                        // New Folder button (if not in selection mode)
                        if !viewModel.selectionMode {
                            Button(action: {
                                viewModel.createFolder()
                            }) {
                                HStack {
                                    Image(systemName: "folder.badge.plus")
                                        .foregroundColor(.blue)
                                        .frame(width: 30, height: 30)
                                    
                                    Text("New Folder")
                                        .foregroundColor(.primary)
                                }
                            }
                            .frame(height: 50)
                        }
                        
                        // File items
                        ForEach(viewModel.getCurrentItems()) { item in
                            FileItemListView(viewModel: viewModel, item: item)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(viewModel.currentPath.isEmpty ? "Files" : viewModel.currentPath.last ?? "Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                FileSystemToolbar(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showDocumentPicker) {
                DocumentPicker(showPicker: $viewModel.showDocumentPicker) { url in
                    viewModel.importPDF(url: url)
                }
            }
            .sheet(item: $viewModel.currentDocument) { document in
                if let item = viewModel.fileSystem.first(where: { $0.id == document.id }) {
                    if item.fileType == .pdf {
                        PDFViewerView(pdfId: document.id, viewModel: viewModel)
                    } else if item.fileType == .note {
                        NoteEditorView(noteId: document.id, viewModel: viewModel)
                    }
                }
            }
            .onAppear {
                viewModel.loadFileSystem()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct DocumentItem: Identifiable {
    let id: String
    let title: String
}

struct FileSystemView_Previews: PreviewProvider {
    static var previews: some View {
        FileSystemView()
    }
}

