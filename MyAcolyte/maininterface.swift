import SwiftUI

struct MainInterface: View {
    @StateObject private var viewModel = FileSystemViewModel()
    @State private var selectedTab: TabItem? = .home // Optional to allow no selection initially
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic // Control sidebar visibility
    @State private var showingTodoList = false // Control to-do list sidebar visibility
    
    // Constants
    private let headerHeight: CGFloat = 60
    
    enum TabItem: String, CaseIterable, Identifiable {
        case home = "house.fill"
        case library = "doc.fill"
        case notes = "note.text.fill"
        case whiteboard = "scribble"
        case profile = "person.circle.fill"
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .library: return "My PDF"
            case .notes: return "My Notes"
            case .whiteboard: return "Whiteboard"
            case .profile: return "Profile"
            }
        }
    }
    
    var body: some View {
        GeometryReader { mainGeometry in
            ZStack(alignment: .top) {
                // Fixed Header Bar at Top
                UpdatedHomeHeaderBar(showingTodoList: $showingTodoList)
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 1)
                
                // Main Content Area - positioned below header
                VStack(spacing: 0) {
                    // Empty space to offset content below the header
                    Spacer()
                        .frame(height: headerHeight)
                    
                    // Main Content with Navigation
                    NavigationSplitView(columnVisibility: $sidebarVisibility) {
                        // Main Navigation Sidebar
                        VStack(spacing: 0) {
                            // Navigation tabs
                            List {
                                NavigationLink(destination: HomeScreenView(viewModel: viewModel), tag: TabItem.home, selection: $selectedTab) {
                                    Label("Home", systemImage: "house.fill")
                                        .foregroundColor(.primary)
                                }
                                
                                NavigationLink(destination: DocumentLibraryView(viewModel: viewModel), tag: TabItem.library, selection: $selectedTab) {
                                    Label("My PDF", systemImage: "doc.fill")
                                        .foregroundColor(.primary)
                                }
                                
                                NavigationLink(destination: MyNotesView(viewModel: viewModel, showFullScreen: .constant(false), selectedDocument: .constant(nil)), tag: TabItem.notes, selection: $selectedTab) {
                                    Label("My Notes", systemImage: "note.text.fill")
                                        .foregroundColor(.primary)
                                }
                                
                                NavigationLink(destination: WhiteboardView(viewModel: viewModel), tag: TabItem.whiteboard, selection: $selectedTab) {
                                    Label("Whiteboard", systemImage: "scribble")
                                        .foregroundColor(.primary)
                                }
                                
                                NavigationLink(destination: SettingsView(viewModel: viewModel), tag: TabItem.profile, selection: $selectedTab) {
                                    Label("Profile", systemImage: "person.circle.fill")
                                        .foregroundColor(.primary)
                                }
                                
                                Section(header: Text("SUBJECTS")) {
                                    DisclosureGroup("Anatomy") {
                                        Text("Cardiovascular System")
                                            .padding(.leading)
                                        Text("Respiratory System")
                                            .padding(.leading)
                                        Text("Nervous System")
                                            .padding(.leading)
                                    }
                                    
                                    DisclosureGroup("Physiology") {
                                        Text("Endocrine System")
                                            .padding(.leading)
                                        Text("Digestive System")
                                            .padding(.leading)
                                    }
                                    
                                    DisclosureGroup("Pathology") {
                                        Text("Cellular Pathology")
                                            .padding(.leading)
                                        Text("Immunopathology")
                                            .padding(.leading)
                                    }
                                }
                            }
                            .listStyle(SidebarListStyle()) // Ensure sidebar appearance
                        }
                        .navigationTitle("")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    // Toggle sidebar visibility
                                    withAnimation {
                                        sidebarVisibility = sidebarVisibility == .all ? .detailOnly : .all
                                    }
                                }) {
                                    Image(systemName: "sidebar.left")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    } detail: {
                        // Detail: Content based on selected tab
                        Group {
                            if let selectedTab = selectedTab {
                                switch selectedTab {
                                case .home:
                                    HomeScreenView(viewModel: viewModel)
                                case .library:
                                    DocumentLibraryView(viewModel: viewModel)
                                case .notes:
                                    MyNotesView(viewModel: viewModel,
                                                showFullScreen: .constant(false),
                                                selectedDocument: .constant(nil))
                                case .whiteboard:
                                    WhiteboardView(viewModel: viewModel)
                                case .profile:
                                    SettingsView(viewModel: viewModel)
                                }
                            } else {
                                // Default to Home view if nothing selected
                                HomeScreenView(viewModel: viewModel)
                                    .onAppear {
                                        // Auto-select home tab
                                        selectedTab = .home
                                    }
                            }
                        }
                        .accentColor(.green) // Maintain green accent color
                    }
                    .frame(maxHeight: .infinity) // Allow content to fill remaining space
                }
                
                // Semi-transparent overlay when To-Do list is visible (positioned below header)
                if showingTodoList {
                    Color.black
                        .opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showingTodoList = false
                            }
                        }
                        .offset(y: headerHeight) // Start below header
                        .frame(height: mainGeometry.size.height - headerHeight) // Only cover below header
                }
                
                // Right-side To-Do List (positioned to start exactly at the header boundary)
                HStack(spacing: 0) {
                    Spacer() // Push to right side
                    
                    ToDoListView(showingTodoList: $showingTodoList)
                        .frame(width: mainGeometry.size.width * 0.25) // Match approximate width of nav sidebar
                        .frame(maxWidth: 280) // Cap maximum width
                        .frame(minWidth: 250) // Set minimum width
                        .frame(height: mainGeometry.size.height - headerHeight) // Only as tall as area below header
                        .background(Color(.systemBackground))
                        .offset(x: showingTodoList ? 0 : mainGeometry.size.width)
                        .offset(y: headerHeight) // Position exactly below header
                        .animation(.spring(), value: showingTodoList)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: -2, y: 0)
                }
            }
            .ignoresSafeArea(edges: .bottom) // Allow content to extend to bottom
        }
        .onAppear {
            // Set initial selection to home
            if selectedTab == nil {
                selectedTab = .home
            }
            
            // Request notification permission on first launch
            requestNotificationPermission()
        }
    }
}

// Previews
//struct UpdatedMainInterface_Previews: PreviewProvider {
//    static var previews: some View {
////        UpdatedMainInterface()
////            .previewDevice("iPhone 14")
////            .previewDisplayName("Main Interface")
//        
//        // Additional preview for iPad to show sidebar
////        UpdatedMainInterface()
////            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
////            .previewDisplayName("Main Interface - iPad")
//    }
//}

// Supporting Views (Headers and To-Do List)
struct UpdatedHomeHeaderBar: View {
    @State private var searchText = ""
    @Binding var showingTodoList: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // App logo
            Image("logo") // Make sure to add logo asset
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(.leading, 16)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                TextField("Spotlight search", text: $searchText)
                    .font(.system(size: 16))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Theme toggle (with sun icon)
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 14, height: 14)
                
                Toggle("", isOn: .constant(true))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .labelsHidden()
                    .frame(width: 36)
            }
            .padding(.horizontal, 4)
            
            // Notification button
            Button(action: {
                // Show notifications
            }) {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            
            // Message button (To-Do List)
            Button(action: {
                withAnimation(.spring()) {
                    showingTodoList.toggle()
                }
            }) {
                Image(systemName: "message")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            
            // Calendar button
            Button(action: {
                // Show calendar
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            
            // Profile button
            Button(action: {
                // Show profile
            }) {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    )
            }
            .padding(.horizontal, 8)
            .padding(.trailing, 16)
        }
        .frame(height: 60)
        .background(Color(.systemBackground))
    }
}

struct ToDoListView: View {
    @Binding var showingTodoList: Bool
    @State private var filterText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title and count
            HStack {
                Text("To Do")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("4")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(4)
                    .background(Circle().fill(Color.purple.opacity(0.2)))
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        showingTodoList = false
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.purple))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
            
            // Task list
            ScrollView {
                VStack(spacing: 16) {
                    ToDoCardView(
                        priority: "Low",
                        priorityColor: .orange,
                        title: "Assignment Management",
                        description: "Break down the research paper into manageable tasks.",
                        avatars: ["person.circle.fill", "person.circle.fill"],
                        fileCount: 0
                    )
                    
                    ToDoCardView(
                        priority: "High",
                        priorityColor: .red,
                        title: "Exam Preparation",
                        description: "Create chapter summaries, practice past exam questions, and schedule group study for upcoming final examinations.",
                        avatars: ["person.circle.fill"],
                        fileCount: 3
                    )
                    
                    ToDoCardView(
                        priority: "High",
                        priorityColor: .red,
                        title: "Patient Case Analysis",
                        description: "Review 5 complex patient cases focusing on differential diagnosis.",
                        avatars: ["person.circle.fill", "person.circle.fill"],
                        fileCount: 0
                    )
                }
                .padding()
            }
            
            Spacer()
            
            // Chat bot footer
            HStack(spacing: 12) {
                Image("logo") // Replace with actual logo asset
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Acolyte Chat Bot")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.95))
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -2)
        }
        .background(Color(.systemBackground))
    }
}

struct ToDoCardView: View {
    let priority: String
    let priorityColor: Color
    let title: String
    let description: String
    let avatars: [String]
    let fileCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Priority label and menu
            HStack {
                Text(priority)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(priorityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.1))
                    .cornerRadius(6)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
            
            // Title and description
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Avatars and files
            HStack {
                // Avatars
                HStack(spacing: -8) {
                    ForEach(avatars.indices, id: \.self) { index in
                        Image(systemName: avatars[index])
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(index % 2 == 0 ? Color.blue : Color.green)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                }
                
                Spacer()
                
                // Files
                if fileCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(fileCount) files")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2)
    }
}
