import SwiftUI

struct DocumentLibraryView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var selectedTab: DocumentType = .all
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .newest
    @State private var showingDocumentPicker = false
    @State private var selectedDocument: DocumentItem?
    @State private var showFullScreen = false
    
    enum DocumentType: String, CaseIterable, Identifiable {
        case all = "All"
        case pdf = "PDFs"
        case notes = "Notes"
        case whiteboard = "Whiteboards"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .all: return "doc.fill"
            case .pdf: return "doc.text.fill"
            case .notes: return "note.text.fill"
            case .whiteboard: return "scribble"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .pdf: return .red
            case .notes: return .green
            case .whiteboard: return .purple
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case nameAsc = "Name (A-Z)"
        case nameDesc = "Name (Z-A)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and filters
            VStack(spacing: 12) {
                // Header with title and add button
                HStack {
                    Text("Document Library")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        // Show document type menu for adding content
                        showDocumentAddMenu()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search documents", text: $searchText)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                
                // Document type selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(DocumentType.allCases) { type in
                            TypeFilterButton(
                                type: type,
                                isSelected: selectedTab == type,
                                action: {
                                    withAnimation {
                                        selectedTab = type
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Sort and layout controls
                HStack {
                    Text("\(filteredDocuments.count) documents")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                sortOption = option
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Sort")
                                .font(.subheadline)
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Document grid
            ScrollView {
                if filteredDocuments.isEmpty {
                    emptyStateView
                } else {
                    documentsGrid
                }
            }
            
            // Floating action button for quick add
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        Button(action: {
                            viewModel.createNewNote()
                            if let document = viewModel.currentDocument {
                                selectedDocument = document
                                showFullScreen = true
                            }
                        }) {
                            Label("New Note", systemImage: "note.text.badge.plus")
                        }
                        
                        Button(action: {
                            viewModel.createNewWhiteboard()
                            if let document = viewModel.currentDocument {
                                selectedDocument = document
                                showFullScreen = true
                            }
                        }) {
                            Label("New Whiteboard", systemImage: "scribble")
                        }
                        
                        Button(action: {
                            showingDocumentPicker = true
                        }) {
                            Label("Import PDF", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Circle().fill(Color.green))
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(showPicker: $showingDocumentPicker) { url in
                viewModel.importPDF(url: url)
            }
        }
        .fullScreenCover(item: $selectedDocument) { document in
            if let item = viewModel.fileSystem.first(where: { $0.id == document.id }) {
                if item.type == .file {
                    if item.fileType == .pdf {
                        PDFViewerView(pdfId: item.id, viewModel: viewModel)
                    } else if item.fileType == .note {
                        EnhancedNoteEditorView(noteId: item.id, viewModel: viewModel)
                    }
                } else if item.type == .whiteboard {
                    WhiteboardView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            viewModel.loadFileSystem()
        }
    }
    
    // Documents grid layout
    private var documentsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(filteredDocuments) { document in
                DocumentCard(document: document, onTap: {
                    selectedDocument = DocumentItem(id: document.id, title: document.name)
                    showFullScreen = true
                })
            }
        }
        .padding()
        .padding(.bottom, 80) // Extra padding for the floating button
    }
    
    // Empty state
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedTab == .pdf ? "doc.text" :
                    selectedTab == .notes ? "note.text" :
                    selectedTab == .whiteboard ? "scribble" : "doc")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(getEmptyStateTitle())
                .font(.headline)
            
            Text(getEmptyStateMessage())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                addNewDocument()
            }) {
                Text("Add \(selectedTab == .all ? "Document" : selectedTab.rawValue.dropLast())")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Helper methods
    private func getEmptyStateTitle() -> String {
        if !searchText.isEmpty {
            return "No results found"
        }
        
        switch selectedTab {
        case .all: return "No documents found"
        case .pdf: return "No PDFs found"
        case .notes: return "No notes found"
        case .whiteboard: return "No whiteboards found"
        }
    }
    
    private func getEmptyStateMessage() -> String {
        if !searchText.isEmpty {
            return "Try different search terms or clear the search"
        }
        
        switch selectedTab {
        case .all: return "Add your first document using the + button"
        case .pdf: return "Import PDF documents to your library"
        case .notes: return "Create notes for your study sessions"
        case .whiteboard: return "Create whiteboards for visual studying"
        }
    }
    
    private func showDocumentAddMenu() {
        // Show a menu to add different document types
        // In a real app, this would show a popup or action sheet
    }
    
    private func addNewDocument() {
        switch selectedTab {
        case .pdf, .all:
            showingDocumentPicker = true
        case .notes:
            viewModel.createNewNote()
            if let document = viewModel.currentDocument {
                selectedDocument = document
                showFullScreen = true
            }
        case .whiteboard:
            viewModel.createNewWhiteboard()
            if let document = viewModel.currentDocument {
                selectedDocument = document
                showFullScreen = true
            }
        }
    }
    
    // Filtered and sorted documents
    private var filteredDocuments: [FileSystemItem] {
        var documents = viewModel.fileSystem.filter { item in
            switch selectedTab {
            case .all:
                return (item.type == .file || item.type == .whiteboard) && item.parentId == viewModel.currentFolder
            case .pdf:
                return item.type == .file && item.fileType == .pdf && item.parentId == viewModel.currentFolder
            case .notes:
                return item.type == .file && item.fileType == .note && item.parentId == viewModel.currentFolder
            case .whiteboard:
                return item.type == .whiteboard && item.parentId == viewModel.currentFolder
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            documents = documents.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        
        // Apply sorting
        switch sortOption {
        case .newest:
            documents.sort { $0.dateModified > $1.dateModified }
        case .oldest:
            documents.sort { $0.dateModified < $1.dateModified }
        case .nameAsc:
            documents.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDesc:
            documents.sort { $0.name.lowercased() > $1.name.lowercased() }
        }
        
        return documents
    }
}

// MARK: - Supporting Views

struct TypeFilterButton: View {
    let type: DocumentLibraryView.DocumentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                
                Text(type.rawValue)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? type.color.opacity(0.2) : Color(.tertiarySystemBackground))
            .foregroundColor(isSelected ? type.color : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct DocumentCard: View {
    let document: FileSystemItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon for the document type
                HStack {
                    Spacer()
                    
                    if document.type == .file {
                        if document.fileType == .pdf {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.red)
                        } else if document.fileType == .note {
                            Image(systemName: "note.text.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.green)
                        }
                    } else if document.type == .whiteboard {
                        Image(systemName: "scribble")
                            .font(.system(size: 36))
                            .foregroundColor(.purple)
                    }
                    
                    Spacer()
                }
                .padding(.top, 10)
                
                Spacer()
                
                // Document name and details
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name.replacingOccurrences(of: document.type == .file ?
                                                          (document.fileType == .pdf ? ".pdf" : ".notes") :
                                                          ".whiteboard", with: ""))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(formatDate(document.dateModified))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    // Document type tag
                    HStack {
                        if document.type == .file {
                            if document.fileType == .pdf {
                                TypeTag(text: "PDF", color: .red)
                            } else if document.fileType == .note {
                                TypeTag(text: "Note", color: .green)
                            }
                        } else if document.type == .whiteboard {
                            TypeTag(text: "Whiteboard", color: .purple)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(height: 160)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct TypeTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(4)
    }
}
