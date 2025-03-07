//
//  noteeditorview.swift
//  MyAcolyte
//
//  Created by admin17 on 07/03/25.
//

import Foundation
import SwiftUI

struct NoteEditorView: View {
    let noteId: String
    @State private var noteContent: String = ""
    @ObservedObject var viewModel: FileSystemViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            TextEditor(text: $noteContent)
                .padding()
                .navigationTitle("Edit Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            // Save note content
                            viewModel.storageService.saveNote(id: noteId, content: noteContent)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .onAppear {
                    // Load note content
                    if let content = viewModel.getNoteById(id: noteId) {
                        noteContent = content
                    }
                }
        }
    }
}
