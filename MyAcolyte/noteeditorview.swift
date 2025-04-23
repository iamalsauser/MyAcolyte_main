import SwiftUI
import Combine
import UniformTypeIdentifiers

struct EnhancedNoteEditorView: View {
    let noteId: String
    @ObservedObject var viewModel: FileSystemViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Note content state
    @State private var noteContent: String = ""
    @State private var noteTitle: String = ""
    @State private var originalContent: String = ""
    @State private var hasUnsavedChanges: Bool = false
    @State private var lastSaved: Date?
    
    // UI control states
    @State private var selectedTab: Int = 0
    @State private var showingFormatting: Bool = false
    @State private var showingDiscardAlert: Bool = false
    @State private var showingImagePicker: Bool = false
    @State private var showingStudyTools: Bool = false
    @State private var showingMedicalSymbols: Bool = false
    @State private var showingExportOptions: Bool = false
    @State private var showingFlashcardCreator: Bool = false
    
    // Formatting states
    @State private var fontSize: CGFloat = 16
    @State private var isItalic: Bool = false
    @State private var isBold: Bool = false
    @State private var textColor: Color = .primary
    @State private var selectedHeadingLevel: Int = 0 // 0 = normal, 1-3 = heading levels
    
    // Statistics
    @State private var wordCount: Int = 0
    @State private var characterCount: Int = 0
    
    // Flashcard states
    @State private var flashcards: [Flashcard] = []
    @State private var currentFlashcardFront: String = ""
    @State private var currentFlashcardBack: String = ""
    
    // Timer for automatic word count
    let wordCountTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    // Tab items for the note editor
    enum TabItem: String, CaseIterable {
        case edit = "Edit"
        case preview = "Preview"
        case flashcards = "Flashcards"
        case stats = "Stats"
        
        var icon: String {
            switch self {
            case .edit: return "pencil"
            case .preview: return "eye"
            case .flashcards: return "rectangle.on.rectangle"
            case .stats: return "chart.bar"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Note title field
                HStack {
                    TextField("Title", text: $noteTitle)
                        .font(.system(size: 20, weight: .bold))
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .onChange(of: noteTitle) { _, _ in
                            hasUnsavedChanges = true
                        }
                    
                    if hasUnsavedChanges {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .padding(.trailing, 16)
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                
                Divider()
                
                // Tab bar for different note modes
                HStack {
                    ForEach(Array(TabItem.allCases.enumerated()), id: \.offset) { index, tab in
                        Button(action: {
                            selectedTab = index
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedTab == index ? .green : .gray)
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedTab == index ? .green : .gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedTab == index ? Color.green.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(UIColor.secondarySystemBackground))
                
                Divider()
                
                // Formatting toolbar (when showing)
                if showingFormatting && selectedTab == 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            // Font size controls
                            HStack(spacing: 5) {
                                Button(action: {
                                    if fontSize > 12 {
                                        fontSize -= 1
                                    }
                                }) {
                                    Image(systemName: "textformat.size.smaller")
                                        .foregroundColor(.primary)
                                }
                                
                                Text("\(Int(fontSize))")
                                    .font(.system(size: 14))
                                    .frame(width: 24)
                                
                                Button(action: {
                                    if fontSize < 28 {
                                        fontSize += 1
                                    }
                                }) {
                                    Image(systemName: "textformat.size.larger")
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                            
                            Divider()
                                .frame(height: 24)
                            
                            // Heading level picker
                            Menu {
                                Button(action: { selectedHeadingLevel = 0 }) {
                                    Label("Normal Text", systemImage: "text.alignleft")
                                        .foregroundColor(selectedHeadingLevel == 0 ? .green : .primary)
                                }
                                
                                Button(action: { selectedHeadingLevel = 1 }) {
                                    Label("Heading 1", systemImage: "h.square")
                                        .foregroundColor(selectedHeadingLevel == 1 ? .green : .primary)
                                }
                                
                                Button(action: { selectedHeadingLevel = 2 }) {
                                    Label("Heading 2", systemImage: "h.square.on.square")
                                        .foregroundColor(selectedHeadingLevel == 2 ? .green : .primary)
                                }
                                
                                Button(action: { selectedHeadingLevel = 3 }) {
                                    Label("Heading 3", systemImage: "h.square.on.square.fill")
                                        .foregroundColor(selectedHeadingLevel == 3 ? .green : .primary)
                                }
                                
                                Button(action: {
                                    insertText("## Study Note\n\n")
                                }) {
                                    Label("Study Note Block", systemImage: "book")
                                }
                                
                                Button(action: {
                                    insertText("## Important\n\n")
                                }) {
                                    Label("Important Block", systemImage: "exclamationmark.triangle")
                                }
                            } label: {
                                Image(systemName: "text.append")
                                    .foregroundColor(.primary)
                                    .padding(5)
                            }
                            
                            // Text style controls
                            Button(action: { isBold.toggle() }) {
                                Image(systemName: "bold")
                                    .foregroundColor(isBold ? .green : .primary)
                                    .padding(5)
                                    .background(isBold ? Color.green.opacity(0.1) : Color.clear)
                                    .cornerRadius(5)
                            }
                            
                            Button(action: { isItalic.toggle() }) {
                                Image(systemName: "italic")
                                    .foregroundColor(isItalic ? .green : .primary)
                                    .padding(5)
                                    .background(isItalic ? Color.green.opacity(0.1) : Color.clear)
                                    .cornerRadius(5)
                            }
                            
                            Divider()
                                .frame(height: 24)
                            
                            // Text color controls
                            ForEach([Color.primary, Color.blue, Color.red, Color.green, Color.orange], id: \.self) { color in
                                Button(action: { textColor = color }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: textColor == color ? 2 : 0)
                                                .padding(1)
                                        )
                                }
                            }
                            
                            Divider()
                                .frame(height: 24)
                            
                            // Lists and checkboxes
                            Button(action: {
                                // Insert checkbox
                                insertText("- [ ] ")
                            }) {
                                Image(systemName: "checklist")
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: {
                                // Insert bullet
                                insertText("• ")
                            }) {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: {
                                // Insert numbered list
                                insertText("1. ")
                            }) {
                                Image(systemName: "list.number")
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    
                    Divider()
                }
                
                // Medical symbols palette (when showing)
                if showingMedicalSymbols && selectedTab == 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(medicalSymbols, id: \.self) { symbol in
                                Button(action: {
                                    insertText(symbol)
                                }) {
                                    Text(symbol)
                                        .font(.system(size: 18))
                                        .padding(8)
                                        .background(Color(UIColor.tertiarySystemBackground))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    
                    Divider()
                }
                
                // Main content area based on selected tab
                TabView(selection: $selectedTab) {
                    // Tab 0: Editor
                    editorTab
                        .tag(0)
                    
                    // Tab 1: Preview
                    previewTab
                        .tag(1)
                    
                    // Tab 2: Flashcards
                    flashcardsTab
                        .tag(2)
                    
                    // Tab 3: Statistics
                    statsTab
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Study tools sheet (when showing)
                if showingStudyTools {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Study Tools")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                StudyToolButton(title: "Flashcard", systemImage: "rectangle.on.rectangle") {
                                    showingFlashcardCreator = true
                                }
                                
                                StudyToolButton(title: "Highlight", systemImage: "highlighter") {
                                    insertText("**[Highlight]** ")
                                }
                                
                                StudyToolButton(title: "Definition", systemImage: "text.book.closed") {
                                    insertText("\n**Definition:** \n")
                                }
                                
                                StudyToolButton(title: "Key Concept", systemImage: "lightbulb") {
                                    insertText("\n**Key Concept:** \n")
                                }
                                
                                StudyToolButton(title: "Reference", systemImage: "link") {
                                    insertText("\n**Reference:** [](url)\n")
                                }
                                
                                StudyToolButton(title: "Mnemonic", systemImage: "brain") {
                                    insertText("\n**Mnemonic:** \n")
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showingStudyTools = false
                            }) {
                                Text("Close")
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if hasUnsavedChanges {
                            saveNote()
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingDiscardAlert = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        if selectedTab == 0 {
                            // Editing tools (only show in Edit tab)
                            Button(action: {
                                withAnimation {
                                    showingFormatting.toggle()
                                    if showingFormatting {
                                        showingMedicalSymbols = false
                                    }
                                }
                            }) {
                                Image(systemName: "textformat")
                                    .foregroundColor(showingFormatting ? .green : .primary)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    showingMedicalSymbols.toggle()
                                    if showingMedicalSymbols {
                                        showingFormatting = false
                                    }
                                }
                            }) {
                                Image(systemName: "pills")
                                    .foregroundColor(showingMedicalSymbols ? .green : .primary)
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Image(systemName: "photo")
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    showingStudyTools.toggle()
                                }
                            }) {
                                Label("Study Tools", systemImage: "lightbulb")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        } else {
                            // Show different tools when not in edit mode
                            Spacer()
                            
                            if selectedTab == 2 {
                                // Flashcard actions
                                Button(action: {
                                    showingFlashcardCreator = true
                                }) {
                                    Label("Add Flashcard", systemImage: "plus")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                            } else {
                                Button(action: {
                                    showingExportOptions = true
                                }) {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Always show save button
                        Button(action: {
                            saveNote()
                        }) {
                            Image(systemName: "arrow.down.doc")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .onAppear {
                loadNote()
                updateCounts()
            }
            .onReceive(wordCountTimer) { _ in
                updateCounts()
                
                // Auto-save every minute if there are changes
                if hasUnsavedChanges && (lastSaved == nil || Date().timeIntervalSince(lastSaved!) > 60) {
                    saveNote()
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Save", role: .none) {
                    saveNote()
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. What would you like to do?")
            }
            .sheet(isPresented: $showingImagePicker) {
                // Image picker would be implemented here
                Text("Image Picker")
                    .font(.headline)
                    .padding()
            }
            .sheet(isPresented: $showingFlashcardCreator) {
                flashcardCreatorView
            }
            .sheet(isPresented: $showingExportOptions) {
                exportOptionsView
            }
        }
    }
    
    // MARK: - Tab Views
    
    private var editorTab: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $noteContent)
                .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: .default))
                .if(isItalic) { view in
                    view.italic()
                }
                .foregroundColor(textColor)
                .padding(.horizontal, 8)
                .onChange(of: noteContent) { _, _ in
                    hasUnsavedChanges = true
                    updateCounts()
                }
            
            // Word and character count
            HStack {
                Spacer()
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(UIColor.systemBackground).opacity(0.8))
                    .cornerRadius(5)
                    .padding(8)
            }
        }
    }
    
    private var previewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(noteTitle)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 8)
                
                // This is a simplified preview - in a real app, you would render
                // the markdown or formatted text properly
                Text(noteContent)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
    
    private var flashcardsTab: some View {
        VStack {
            if flashcards.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Flashcards Created")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Tap 'Add Flashcard' to create your first study card from this note.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingFlashcardCreator = true
                    }) {
                        Text("Create Flashcard")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(Color.green)
                                .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(flashcards) { card in
                            FlashcardView(card: card)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var statsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary stats
                HStack(spacing: 20) {
                    StatCard(title: "Words", value: "\(wordCount)")
                    StatCard(title: "Characters", value: "\(characterCount)")
                    StatCard(title: "Flashcards", value: "\(flashcards.count)")
                }
                .padding(.horizontal)
                
                Divider()
                
                // Reading time estimate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated Reading Time")
                        .font(.headline)
                    
                    HStack {
                        let readingTime = max(1, wordCount / 200)
                        Text("\(readingTime) min")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Based on 200 words")
                            Text("per minute")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Word frequency
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Used Words")
                        .font(.headline)
                    
                    if wordCount > 0 {
                        let topWords = calculateTopWords()
                        ForEach(topWords.prefix(5), id: \.key) { word, count in
                            HStack {
                                Text(word)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("No content to analyze")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Last edited info
                if let lastSaved = lastSaved {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Saved")
                            .font(.headline)
                        
                        Text("\(lastSaved.formatted(date: .complete, time: .shortened))")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Sheets & Dialogs
    
    private var flashcardCreatorView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create a New Flashcard")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Front (Question)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $currentFlashcardFront)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Back (Answer)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $currentFlashcardBack)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    // Create flashcard
                    if !currentFlashcardFront.isEmpty && !currentFlashcardBack.isEmpty {
                        let newCard = Flashcard(
                            id: UUID().uuidString,
                            front: currentFlashcardFront,
                            back: currentFlashcardBack
                        )
                        flashcards.append(newCard)
                        currentFlashcardFront = ""
                        currentFlashcardBack = ""
                        showingFlashcardCreator = false
                        
                        // Mark changes as unsaved to ensure flashcards are saved with the note
                        hasUnsavedChanges = true
                    }
                }) {
                    Text("Create Flashcard")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (!currentFlashcardFront.isEmpty && !currentFlashcardBack.isEmpty) ?
                                Color.green : Color.gray
                        )
                        .cornerRadius(10)
                }
                .disabled(currentFlashcardFront.isEmpty || currentFlashcardBack.isEmpty)
            }
            .padding()
            .navigationBarTitle("New Flashcard", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    currentFlashcardFront = ""
                    currentFlashcardBack = ""
                    showingFlashcardCreator = false
                }
            )
        }
    }
    
    private var exportOptionsView: some View {
        NavigationView {
            List {
                Button(action: {
                    // Export as PDF (would implement in real app)
                    showingExportOptions = false
                }) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.red)
                        Text("Export as PDF")
                    }
                }
                
                Button(action: {
                    // Export as Markdown (would implement in real app)
                    showingExportOptions = false
                }) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                            .foregroundColor(.blue)
                        Text("Export as Markdown")
                    }
                }
                
                Button(action: {
                    // Share (would implement in real app)
                    let activityVC = UIActivityViewController(
                        activityItems: [noteTitle, noteContent],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityVC, animated: true)
                    }
                    
                    showingExportOptions = false
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.green)
                        Text("Share")
                    }
                }
                
                if !flashcards.isEmpty {
                    Button(action: {
                        // Export flashcards (would implement in real app)
                        showingExportOptions = false
                    }) {
                        HStack {
                            Image(systemName: "rectangle.on.rectangle")
                                .foregroundColor(.orange)
                        Text("Export Flashcards")
                        }
                    }
                }
            }
            .navigationBarTitle("Export Options", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showingExportOptions = false
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateCounts() {
        wordCount = noteContent.split(separator: " ").count
        characterCount = noteContent.count
    }
    
    private func loadNote() {
        if let content = viewModel.getNoteById(id: noteId) {
            noteContent = content
            originalContent = content
            
            // Extract title from file item
            if let noteItem = viewModel.fileSystem.first(where: { $0.id == noteId }) {
                noteTitle = noteItem.name.replacingOccurrences(of: ".notes", with: "")
            }
            
            // Load flashcards (in a real app, these would be stored with the note)
            loadFlashcards()
        }
        
        // Set initial last saved time to now
        lastSaved = Date()
    }
    
    private func saveNote() {
        // Save content
        viewModel.storageService.saveNote(id: noteId, content: noteContent)
        
        // Save flashcards (in a real app, you'd store these properly)
        saveFlashcards()
        
        // Update file item's name if title changed
        if let index = viewModel.fileSystem.firstIndex(where: { $0.id == noteId }) {
            let newName = noteTitle.hasSuffix(".notes") ? noteTitle : "\(noteTitle).notes"
            if viewModel.fileSystem[index].name != newName {
                viewModel.fileSystem[index].name = newName
                viewModel.fileSystem[index].dateModified = Date()
                viewModel.saveFileSystem()
            }
        }
        
        lastSaved = Date()
        hasUnsavedChanges = false
        
        // Show notification
        NotificationManager.shared.sendNotification(
            title: "Note Saved",
            message: "Your note '\(noteTitle)' has been saved."
        )
    }
    
    private func loadFlashcards() {
        // In a real app, you would load flashcards from storage
        // For now, we'll create some sample flashcards if none exist
        if flashcards.isEmpty && noteTitle.contains("Anatomy") {
            flashcards = [
                Flashcard(id: "1", front: "What are the four types of tissues in the human body?", back: "Epithelial, Connective, Muscle, and Nervous tissues"),
                Flashcard(id: "2", front: "Which bone is the longest in the human body?", back: "The femur (thigh bone)"),
                Flashcard(id: "3", front: "Name the chambers of the heart", back: "Right atrium, right ventricle, left atrium, left ventricle")
            ]
        }
    }
    
    private func saveFlashcards() {
        // In a real app, you would save the flashcards to persistent storage
        // This is a placeholder for that functionality
        print("Saved \(flashcards.count) flashcards")
    }
    
    private func insertText(_ text: String) {
        noteContent.append(text)
        hasUnsavedChanges = true
    }
    
    private func calculateTopWords() -> [(key: String, value: Int)] {
        let words = noteContent.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 3 }
        
        var wordCounts: [String: Int] = [:]
        
        for word in words {
            wordCounts[word, default: 0] += 1
        }
        
        return wordCounts.sorted { $0.value > $1.value }
    }
}

// MARK: - Supporting Structures

struct Flashcard: Identifiable, Codable {
    let id: String
    let front: String
    let back: String
    var lastReviewed: Date? = nil
    var confidenceLevel: Int = 0 // 0-5 scale
}

// MARK: - Supporting Views

struct StudyToolButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 60)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct FlashcardView: View {
    let card: Flashcard
    @State private var isShowingAnswer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Card content
            ZStack {
                // Front
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Question")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text(card.front)
                        .font(.headline)
                        .lineLimit(nil)
                        .padding(.vertical)
                    
                    if !isShowingAnswer {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    isShowingAnswer.toggle()
                                }
                            }) {
                                Text("Show Answer")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .opacity(isShowingAnswer ? 0 : 1)
                
                // Back
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("Answer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text(card.back)
                        .font(.headline)
                        .lineLimit(nil)
                        .padding(.vertical)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                isShowingAnswer.toggle()
                            }
                        }) {
                            Text("Show Question")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .opacity(isShowingAnswer ? 1 : 0)
            }
            .frame(minHeight: 150)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Confidence buttons (only show when answer is visible)
            if isShowingAnswer {
                HStack {
                    Text("Rate your confidence:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    ForEach(1...3, id: \.self) { level in
                        Button(action: {
                            // In a real app, you would save this confidence level
                            isShowingAnswer = false
                        }) {
                            Text("\(level)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(
                                    level == 1 ? Color.red :
                                        level == 2 ? Color.orange : Color.green
                                )
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// Array of medical symbols for the symbol palette
let medicalSymbols = [
    "♡", "❤️", "☤", "⚕️", "⚚", "†", "℞", "℃", "μ", "α", "β", "γ", "δ",
    "Δ", "σ", "π", "Ω", "∞", "±", "≈", "≠", "≤", "≥", "÷", "×", "→"
]

// View extension for applying modifiers conditionally
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Extension to apply rounded corners to specific corners only
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
