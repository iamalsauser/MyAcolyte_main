import SwiftUI

struct MyNotesView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @Binding var showFullScreen: Bool
    @Binding var selectedDocument: DocumentItem?
    
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var selectedCategory: NoteCategory? = nil
    @State private var showingSortOptions: Bool = false
    @State private var currentSort: NoteSortOption = .lastModified
    
    enum NoteCategory: String, CaseIterable, Identifiable {
        case all = "All Notes"
        case anatomy = "Anatomy"
        case physiology = "Physiology"
        case pathology = "Pathology"
        case pharmacology = "Pharmacology"
        case clinical = "Clinical"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .all: return "note.text"
            case .anatomy: return "figure.stand"
            case .physiology: return "heart"
            case .pathology: return "allergens"
            case .pharmacology: return "pills"
            case .clinical: return "stethoscope"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .gray
            case .anatomy: return .blue
            case .physiology: return .red
            case .pathology: return .purple
            case .pharmacology: return .green
            case .clinical: return .orange
            }
        }
    }
    
    enum NoteSortOption: String, CaseIterable {
        case lastModified = "Last Modified"
        case alphabetical = "Alphabetical"
        case created = "Date Created"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 12) {
                // Title and Create button
                HStack {
                    Text("My Notes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.createNewNote()
                        
                        // Access the created note
                        if let document = viewModel.currentDocument {
                            selectedDocument = document
                            showFullScreen = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Note")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                // Search bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search notes", text: $searchText)
                            .foregroundColor(.primary)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Sort options
                    Menu {
                        ForEach(NoteSortOption.allCases, id: \.self) { option in
                            Button(action: {
                                currentSort = option
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    if currentSort == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(NoteCategory.allCases) { category in
                        NoteCategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                withAnimation {
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.secondarySystemBackground))
            
            Divider()
            
            // Notes list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredNotes) { note in
                        NoteCard(
                            note: note,
                            category: getCategoryForNote(note),
                            onTap: {
                                selectedDocument = DocumentItem(id: note.id, title: note.name)
                                showFullScreen = true
                            }
                        )
                    }
                    
                    if filteredNotes.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            if !searchText.isEmpty {
                                Text("No results found for \"\(searchText)\"")
                                    .font(.headline)
                            } else if selectedCategory != nil {
                                Text("No notes in category \(selectedCategory?.rawValue ?? "")")
                                    .font(.headline)
                            } else {
                                Text("No notes yet")
                                    .font(.headline)
                                
                                Button(action: {
                                    viewModel.createNewNote()
                                    
                                    if let document = viewModel.currentDocument {
                                        selectedDocument = document
                                        showFullScreen = true
                                    }
                                }) {
                                    Text("Create your first note")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 12)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding()
                .padding(.bottom, 100) // Add extra padding at bottom for tab bar
            }
        }
        .onAppear {
            viewModel.loadFileSystem()
        }
        .fullScreenCover(item: $selectedDocument) { document in
            if let item = viewModel.fileSystem.first(where: { $0.id == document.id }) {
                if item.fileType == .note {
                    // Use our enhanced note editor instead of the original one
                    EnhancedNoteEditorView(noteId: item.id, viewModel: viewModel)
                } else {
                    Text("Error: Document Not Found")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Get only note items from file system
    private var notes: [FileSystemItem] {
        return viewModel.fileSystem.filter { $0.type == .file && $0.fileType == .note }
    }
    
    // Apply filters and sorting
    private var filteredNotes: [FileSystemItem] {
        var result = notes
        
        // Apply category filter if selected
        if let category = selectedCategory, category != .all {
            result = result.filter { noteItem in
                getCategoryForNote(noteItem) == category
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { note in
                note.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply sorting
        switch currentSort {
        case .lastModified:
            result.sort { $0.dateModified > $1.dateModified }
        case .alphabetical:
            result.sort { $0.name < $1.name }
        case .created:
            result.sort { $0.dateCreated > $1.dateCreated }
        }
        
        return result
    }
    
    // Determine note category based on name
    private func getCategoryForNote(_ note: FileSystemItem) -> NoteCategory {
        let name = note.name.lowercased()
        
        if name.contains("anatomy") {
            return .anatomy
        } else if name.contains("physiology") || name.contains("heart") || name.contains("lung") {
            return .physiology
        } else if name.contains("pathology") || name.contains("disease") {
            return .pathology
        } else if name.contains("drug") || name.contains("medication") || name.contains("pharmac") {
            return .pharmacology
        } else if name.contains("patient") || name.contains("clinical") || name.contains("case") {
            return .clinical
        } else {
            return .all
        }
    }
}

// MARK: - Supporting Views

struct NoteCategoryButton: View {
    let category: MyNotesView.NoteCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                
                Text(category.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? category.color.opacity(0.2) : Color(.tertiarySystemBackground))
            .foregroundColor(isSelected ? category.color : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct NoteCard: View {
    let note: FileSystemItem
    let category: MyNotesView.NoteCategory
    let onTap: () -> Void
    
    @State private var notePreview: String = ""
    @ObservedObject var viewModel = FileSystemViewModel()
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Title and category
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.name.replacingOccurrences(of: ".notes", with: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                                .foregroundColor(category.color)
                            
                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundColor(category.color)
                        }
                    }
                    
                    Spacer()
                    
                    // Date
                    Text(formattedDate(note.dateModified))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Preview of note content
                if !notePreview.isEmpty {
                    Text(notePreview)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
                
                // Stats row
                HStack(spacing: 16) {
                    // Word count
                    StatBadge(
                        icon: "textformat.size",
                        value: "\(wordCount(notePreview)) words"
                    )
                    
                    // FlashCard count
                    StatBadge(
                        icon: "rectangle.on.rectangle",
                        value: "\(Int.random(in: 0...5)) cards" // Mock data for demo
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Load note content for preview
            if let content = viewModel.getNoteById(id: note.id) {
                notePreview = content.prefix(200).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    
    // Helper functions
    private func formattedDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today, \(formatTime(date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(formatTime(date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func wordCount(_ text: String) -> Int {
        return text.split(separator: " ").count
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(4)
    }
}
