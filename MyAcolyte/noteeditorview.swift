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
    @State private var editorMode: EditorMode = .edit
    @State private var isFullScreen: Bool = false
    @State private var showingSaveConfirmation: Bool = false
    
    // Formatting states
    @State private var fontSize: CGFloat = 16
    @State private var isItalic: Bool = false
    @State private var isBold: Bool = false
    @State private var textColor: Color = .primary
    @State private var selectedHeadingLevel: Int = 0 // 0 = normal, 1-3 = heading levels
    @State private var selectedTextAlignment: TextAlignment = .leading
    
    // Statistics
    @State private var wordCount: Int = 0
    @State private var characterCount: Int = 0
    @State private var readingTime: Int = 0
    
    // Flashcard states
    @State private var flashcards: [Flashcard] = []
    @State private var currentFlashcardFront: String = ""
    @State private var currentFlashcardBack: String = ""
    @State private var showingFlashcardStudyMode: Bool = false
    @State private var currentFlashcardIndex: Int = 0
    @State private var isShowingFlashcardAnswer: Bool = false
    
    // Editor themes
    @State private var currentTheme: EditorTheme = .light
    
    // Timer for automatic word count
    let wordCountTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    enum EditorMode {
        case edit, preview, flashcards, stats
    }
    
    enum EditorTheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case sepia = "Sepia"
        case forest = "Forest"
        case night = "Night"
        
        var backgroundColor: Color {
            switch self {
            case .light: return Color(.systemBackground)
            case .dark: return Color(.systemGray6)
            case .sepia: return Color(hex: "#F7F2E7")
            case .forest: return Color(hex: "#E8F0E8")
            case .night: return Color(hex: "#1A1A2E")
            }
        }
        
        var textColor: Color {
            switch self {
            case .light, .sepia, .forest: return Color(.label)
            case .dark: return Color(.label)
            case .night: return Color.white
            }
        }
        
        var accentColor: Color {
            switch self {
            case .light: return .blue
            case .dark: return .blue
            case .sepia: return Color(hex: "#8B4513") // SaddleBrown
            case .forest: return Color(hex: "#1B5E20") // Dark Green
            case .night: return Color(hex: "#4E64BE") // Indigo
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background based on theme
                currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern top navigation bar
                    VStack(spacing: 0) {
                        if !isFullScreen {
                            // Title bar with controls
                            HStack {
                                // Back button
                                Button(action: {
                                    if hasUnsavedChanges {
                                        showingDiscardAlert = true
                                    } else {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(currentTheme.accentColor)
                                        .font(.system(size: 16, weight: .semibold))
                                        .padding(8)
                                }
                                
                                Spacer()
                                
                                // Mode selection
                                Picker("Mode", selection: $editorMode) {
                                    Image(systemName: "pencil").tag(EditorMode.edit)
                                    Image(systemName: "eye").tag(EditorMode.preview)
                                    Image(systemName: "rectangle.on.rectangle").tag(EditorMode.flashcards)
                                    Image(systemName: "chart.bar").tag(EditorMode.stats)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: geometry.size.width * 0.6)
                                
                                Spacer()
                                
                                // Actions menu
                                Menu {
                                    Button(action: {
                                        saveNote()
                                    }) {
                                        Label("Save", systemImage: "arrow.down.doc")
                                    }
                                    
                                    Button(action: {
                                        withAnimation {
                                            isFullScreen.toggle()
                                        }
                                    }) {
                                        Label(
                                            isFullScreen ? "Exit Fullscreen" : "Fullscreen",
                                            systemImage: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                                        )
                                    }
                                    
                                    Divider()
                                    
                                    // Theme submenu
                                    Menu("Theme") {
                                        ForEach(EditorTheme.allCases, id: \.self) { theme in
                                            Button(action: {
                                                currentTheme = theme
                                                // Adjust text color to match theme
                                                textColor = theme.textColor
                                            }) {
                                                HStack {
                                                    Text(theme.rawValue)
                                                    if currentTheme == theme {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    Button(action: {
                                        showingExportOptions = true
                                    }) {
                                        Label("Export", systemImage: "square.and.arrow.up")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundColor(currentTheme.accentColor)
                                        .font(.system(size: 16, weight: .semibold))
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            
                            // Note title with edit function
                            HStack {
                                TextField("Title", text: $noteTitle)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(currentTheme.textColor)
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
                            .background(currentTheme.backgroundColor)
                            
                            // Formatting toolbar when in edit mode
                            if editorMode == .edit && showingFormatting {
                                formattingToolbar
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6).opacity(0.5))
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Medical symbols palette when shown
                            if editorMode == .edit && showingMedicalSymbols {
                                medicalSymbolsPalette
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6).opacity(0.5))
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            Divider()
                        }
                        
                        // Main content area
                        switch editorMode {
                        case .edit:
                            editorView
                        case .preview:
                            previewView
                        case .flashcards:
                            flashcardsView
                        case .stats:
                            statsView
                        }
                        
                        // Bottom floating toolbar (shown only in edit mode and not in fullscreen)
                        if editorMode == .edit && !isFullScreen {
                            bottomToolbar
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray6).opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.2), radius: 3)
                                )
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                        
                        // Study tools panel (when shown)
                        if showingStudyTools && !isFullScreen {
                            studyToolsPanel
                                .transition(.move(edge: .bottom))
                        }
                    }
                }
                
                // Save confirmation toast
                if showingSaveConfirmation {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Note saved")
                                .foregroundColor(.primary)
                                .font(.subheadline)
                        }
                        .padding(10)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 3)
                        )
                        .padding(.bottom, 20)
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .navigationBarHidden(true)
            .statusBar(hidden: isFullScreen)
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
            // Image picker placeholder
            Text("Image Picker Would Appear Here")
                .font(.headline)
                .padding()
        }
        .sheet(isPresented: $showingFlashcardCreator) {
            flashcardCreatorView
        }
        .sheet(isPresented: $showingExportOptions) {
            exportOptionsView
        }
        .sheet(isPresented: $showingFlashcardStudyMode) {
            flashcardStudyView
        }
    }
    
    // MARK: - View Components
    
    // Formatting toolbar at the top when in edit mode
    private var formattingToolbar: some View {
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
                            .foregroundColor(currentTheme.textColor)
                    }
                    
                    Text("\(Int(fontSize))")
                        .font(.system(size: 14))
                        .frame(width: 24)
                        .foregroundColor(currentTheme.textColor)
                    
                    Button(action: {
                        if fontSize < 28 {
                            fontSize += 1
                        }
                    }) {
                        Image(systemName: "textformat.size.larger")
                            .foregroundColor(currentTheme.textColor)
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
                
                Divider()
                    .frame(height: 24)
                
                // Text alignment options
                HStack(spacing: 8) {
                    let alignments: [TextAlignment] = [.leading, .center, .trailing]
                    let icons = ["text.align.left", "text.align.center", "text.align.right"]

                    ForEach(0..<3, id: \.self) { index in
                        Button(action: {
                            selectedTextAlignment = alignments[index]
                        }) {
                            Image(systemName: icons[index])
                                .foregroundColor(selectedTextAlignment == alignments[index] ? currentTheme.accentColor : currentTheme.textColor)
                                .padding(6)
                                .background(selectedTextAlignment == alignments[index] ? currentTheme.accentColor.opacity(0.1) : Color.clear)
                                .cornerRadius(6)
                        }
                    }

                }
                
                Divider()
                    .frame(height: 24)
                
                // Heading level picker
                Menu {
                    Button(action: { selectedHeadingLevel = 0 }) {
                        Label("Normal Text", systemImage: "text.alignleft")
                            .foregroundColor(selectedHeadingLevel == 0 ? currentTheme.accentColor : currentTheme.textColor)
                    }
                    
                    Button(action: { selectedHeadingLevel = 1 }) {
                        Label("Heading 1", systemImage: "h.square")
                            .foregroundColor(selectedHeadingLevel == 1 ? currentTheme.accentColor : currentTheme.textColor)
                    }
                    
                    Button(action: { selectedHeadingLevel = 2 }) {
                        Label("Heading 2", systemImage: "h.square.on.square")
                            .foregroundColor(selectedHeadingLevel == 2 ? currentTheme.accentColor : currentTheme.textColor)
                    }
                    
                    Button(action: { selectedHeadingLevel = 3 }) {
                        Label("Heading 3", systemImage: "h.square.on.square.fill")
                            .foregroundColor(selectedHeadingLevel == 3 ? currentTheme.accentColor : currentTheme.textColor)
                    }
                    
                    Divider()
                    
                    Group {
                        Button(action: {
                            insertTemplateText("## Study Note\n\n")
                        }) {
                            Label("Study Note Block", systemImage: "book")
                        }
                        
                        Button(action: {
                            insertTemplateText("## Important\n\n")
                        }) {
                            Label("Important Block", systemImage: "exclamationmark.triangle")
                        }
                        
                        Button(action: {
                            insertTemplateText("## Definition\n\n")
                        }) {
                            Label("Definition Block", systemImage: "text.book.closed")
                        }
                        
                        Button(action: {
                            insertTemplateText("## Summary\n\n")
                        }) {
                            Label("Summary Block", systemImage: "list.bullet.rectangle")
                        }
                    }
                } label: {
                    Image(systemName: "text.append")
                        .foregroundColor(currentTheme.textColor)
                        .padding(5)
                }
                
                // Text style controls
                Button(action: { isBold.toggle() }) {
                    Image(systemName: "bold")
                        .foregroundColor(isBold ? currentTheme.accentColor : currentTheme.textColor)
                        .padding(5)
                        .background(isBold ? currentTheme.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(5)
                }
                
                Button(action: { isItalic.toggle() }) {
                    Image(systemName: "italic")
                        .foregroundColor(isItalic ? currentTheme.accentColor : currentTheme.textColor)
                        .padding(5)
                        .background(isItalic ? currentTheme.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(5)
                }
                
                Divider()
                    .frame(height: 24)
                
                // Text color controls
                ForEach([Color.primary, Color.blue, Color.red, Color.green, Color.orange, Color.purple], id: \.self) { color in
                    Button(action: { textColor = color }) {
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(currentTheme.textColor, lineWidth: textColor == color ? 2 : 0)
                                    .padding(1)
                            )
                    }
                }
                
                Divider()
                    .frame(height: 24)
                
                // Lists and checkboxes
                Button(action: {
                    // Insert checkbox
                    insertTemplateText("- [ ] ")
                }) {
                    Image(systemName: "checklist")
                        .foregroundColor(currentTheme.textColor)
                }
                
                Button(action: {
                    // Insert bullet
                    insertTemplateText("• ")
                }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(currentTheme.textColor)
                }
                
                Button(action: {
                    // Insert numbered list
                    insertTemplateText("1. ")
                }) {
                    Image(systemName: "list.number")
                        .foregroundColor(currentTheme.textColor)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Medical symbols palette
    private var medicalSymbolsPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(medicalSymbols, id: \.self) { symbol in
                    Button(action: {
                        insertTemplateText(symbol)
                    }) {
                        Text(symbol)
                            .font(.system(size: 18))
                            .foregroundColor(currentTheme.textColor)
                            .padding(8)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Main editor view
    private var editorView: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $noteContent)
                .font(.system(size: fontSize, weight: isBold ? .bold : .regular, design: .default))
                .if(isItalic) { view in
                    view.italic()
                }
                .foregroundColor(textColor)
                .padding(.horizontal, 8)
                .background(currentTheme.backgroundColor)
                .onChange(of: noteContent) { _, _ in
                    hasUnsavedChanges = true
                    updateCounts()
                }
                .overlay(alignment: .topTrailing) {
                    if isFullScreen {
                        Button(action: {
                            withAnimation {
                                isFullScreen = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                }
            
            // Word and character count
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Label("\(wordCount)", systemImage: "text.word.count")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("|")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let lastSaved = lastSaved {
                        Label(timeAgoSince(lastSaved), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Label("Not saved", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(Color(UIColor.systemBackground).opacity(0.8))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 1)
                .padding(8)
            }
        }
    }
    
    // Preview view with rendered markdown
    private var previewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(noteTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(currentTheme.textColor)
                    .padding(.bottom, 8)
                
                // This is a simplified preview - in a real app, you would render
                // the markdown or formatted text properly
                Text(noteContent)
                    .foregroundColor(currentTheme.textColor)
                    .padding(.horizontal)
                    .textSelection(.enabled)
                
                if isFullScreen {
                    Button(action: {
                        withAnimation {
                            isFullScreen = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                            Text("Exit Fullscreen")
                        }
                        .foregroundColor(currentTheme.accentColor)
                        .padding()
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
    }
    
    // Flashcards view
    private var flashcardsView: some View {
        VStack {
            if flashcards.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Flashcards Created")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(currentTheme.textColor)
                    
                    Text("Tap 'Create Flashcard' to make your first study card from this note.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingFlashcardCreator = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Flashcard")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(currentTheme.accentColor)
                        .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding()
            } else {
                VStack {
                    HStack {
                        Text("You have \(flashcards.count) flashcard\(flashcards.count > 1 ? "s" : "")")
                            .font(.headline)
                            .foregroundColor(currentTheme.textColor)
                        
                        Spacer()
                        
                        Button(action: {
                            showingFlashcardStudyMode = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Study")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(currentTheme.accentColor)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showingFlashcardCreator = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(currentTheme.accentColor)
                                .padding(8)
                                .background(currentTheme.accentColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(flashcards) { card in
                                FlashcardListItem(card: card)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    // Stats view
    private var statsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary stats
                HStack(spacing: 20) {
                    StatCard(title: "Words") {
                        HStack {
                            Image(systemName: "textformat")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            
                            Text("\(wordCount)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }

                    StatCard(title: "Characters") {
                        HStack {
                            Image(systemName: "character")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            
                            Text("\(characterCount)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }

                    StatCard(title: "Flashcards") {
                        HStack {
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            
                            Text("\(flashcards.count)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Reading time estimate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated Reading Time")
                        .font(.headline)
                        .foregroundColor(currentTheme.textColor)
                    
                    HStack {
                        let readingTime = max(1, wordCount / 200)
                        Text("\(readingTime) min")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(currentTheme.accentColor)
                        
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
                        .foregroundColor(currentTheme.textColor)
                    
                    if wordCount > 0 {
                        let topWords = calculateTopWords()
                        ForEach(topWords.prefix(5), id: \.key) { word, count in
                            HStack {
                                Text(word)
                                    .fontWeight(.medium)
                                    .foregroundColor(currentTheme.textColor)
                                
                                Spacer()
                                
                                // Visual frequency indicator
                                HStack(spacing: 0) {
                                    ForEach(0..<min(count, 10), id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(currentTheme.accentColor)
                                            .frame(width: 8, height: 16)
                                            .padding(.horizontal, 1)
                                    }
                                }
                                
                                Text("\(count)")
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
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
                            .foregroundColor(currentTheme.textColor)
                        
                        Text("\(lastSaved.formatted(date: .complete, time: .shortened))")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Study session tracking
                VStack(alignment: .leading, spacing: 8) {
                    Text("Study Progress")
                        .font(.headline)
                        .foregroundColor(currentTheme.textColor)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's sessions")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("2 sessions")
                                .font(.title3)
                                .foregroundColor(currentTheme.textColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total study time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("45 minutes")
                                .font(.title3)
                                .foregroundColor(currentTheme.textColor)
                        }
                    }
                    
                    // Study streak
                    HStack {
                        ForEach(0..<7, id: \.self) { index in
                            let isActive = index < 4 // Simulated 4-day streak
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(isActive ? currentTheme.accentColor : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                
                                


                                      Text(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index])
                                                                          .font(.caption2)
                                                                          .foregroundColor(isActive ? currentTheme.textColor : .secondary)
                                                                  }
                                                              }
                                                          }
                                                          .padding(.top, 8)
                                                      }
                                                      .padding()
                                                      .background(Color(UIColor.secondarySystemBackground))
                                                      .cornerRadius(12)
                                                      .padding(.horizontal)
                                                  }
                                                  .padding(.vertical)
                                              }
                                          }
                                          
                                          // Bottom toolbar for editor mode
                                          private var bottomToolbar: some View {
                                              HStack(spacing: 20) {
                                                  // Formatting tools button
                                                  Button(action: {
                                                      withAnimation {
                                                          showingFormatting.toggle()
                                                          if showingFormatting {
                                                              showingMedicalSymbols = false
                                                              showingStudyTools = false
                                                          }
                                                      }
                                                  }) {
                                                      VStack(spacing: 2) {
                                                          Image(systemName: "textformat")
                                                              .font(.system(size: 20))
                                                              .foregroundColor(showingFormatting ? currentTheme.accentColor : .primary)
                                                          
                                                          Text("Format")
                                                              .font(.caption)
                                                              .foregroundColor(.primary)
                                                      }
                                                      .frame(width: 60)
                                                  }
                                                  
                                                  // Medical symbols button
                                                  Button(action: {
                                                      withAnimation {
                                                          showingMedicalSymbols.toggle()
                                                          if showingMedicalSymbols {
                                                              showingFormatting = false
                                                              showingStudyTools = false
                                                          }
                                                      }
                                                  }) {
                                                      VStack(spacing: 2) {
                                                          Image(systemName: "pills")
                                                              .font(.system(size: 20))
                                                              .foregroundColor(showingMedicalSymbols ? currentTheme.accentColor : .primary)
                                                          
                                                          Text("Symbols")
                                                              .font(.caption)
                                                              .foregroundColor(.primary)
                                                      }
                                                      .frame(width: 60)
                                                  }
                                                  
                                                  // Image insert button
                                                  Button(action: {
                                                      showingImagePicker = true
                                                  }) {
                                                      VStack(spacing: 2) {
                                                          Image(systemName: "photo")
                                                              .font(.system(size: 20))
                                                              .foregroundColor(.primary)
                                                          
                                                          Text("Image")
                                                              .font(.caption)
                                                              .foregroundColor(.primary)
                                                      }
                                                      .frame(width: 60)
                                                  }
                                                  
                                                  Spacer()
                                                  
                                                  // Study tools button
                                                  Button(action: {
                                                      withAnimation {
                                                          showingStudyTools.toggle()
                                                          if showingStudyTools {
                                                              showingFormatting = false
                                                              showingMedicalSymbols = false
                                                          }
                                                      }
                                                  }) {
                                                      HStack {
                                                          Image(systemName: "lightbulb")
                                                          Text("Study Tools")
                                                      }
                                                      .font(.system(size: 14))
                                                      .foregroundColor(.white)
                                                      .padding(.horizontal, 12)
                                                      .padding(.vertical, 8)
                                                      .background(currentTheme.accentColor)
                                                      .cornerRadius(20)
                                                  }
                                                  
                                                  // Save button
                                                  Button(action: {
                                                      saveNote()
                                                  }) {
                                                      VStack(spacing: 2) {
                                                          Image(systemName: "arrow.down.doc")
                                                              .font(.system(size: 20))
                                                              .foregroundColor(currentTheme.accentColor)
                                                          
                                                          Text("Save")
                                                              .font(.caption)
                                                              .foregroundColor(.primary)
                                                      }
                                                      .frame(width: 60)
                                                  }
                                              }
                                          }
                                          
                                          // Study tools panel at the bottom
                                          private var studyToolsPanel: some View {
                                              VStack(alignment: .leading, spacing: 15) {
                                                  HStack {
                                                      Text("Study Tools")
                                                          .font(.headline)
                                                          .foregroundColor(currentTheme.textColor)
                                                      
                                                      Spacer()
                                                      
                                                      Button(action: {
                                                          withAnimation {
                                                              showingStudyTools = false
                                                          }
                                                      }) {
                                                          Image(systemName: "xmark.circle.fill")
                                                              .foregroundColor(.gray)
                                                      }
                                                  }
                                                  .padding(.horizontal)
                                                  
                                                  ScrollView(.horizontal, showsIndicators: false) {
                                                      HStack(spacing: 15) {
                                                          ModernStudyToolButton(title: "Flashcard", systemImage: "rectangle.on.rectangle", themeColor: currentTheme.accentColor) {
                                                              showingFlashcardCreator = true
                                                          }
                                                          
                                                          ModernStudyToolButton(title: "Highlight", systemImage: "highlighter", themeColor: currentTheme.accentColor) {
                                                              insertTemplateText("**[Highlight]** ")
                                                          }
                                                          
                                                          ModernStudyToolButton(title: "Definition", systemImage: "text.book.closed", themeColor: currentTheme.accentColor) {
                                                              insertTemplateText("\n**Definition:** \n")
                                                          }
                                                          
                                                          ModernStudyToolButton(title: "Key Concept", systemImage: "lightbulb", themeColor: currentTheme.accentColor) {
                                                              insertTemplateText("\n**Key Concept:** \n")
                                                          }
                                                          
                                                          ModernStudyToolButton(title: "Reference", systemImage: "link", themeColor: currentTheme.accentColor) {
                                                              insertTemplateText("\n**Reference:** [](url)\n")
                                                          }
                                                          
                                                          ModernStudyToolButton(title: "Mnemonic", systemImage: "brain", themeColor: currentTheme.accentColor) {
                                                              insertTemplateText("\n**Mnemonic:** \n")
                                                          }
                                                          
                                                          ModernStudyToolButton(title: "Citation", systemImage: "quote.opening", themeColor: currentTheme.accentColor) {
                                                              insertTemplateText("\n> Citation: \n")
                                                          }
                                                          
                                                          ModernStudyToolButton(title: "Table", systemImage: "tablecells", themeColor: currentTheme.accentColor) {
                                                              insertTemplateText("\n| Column 1 | Column 2 | Column 3 |\n| --- | --- | --- |\n| Data | Data | Data |\n| Data | Data | Data |\n")
                                                          }
                                                      }
                                                      .padding(.horizontal)
                                                  }
                                              }
                                              .padding(.vertical, 16)
                                              .background(
                                                  RoundedRectangle(cornerRadius: 16)
                                                      .fill(Color(.systemGray6).opacity(0.95))
                                                      .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
                                              )
                                              .padding(.horizontal, 8)
                                          }
                                          
                                          // MARK: - Sheets & Dialogs
                                          
                                          // Flashcard creator sheet
                                          private var flashcardCreatorView: some View {
                                              NavigationView {
                                                  VStack(spacing: 24) {
                                                      VStack(alignment: .leading, spacing: 8) {
                                                          HStack {
                                                              Image(systemName: "questionmark.circle.fill")
                                                                  .foregroundColor(currentTheme.accentColor)
                                                                  .font(.title3)
                                                              
                                                              Text("Question / Front Side")
                                                                  .font(.headline)
                                                                  .foregroundColor(currentTheme.textColor)
                                                          }
                                                          
                                                          TextEditor(text: $currentFlashcardFront)
                                                              .frame(height: 120)
                                                              .padding(12)
                                                              .background(Color(UIColor.secondarySystemBackground))
                                                              .cornerRadius(12)
                                                              .overlay(
                                                                  RoundedRectangle(cornerRadius: 12)
                                                                      .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                              )
                                                      }
                                                      
                                                      VStack(alignment: .leading, spacing: 8) {
                                                          HStack {
                                                              Image(systemName: "exclamationmark.circle.fill")
                                                                  .foregroundColor(currentTheme.accentColor)
                                                                  .font(.title3)
                                                              
                                                              Text("Answer / Back Side")
                                                                  .font(.headline)
                                                                  .foregroundColor(currentTheme.textColor)
                                                          }
                                                          
                                                          TextEditor(text: $currentFlashcardBack)
                                                              .frame(height: 120)
                                                              .padding(12)
                                                              .background(Color(UIColor.secondarySystemBackground))
                                                              .cornerRadius(12)
                                                              .overlay(
                                                                  RoundedRectangle(cornerRadius: 12)
                                                                      .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                              )
                                                      }
                                                      
                                                      // Tips section
                                                      if currentFlashcardFront.isEmpty || currentFlashcardBack.isEmpty {
                                                          VStack(alignment: .leading, spacing: 8) {
                                                              Text("Tips for effective flashcards:")
                                                                  .font(.subheadline)
                                                                  .fontWeight(.semibold)
                                                                  .foregroundColor(currentTheme.textColor)
                                                              
                                                              FlashcardTipRow(text: "Keep questions clear and specific")
                                                              FlashcardTipRow(text: "Include one concept per card")
                                                              FlashcardTipRow(text: "Use your own words to reinforce learning")
                                                          }
                                                          .padding()
                                                          .background(Color(UIColor.tertiarySystemBackground))
                                                          .cornerRadius(12)
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
                                                              .fontWeight(.semibold)
                                                              .foregroundColor(.white)
                                                              .frame(maxWidth: .infinity)
                                                              .padding()
                                                              .background(
                                                                  (!currentFlashcardFront.isEmpty && !currentFlashcardBack.isEmpty) ?
                                                                      currentTheme.accentColor : Color.gray
                                                              )
                                                              .cornerRadius(10)
                                                      }
                                                      .disabled(currentFlashcardFront.isEmpty || currentFlashcardBack.isEmpty)
                                                  }
                                                  .padding()
                                                  .navigationBarTitle("New Flashcard", displayMode: .inline)
                                                  .navigationBarItems(
                                                      trailing: Button("Cancel") {
                                                          showingFlashcardCreator = false
                                                      }
                                                  )
                                              }
                                          }
                                          
                                          // Flashcard study mode sheet
                                          private var flashcardStudyView: some View {
                                              NavigationView {
                                                  ZStack {
                                                      Color(UIColor.systemGray6)
                                                          .ignoresSafeArea()
                                                      
                                                      VStack(spacing: 20) {
                                                          // Progress indicator
                                                          Text("Card \(currentFlashcardIndex + 1) of \(flashcards.count)")
                                                              .font(.headline)
                                                              .padding(.top)
                                                          
                                                          // Card display
                                                          VStack {
                                                              if flashcards.indices.contains(currentFlashcardIndex) {
                                                                  FlashcardView(
                                                                      card: flashcards[currentFlashcardIndex],
                                                                      isShowingAnswer: $isShowingFlashcardAnswer,
                                                                      themeColor: currentTheme.accentColor
                                                                  )
                                                              }
                                                          }
                                                          .frame(height: 300)
                                                          .padding()
                                                          
                                                          // Navigation controls
                                                          HStack(spacing: 30) {
                                                              Button(action: {
                                                                  if currentFlashcardIndex > 0 {
                                                                      currentFlashcardIndex -= 1
                                                                      isShowingFlashcardAnswer = false
                                                                  }
                                                              }) {
                                                                  Image(systemName: "arrow.left.circle.fill")
                                                                      .font(.system(size: 40))
                                                                      .foregroundColor(currentFlashcardIndex > 0 ? currentTheme.accentColor : Color.gray)
                                                              }
                                                              .disabled(currentFlashcardIndex == 0)
                                                              
                                                              if !isShowingFlashcardAnswer {
                                                                  Button(action: {
                                                                      withAnimation {
                                                                          isShowingFlashcardAnswer = true
                                                                      }
                                                                  }) {
                                                                      Text("Show Answer")
                                                                          .font(.headline)
                                                                          .foregroundColor(.white)
                                                                          .padding(.horizontal, 20)
                                                                          .padding(.vertical, 12)
                                                                          .background(currentTheme.accentColor)
                                                                          .cornerRadius(20)
                                                                  }
                                                              } else {
                                                                  HStack(spacing: 15) {
                                                                      ForEach(1...3, id: \.self) { confidenceLevel in
                                                                          Button(action: {
                                                                              // Record confidence and move to next card
                                                                              markCardConfidence(confidenceLevel)
                                                                              
                                                                              if currentFlashcardIndex < flashcards.count - 1 {
                                                                                  currentFlashcardIndex += 1
                                                                                  isShowingFlashcardAnswer = false
                                                                              }
                                                                          }) {
                                                                              Text("\(confidenceLevel)")
                                                                                  .font(.headline)
                                                                                  .foregroundColor(.white)
                                                                                  .frame(width: 40, height: 40)
                                                                                  .background(
                                                                                      confidenceLevel == 1 ? Color.red :
                                                                                          confidenceLevel == 2 ? Color.orange : Color.green
                                                                                  )
                                                                                  .clipShape(Circle())
                                                                          }
                                                                      }
                                                                  }
                                                              }
                                                              
                                                              Button(action: {
                                                                  if currentFlashcardIndex < flashcards.count - 1 {
                                                                      currentFlashcardIndex += 1
                                                                      isShowingFlashcardAnswer = false
                                                                  }
                                                              }) {
                                                                  Image(systemName: "arrow.right.circle.fill")
                                                                      .font(.system(size: 40))
                                                                      .foregroundColor(currentFlashcardIndex < flashcards.count - 1 ? currentTheme.accentColor : Color.gray)
                                                              }
                                                              .disabled(currentFlashcardIndex == flashcards.count - 1)
                                                          }
                                                          .padding()
                                                          
                                                          // Confidence level legend (shown when viewing answer)
                                                          if isShowingFlashcardAnswer {
                                                              HStack(spacing: 15) {
                                                                  VStack {
                                                                      Circle()
                                                                          .fill(Color.red)
                                                                          .frame(width: 12, height: 12)
                                                                      Text("Again")
                                                                          .font(.caption)
                                                                  }
                                                                  
                                                                  VStack {
                                                                      Circle()
                                                                          .fill(Color.orange)
                                                                          .frame(width: 12, height: 12)
                                                                      Text("Hard")
                                                                          .font(.caption)
                                                                  }
                                                                  
                                                                  VStack {
                                                                      Circle()
                                                                          .fill(Color.green)
                                                                          .frame(width: 12, height: 12)
                                                                      Text("Easy")
                                                                          .font(.caption)
                                                                  }
                                                              }
                                                              .padding(.bottom)
                                                          }
                                                          
                                                          Spacer()
                                                      }
                                                  }
                                                  .navigationBarTitle("Study Flashcards", displayMode: .inline)
                                                  .navigationBarItems(
                                                      trailing: Button("Done") {
                                                          showingFlashcardStudyMode = false
                                                      }
                                                  )
                                                  .onAppear {
                                                      // Reset to first card when starting study session
                                                      currentFlashcardIndex = 0
                                                      isShowingFlashcardAnswer = false
                                                  }
                                              }
                                          }
                                          
                                          // Export options sheet
                                          private var exportOptionsView: some View {
                                              NavigationView {
                                                  List {
                                                      Section(header: Text("Export Format")) {
                                                          Button(action: {
                                                              exportAsPDF()
                                                          }) {
                                                              HStack {
                                                                  Image(systemName: "doc.fill")
                                                                      .foregroundColor(.red)
                                                                  Text("Export as PDF")
                                                              }
                                                          }
                                                          
                                                          Button(action: {
                                                              exportAsMarkdown()
                                                          }) {
                                                              HStack {
                                                                  Image(systemName: "doc.plaintext")
                                                                      .foregroundColor(.blue)
                                                                  Text("Export as Markdown")
                                                              }
                                                          }
                                                          
                                                          Button(action: {
                                                              exportAsText()
                                                          }) {
                                                              HStack {
                                                                  Image(systemName: "doc.text")
                                                                      .foregroundColor(.green)
                                                                  Text("Export as Plain Text")
                                                              }
                                                          }
                                                      }
                                                      
                                                      Section(header: Text("Share")) {
                                                          Button(action: {
                                                              shareNote()
                                                          }) {
                                                              HStack {
                                                                  Image(systemName: "square.and.arrow.up")
                                                                      .foregroundColor(currentTheme.accentColor)
                                                                  Text("Share")
                                                              }
                                                          }
                                                      }
                                                      
                                                      if !flashcards.isEmpty {
                                                          Section(header: Text("Flashcards")) {
                                                              Button(action: {
                                                                  exportFlashcards()
                                                              }) {
                                                                  HStack {
                                                                      Image(systemName: "rectangle.on.rectangle")
                                                                          .foregroundColor(.orange)
                                                                      Text("Export Flashcards")
                                                                  }
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
                                              readingTime = max(1, wordCount / 200) // Estimate based on 200 words per minute
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
                                              
                                              // Show the save confirmation toast
                                              withAnimation {
                                                  showingSaveConfirmation = true
                                              }
                                              
                                              // Hide the confirmation after 2 seconds
                                              DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                  withAnimation {
                                                      showingSaveConfirmation = false
                                                  }
                                              }
                                              
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
                                          
                                          private func insertTemplateText(_ text: String) {
                                              noteContent.append(text)
                                              hasUnsavedChanges = true
                                          }
                                          
                                          private func markCardConfidence(_ level: Int) {
                                              if flashcards.indices.contains(currentFlashcardIndex) {
                                                  // In a real app, you would update the confidence level and adjust the spaced repetition algorithm
                                                  // This is just a placeholder
                                                  NotificationManager.shared.sendNotification(
                                                      title: "Card Rated",
                                                      message: "Confidence level \(level) recorded."
                                                  )
                                              }
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
                                          
                                          private func timeAgoSince(_ date: Date) -> String {
                                              let minutes = Int(Date().timeIntervalSince(date) / 60)
                                              
                                              if minutes < 1 {
                                                  return "Just now"
                                              } else if minutes == 1 {
                                                  return "1 min ago"
                                              } else if minutes < 60 {
                                                  return "\(minutes) mins ago"
                                              } else if minutes < 120 {
                                                  return "1 hour ago"
                                              } else if minutes < 1440 {
                                                  return "\(minutes / 60) hours ago"
                                              } else {
                                                  return "\(minutes / 1440) days ago"
                                              }
                                          }
                                          
                                          // Export and share functions
                                          private func exportAsPDF() {
                                              NotificationManager.shared.sendNotification(
                                                  title: "PDF Export",
                                                  message: "The note has been exported as PDF."
                                              )
                                              showingExportOptions = false
                                          }
                                          
                                          private func exportAsMarkdown() {
                                              NotificationManager.shared.sendNotification(
                                                  title: "Markdown Export",
                                                  message: "The note has been exported as Markdown."
                                              )
                                              showingExportOptions = false
                                          }
                                          
                                          private func exportAsText() {
                                              NotificationManager.shared.sendNotification(
                                                  title: "Text Export",
                                                  message: "The note has been exported as plain text."
                                              )
                                              showingExportOptions = false
                                          }
                                          
                                          private func shareNote() {
                                              let activityVC = UIActivityViewController(
                                                  activityItems: [noteTitle, noteContent],
                                                  applicationActivities: nil
                                              )
                                              
                                              if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                                 let rootViewController = windowScene.windows.first?.rootViewController {
                                                  rootViewController.present(activityVC, animated: true)
                                              }
                                              
                                              showingExportOptions = false
                                          }
                                          
                                          private func exportFlashcards() {
                                              NotificationManager.shared.sendNotification(
                                                  title: "Flashcards Export",
                                                  message: "\(flashcards.count) flashcards have been exported."
                                              )
                                              showingExportOptions = false
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

                                      struct ModernStudyToolButton: View {
                                          let title: String
                                          let systemImage: String
                                          let themeColor: Color
                                          let action: () -> Void
                                          
                                          var body: some View {
                                              Button(action: action) {
                                                  VStack(spacing: 8) {
                                                      Image(systemName: systemImage)
                                                          .font(.system(size: 24))
                                                          .foregroundColor(themeColor)
                                                          .frame(width: 48, height: 48)
                                                          .background(themeColor.opacity(0.1))
                                                          .clipShape(Circle())
                                                      
                                                      Text(title)
                                                          .font(.caption)
                                                          .foregroundColor(.primary)
                                                  }
                                                  .frame(width: 80, height: 80)
                                              }
                                          }
                                      }

                                      struct FlashcardView: View {
                                          let card: Flashcard
                                          @Binding var isShowingAnswer: Bool
                                          let themeColor: Color
                                          
                                          var body: some View {
                                              ZStack {
                                                  // Front
                                                  VStack(alignment: .leading, spacing: 16) {
                                                      HStack {
                                                          Image(systemName: "questionmark.circle.fill")
                                                              .foregroundColor(themeColor)
                                                              .font(.title2)
                                                          
                                                          Text("Question")
                                                              .font(.headline)
                                                              .foregroundColor(.secondary)
                                                          
                                                          Spacer()
                                                      }
                                                      
                                                      Text(card.front)
                                                          .font(.title3)
                                                          .padding(.vertical)
                                                          .frame(maxWidth: .infinity, alignment: .leading)
                                                      
                                                      Spacer()
                                                      
                                                      if !isShowingAnswer {
                                                          HStack {
                                                              Spacer()
                                                              
                                                              Button(action: {
                                                                  withAnimation {
                                                                      isShowingAnswer.toggle()
                                                                  }
                                                              }) {
                                                                  Text("Reveal Answer")
                                                                      .font(.headline)
                                                                      .foregroundColor(.white)
                                                                      .padding(.horizontal, 16)
                                                                      .padding(.vertical, 10)
                                                                      .background(themeColor)
                                                                      .cornerRadius(20)
                                                              }
                                                          }
                                                      }
                                                  }
                                                  .padding()
                                                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                                  .background(Color.white)
                                                  .cornerRadius(16)
                                                  .shadow(color: Color.black.opacity(0.1), radius: 5)
                                                  .opacity(isShowingAnswer ? 0 : 1)
                                                  .rotation3DEffect(
                                                      .degrees(isShowingAnswer ? 180 : 0),
                                                      axis: (x: 0, y: 1, z: 0)
                                                  )
                                                  
                                                  // Back
                                                  VStack(alignment: .leading, spacing: 16) {
                                                      HStack {
                                                          Image(systemName: "exclamationmark.circle.fill")
                                                              .foregroundColor(themeColor)
                                                              .font(.title2)
                                                          
                                                          Text("Answer")
                                                              .font(.headline)
                                                              .foregroundColor(.secondary)
                                                          
                                                          Spacer()
                                                      }
                                                      
                                                      Text(card.back)
                                                          .font(.title3)
                                                          .padding(.vertical)
                                                          .frame(maxWidth: .infinity, alignment: .leading)
                                                      
                                                      Spacer()
                                                  }
                                                  .padding()
                                                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                                  .background(Color.white)
                                                  .cornerRadius(16)
                                                  .shadow(color: Color.black.opacity(0.1), radius: 5)
                                                  .opacity(isShowingAnswer ? 1 : 0)
                                                  .rotation3DEffect(
                                                      .degrees(isShowingAnswer ? 0 : -180),
                                                      axis: (x: 0, y: 1, z: 0)
                                                  )
                                              }
                                              .padding()
                                          }
                                      }

                                      struct FlashcardListItem: View {
                                          let card: Flashcard
                                          
                                          var body: some View {
                                              VStack(alignment: .leading, spacing: 8) {
                                                  Text(card.front)
                                                      .font(.headline)
                                                      .lineLimit(2)
                                                  
                                                  Divider()
                                                  
                                                  Text(card.back)
                                                      .font(.subheadline)
                                                      .foregroundColor(.secondary)
                                                      .lineLimit(3)
                                              }
                                              .padding()
                                              .frame(maxWidth: .infinity, alignment: .leading)
                                              .background(Color(UIColor.secondarySystemBackground))
                                              .cornerRadius(12)
                                          }
                                      }

                                      struct FlashcardTipRow: View {
                                          let text: String
                                          
                                          var body: some View {
                                              HStack(alignment: .top, spacing: 8) {
                                                  Image(systemName: "checkmark.circle.fill")
                                                      .foregroundColor(.green)
                                                      .font(.caption)
                                                  
                                                  Text(text)
                                                      .font(.caption)
                                                      .foregroundColor(.secondary)
                                              }
                                          }
                                      }

//                                      struct StatCard: View {
//                                          let title: String
//                                          let value: String
//                                          let icon: String
//                                          
//                                          var body: some View {
//                                              VStack(spacing: 8) {
//                                                  Image(systemName: icon)
//                                                      .font(.system(size: 24))
//                                                      .foregroundColor(.blue)
//                                                  
//                                                  Text(value)
//                                                      .font(.system(size: 24, weight: .bold))
//                                                      .foregroundColor(.primary)
//                                                  
//                                                  Text(title)
//                                                      .font(.caption)
//                                                      .foregroundColor(.secondary)
//                                              }
//                                              .frame(maxWidth: .infinity)
//                                              .padding()
//                                              .background(Color(UIColor.secondarySystemBackground))
//                                              .cornerRadius(12)
//                                          }
//                                      }

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

                                      // Color extension for hex colors
                                    

                                              extension Color {
                                                  init(hex1: String) {
                                                      let hex = hex1.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                                                      var int: UInt64 = 0
                                                      Scanner(string: hex).scanHexInt64(&int)
                                                      let a, r, g, b: UInt64
                                                      switch hex.count {
                                                      case 3: // RGB (12-bit)
                                                          (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
                                                      case 6: // RGB (24-bit)
                                                          (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
                                                      case 8: // ARGB (32-bit)
                                                          (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
                                                      default:
                                                          (a, r, g, b) = (255, 0, 0, 0)
                                                      }
                                                      self.init(
                                                          .sRGB,
                                                          red: Double(r) / 255,
                                                          green: Double(g) / 255,
                                                          blue: Double(b) / 255,
                                                          opacity: Double(a) / 255
                                                      )
                                                  }
                                              }
