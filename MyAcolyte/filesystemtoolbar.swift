//
//  filesystemtoolbar.swift
//  MyAcolyte
//
//  Created by admin17 on 07/03/25.
//

import Foundation
import SwiftUI

struct FileSystemToolbar: ToolbarContent {
    @ObservedObject var viewModel: FileSystemViewModel
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if viewModel.selectionMode {
                Button(action: {
                    viewModel.deleteItems()
                }) {
                    Image(systemName: "trash")
                }
                
                Button(action: {
                    viewModel.toggleSelectionMode()
                }) {
                    Text("Cancel")
                }
            } else {
                Menu {
                    Button(action: {
                        viewModel.createFolder()
                    }) {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                    
                    Button(action: {
                        viewModel.createNewNote()
                    }) {
                        Label("New Note", systemImage: "note.text.badge.plus")
                    }
                    
                    Button(action: {
                        viewModel.showDocumentPicker = true
                    }) {
                        Label("Import PDF", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                
                Menu {
                    Picker("View", selection: $viewModel.viewMode) {
                        Label("Grid", systemImage: "square.grid.2x2")
                            .tag(FileSystemViewModel.ViewMode.grid)
                        
                        Label("List", systemImage: "list.bullet")
                            .tag(FileSystemViewModel.ViewMode.list)
                    }
                    
                    Menu {
                        ForEach(FileSystemViewModel.SortOrder.allCases, id: \.self) { order in
                            Button(action: {
                                viewModel.changeSortOrder(order)
                            }) {
                                HStack {
                                    Text(order.rawValue)
                                    if viewModel.sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Sort by", systemImage: "arrow.up.arrow.down")
                    }
                    
                    Button(action: {
                        viewModel.toggleSelectionMode()
                    }) {
                        Label("Select Items", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
