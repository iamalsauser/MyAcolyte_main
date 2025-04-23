import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var showDocumentPicker = false
    @State private var selectedDocument: DocumentItem?
    @State private var showingSearchSheet = false
    @State private var searchQuery = ""
    @State private var showingFullScreenContinueReading = false
    @State private var showingStudyToolsSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Search bar at the top - now functional
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search pdf", text: $searchQuery)
                        .font(.system(size: 16))
                        .onSubmit {
                            // Perform search when user presses return
                            performSearch()
                        }
                }
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)
                .onTapGesture {
                    showingSearchSheet = true
                }
                
                // Recent uploads section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button(action: {
                            showDocumentPicker = true
                        }) {
                            Text("New Upload")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // Show recent files screen
                            viewModel.recentsUpdated = true
                        }) {
                            Text("Recent")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent files list
                    VStack(spacing: 0) {
                        ForEach(viewModel.recentFiles.prefix(3)) { item in
                            RecentFileRow(item: item, onTap: {
                                openFile(item)
                            })
                        }
                        
                        // If no recent files, add some interactive demo rows
                        if viewModel.recentFiles.isEmpty {
                            ForEach(1...3, id: \.self) { index in
                                let demoItem = FileSystemItem(
                                    id: "demo-\(index)",
                                    name: "NEET_PG_Preparation_Materials_2025.pdf",
                                    type: .file,
                                    fileType: .pdf
                                )
                                RecentFileRow(item: demoItem, onTap: {
                                    // Create a sample file when demo row is tapped
                                    createSampleFile()
                                })
                            }
                        }
                    }
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Library section with working "New Upload" button
                HStack {
                    Text("Library")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        Text("New Upload")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Continue reading section with working cards
                VStack(alignment: .leading, spacing: 16) {
                    Text("Continue reading")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        let recentStudyItems = viewModel.getRecentStudyItems()
                        
                        if !recentStudyItems.isEmpty {
                            ForEach(recentStudyItems, id: \.0.id) { (item, progress) in
                                ContinueReadingItem(
                                    title: item.name.replacingOccurrences(of: ".pdf", with: ""),
                                    lastStudied: "Last studied",
                                    progress: progress.progress,
                                    percentage: "\(progress.percentComplete)%",
                                    user: "You",
                                    timeSpent: progress.formattedTimeSpent,
                                    date: progress.lastStudiedText,
                                    onTap: {
                                        openFile(item)
                                    }
                                )
                            }
                        } else {
                            // Demo items if no study progress exists
                            ContinueReadingItem(
                                title: "Unit 9- Anatomy",
                                lastStudied: "Last studied",
                                progress: 0.5,
                                percentage: "50%",
                                user: "LOPYSTEP",
                                timeSpent: "20mins",
                                date: "Today",
                                onTap: {
                                    createSampleFile()
                                }
                            )
                            
                            ContinueReadingItem(
                                title: "Unit 8- Special Senses",
                                lastStudied: "Last studied",
                                progress: 0.7,
                                percentage: "70%",
                                user: "LOPYSTEP",
                                timeSpent: "15mins",
                                date: "Yesterday",
                                onTap: {
                                    createSampleFile()
                                }
                            )
                            
                            ContinueReadingItem(
                                title: "Unit 7- Nervous System",
                                lastStudied: "Last studied",
                                progress: 0.4,
                                percentage: "40%",
                                user: "LOPYSTEP",
                                timeSpent: "5mins",
                                date: "12days ago",
                                onTap: {
                                    createSampleFile()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Optimize your study section with working cards
                VStack(alignment: .leading, spacing: 16) {
                    Text("Optimize your study")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.horizontal)
                    
                    // Two column grid layout for review cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ReviewCard(
                            subject: "Anatomy",
                            title: "Due for review",
                            bulletPoints: [
                                "These topics are due for review",
                                "Time to reinforce key concepts"
                            ],
                            onTap: {
                                showingStudyToolsSheet = true
                            }
                        )
                        
                        ReviewCard(
                            subject: "Physiology",
                            title: "Weak Areas",
                            bulletPoints: [
                                "Key improvement areas",
                                "Low understanding - start here"
                            ],
                            onTap: {
                                showingStudyToolsSheet = true
                            }
                        )
                        
                        ReviewCard(
                            subject: "Biochemistry",
                            title: "Improvement Zones",
                            bulletPoints: [
                                "These topics need attention",
                                "Focus here for better scores"
                            ],
                            onTap: {
                                showingStudyToolsSheet = true
                            }
                        )
                        
                        ReviewCard(
                            subject: "Pathology",
                            title: "Review Needed",
                            bulletPoints: [
                                "Revisit these topics soon",
                                "Critical for examination success"
                            ],
                            onTap: {
                                showingStudyToolsSheet = true
                            }
                        )
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 60)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(showPicker: $showDocumentPicker) { url in
                viewModel.importPDF(url: url)
            }
        }
        .fullScreenCover(item: $selectedDocument) { document in
            if let item = viewModel.fileSystem.first(where: { $0.id == document.id }) {
                if item.type == .file && item.fileType == .pdf {
                    PDFViewerView(pdfId: item.id, viewModel: viewModel)
                }
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchResultsView(
                viewModel: viewModel,
                searchQuery: $searchQuery,
                selectedDocument: $selectedDocument
            )
        }
        .sheet(isPresented: $showingStudyToolsSheet) {
            StudyToolsView(viewModel: viewModel)
        }
    }
    
    private func performSearch() {
        if !searchQuery.isEmpty {
            showingSearchSheet = true
        }
    }
    
    private func openFile(_ item: FileSystemItem) {
        viewModel.openFile(item)
        selectedDocument = DocumentItem(id: item.id, title: item.name)
    }
    
    private func createSampleFile() {
        // Create a dummy file for demo purposes
        let documentId = UUID().uuidString
        let fileName = "Sample Study Material.pdf"
        
        let newFile = FileSystemItem(
            id: documentId,
            name: fileName,
            type: .file,
            fileType: .pdf,
            parentId: viewModel.currentFolder
        )
        
        viewModel.fileSystem.append(newFile)
        viewModel.saveFileSystem()
        
        // Add to recent files
        viewModel.addToRecentFiles(newFile)
        
        // Create initial study progress
        viewModel.updateStudyProgress(for: documentId)
        
        selectedDocument = DocumentItem(id: documentId, title: fileName)
        
        NotificationManager.shared.sendNotification(
            title: "Sample Created",
            message: "A sample PDF has been created for demonstration."
        )
    }
}

// Components for the Home View with tap functionality added

struct RecentFileRow: View {
    let item: FileSystemItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.green)
                    .frame(width: 24, height: 24)
                
                Text(item.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("3m ago")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text("2.20MB")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(4)
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContinueReadingItem: View {
    let title: String
    let lastStudied: String
    let progress: Double
    let percentage: String
    let user: String
    let timeSpent: String
    let date: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon/thumbnail
                Image(systemName: "doc.fill")
                    .foregroundColor(.green)
                    .frame(width: 30, height: 30)
                    .padding(8)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(date)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(lastStudied)
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        // Progress bar
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(height: 5)
                                .foregroundColor(Color.gray.opacity(0.3))
                                .cornerRadius(2.5)
                            
                            Rectangle()
                                .frame(width: 100 * progress, height: 5)
                                .foregroundColor(.green)
                                .cornerRadius(2.5)
                        }
                        .frame(width: 100)
                        
                        Text(percentage)
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 8))
                        
                        Text(user)
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text(timeSpent)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReviewCard: View {
    let subject: String
    let title: String
    let bulletPoints: [String]
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text(subject)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bulletPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text(point)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    Text("Review now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// New Component: Search Results View
struct SearchResultsView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @Binding var searchQuery: String
    @Binding var selectedDocument: DocumentItem?
    @Environment(\.dismiss) private var dismiss
    
    var filteredResults: [FileSystemItem] {
        if searchQuery.isEmpty {
            return []
        }
        
        return viewModel.fileSystem.filter { item in
            (item.type == .file || item.type == .whiteboard) &&
            item.name.lowercased().contains(searchQuery.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search files...", text: $searchQuery)
                        .font(.system(size: 16))
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                if filteredResults.isEmpty && !searchQuery.isEmpty {
                    // No results
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No results found for \"\(searchQuery)\"")
                            .font(.title3)
                        
                        Text("Try a different search term or browse your library")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // Results
                    List {
                        ForEach(filteredResults) { item in
                            Button(action: {
                                viewModel.openFile(item)
                                selectedDocument = DocumentItem(id: item.id, title: item.name)
                                dismiss()
                            }) {
                                HStack {
                                    FileIcon(item: item, size: 24)
                                        .padding(6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .lineLimit(1)
                                        
                                        Text(formatDate(item.dateModified))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// New Component: Study Tools View
struct StudyToolsView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @Environment(\.dismiss) private var dismiss
    
    let studyTools = [
        ("Focus Timer", "timer", "Track your study sessions"),
        ("Flashcards", "rectangle.on.rectangle", "Create custom flashcards"),
        ("Mind Maps", "map", "Visualize complex topics"),
        ("Notes", "note.text", "Organize your study notes"),
        ("Quiz Generator", "questionmark.square", "Test your knowledge")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Banner image
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 160)
                            .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Study Tools")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Boost your learning with these tools")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(20)
                    }
                    .padding(.horizontal)
                    
                    // Tools Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(studyTools, id: \.0) { tool in
                            Button(action: {
                                toolTapped(tool.0)
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: tool.1)
                                        .font(.system(size: 30))
                                        .foregroundColor(.green)
                                        .frame(width: 60, height: 60)
                                        .background(Color.green.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    Text(tool.0)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(tool.2)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Study tips section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Study Tips")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            StudyTipCard(
                                title: "Spaced Repetition",
                                description: "Review materials at increasing intervals for better retention.",
                                iconName: "calendar"
                            )
                            
                            StudyTipCard(
                                title: "Active Recall",
                                description: "Test yourself on material rather than simply re-reading it.",
                                iconName: "lightbulb"
                            )
                            
                            StudyTipCard(
                                title: "Pomodoro Technique",
                                description: "Study in focused 25-minute intervals with 5-minute breaks.",
                                iconName: "timer"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Study Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toolTapped(_ tool: String) {
        switch tool {
        case "Notes":
            // Create new note
            viewModel.createNewNote()
            NotificationManager.shared.sendNotification(
                title: "Note Created",
                message: "Your new note is ready to edit."
            )
        case "Flashcards":
            // Create new flashcard
            NotificationManager.shared.sendNotification(
                title: "Flashcards",
                message: "Flashcard creation tools will launch here."
            )
        default:
            // Generic response for other tools
            NotificationManager.shared.sendNotification(
                title: tool,
                message: "This tool will be available in a future update."
            )
        }
        
        // Close the sheet after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

struct StudyTipCard: View {
    let title: String
    let description: String
    let iconName: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 40, height: 40)
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
