import SwiftUI

struct MainFileSystemView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var showFullScreen = false
    @State private var selectedDocument: DocumentItem?
    @State private var selectedTab: SidebarTab = .home
    @State private var isCollapsed = false
    @State private var showSearchBar = false
    @State private var searchText = ""
    
    enum SidebarTab: String, CaseIterable, Identifiable {
        case home = "Home"
        case myPDF = "My PDF"
        case myNotes = "My Notes"
        case whiteboard = "Whiteboard"
        case community = "Community"
        case settings = "Settings"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .myPDF: return "doc.fill"
            case .myNotes: return "note.text.fill"
            case .whiteboard: return "scribble"
            case .community: return "person.3.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .home: return .blue
            case .myPDF: return .red
            case .myNotes: return .green
            case .whiteboard: return .purple
            case .community: return .orange
            case .settings: return .gray
            }
        }
    }

    var body: some View {
        NavigationView {
            // Enhanced Sidebar
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Logo Section
                    VStack(spacing: 12) {
                        Image("logo") // App logo
                            .resizable()
                            .scaledToFit()
                            .frame(width: isCollapsed ? 40 : 80, height: isCollapsed ? 40 : 80)
                            .padding(.top, isCollapsed ? 10 : 20)
                        
                        if !isCollapsed {
                            Text("MyAcolyte")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.bottom, 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.2)),
                        alignment: .bottom
                    )
                    
                    // Search Bar (toggleable)
                    if showSearchBar && !isCollapsed {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search files...", text: $searchText)
                                .font(.subheadline)
                        }
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
                    // Navigation Tabs
                    ScrollView {
                        VStack(spacing: 5) {
                            ForEach(SidebarTab.allCases) { tab in
                                Button(action: {
                                    selectedTab = tab
                                }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: tab.icon)
                                            .foregroundColor(selectedTab == tab ? tab.color : .secondary)
                                            .font(.system(size: 18))
                                            .frame(width: 24, height: 24)
                                        
                                        if !isCollapsed {
                                            Text(tab.rawValue)
                                                .foregroundColor(selectedTab == tab ? tab.color : .primary)
                                                .font(.subheadline)
                                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                            
                                            Spacer()
                                            
                                            if selectedTab == tab {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(tab.color)
                                                    .frame(width: 3, height: 16)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, isCollapsed ? 12 : 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedTab == tab ?
                                                  tab.color.opacity(0.1) :
                                                  Color.clear)
                                            .padding(.horizontal, isCollapsed ? 4 : 8)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Recent Folders Section (when expanded)
                            if !isCollapsed {
                                Divider()
                                    .padding(.vertical, 10)
                                
                                Text("RECENT FOLDERS")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                                
                                let folders = viewModel.fileSystem.filter { $0.type == .folder }
                                                        .prefix(5)
                                
                                if folders.isEmpty {
                                    Text("No recent folders")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                } else {
                                    ForEach(Array(folders), id: \.id) { folder in
                                        Button(action: {
                                            viewModel.navigateToFolder(item: folder)
                                        }) {
                                            HStack {
                                                Image(systemName: "folder.fill")
                                                    .foregroundColor(Color(UIColor.systemYellow))
                                                    .font(.system(size: 14))
                                                    .frame(width: 20, height: 20)
                                                
                                                Text(folder.name)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                    .foregroundColor(.primary)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }

                                // Storage Usage (when expanded)
                                Divider()
                                    .padding(.vertical, 10)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("STORAGE")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    // Storage usage bar
                                    VStack(alignment: .leading, spacing: 6) {
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(height: 6)
                                                
                                                // Fake storage usage for demo (30%)
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.blue)
                                                    .frame(width: geometry.size.width * 0.3, height: 6)
                                            }
                                        }
                                        .frame(height: 6)
                                        
                                        HStack {
                                            Text("3.2 GB of 10 GB used")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Text("30%")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    
                    Spacer()
                    
                    // Bottom tools
                    VStack(spacing: 16) {
                        if !isCollapsed {
                            Divider()
                        }
                        
                        HStack {
                            // Toggle search button
                            Button(action: {
                                if !isCollapsed {
                                    withAnimation {
                                        showSearchBar.toggle()
                                    }
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                                    .frame(width: 36, height: 36)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(isCollapsed ? 0 : 1)
                            
                            Spacer()
                            
                            // Collapse/expand sidebar
                            Button(action: {
                                withAnimation(.spring()) {
                                    isCollapsed.toggle()
                                    if isCollapsed {
                                        showSearchBar = false
                                    }
                                }
                            }) {
                                Image(systemName: isCollapsed ? "chevron.right" : "chevron.left")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                                    .frame(width: 36, height: 36)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, isCollapsed ? 12 : 16)
                        .padding(.bottom, 16)
                    }
                }
                .frame(width: isCollapsed ? 60 : 240)
            }
            .frame(minWidth: isCollapsed ? 60 : 240)

            // Main Content
            switch selectedTab {
            case .home:
                HomeView(viewModel: viewModel)
            case .myPDF:
                MyPDFView(viewModel: viewModel)
            case .myNotes:
                MyNotesView(viewModel: viewModel, showFullScreen: $showFullScreen, selectedDocument: $selectedDocument)
            case .whiteboard:
                WhiteboardView(viewModel: viewModel)
            case .community:
                CommunityView(viewModel: viewModel)
            case .settings:
                SettingsView(viewModel: viewModel)
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

// MARK: - File Grid View (unchanged)
struct FileGridView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @Binding var showFullScreen: Bool
    @Binding var selectedDocument: DocumentItem?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                if !viewModel.selectionMode {
                    Button(action: { viewModel.createFolder() }) {
                        FolderButtonView(label: "New Folder", icon: "folder.badge.plus")
                    }
                }

                ForEach(viewModel.getCurrentItems()) { item in
                    Button(action: {
                        selectedDocument = DocumentItem(id: item.id, title: item.name)
                        showFullScreen = true
                    }) {
                        FileItemGridView(viewModel: viewModel, item: item)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - File List View (unchanged)
struct FileListView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @Binding var showFullScreen: Bool
    @Binding var selectedDocument: DocumentItem?

    var body: some View {
        List {
            if !viewModel.selectionMode {
                Button(action: { viewModel.createFolder() }) {
                    FolderButtonView(label: "New Folder", icon: "folder.badge.plus")
                }
                .frame(height: 50)
            }

            ForEach(viewModel.getCurrentItems()) { item in
                Button(action: {
                    selectedDocument = DocumentItem(id: item.id, title: item.name)
                    showFullScreen = true
                }) {
                    FileItemListView(viewModel: viewModel, item: item)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Folder Button View (unchanged)
struct FolderButtonView: View {
    var label: String
    var icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)

            Text(label)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Recent Files View (unchanged)
struct RecentFilesView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @Binding var showFullScreen: Bool
    @Binding var selectedDocument: DocumentItem?

    var body: some View {
        if !viewModel.recentFiles.isEmpty {
            Section(header: Text("Recent Files").font(.headline)) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.recentFiles) { item in
                            Button(action: {
                                selectedDocument = DocumentItem(id: item.id, title: item.name)
                                showFullScreen = true
                            }) {
                                FilePreviewView(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - File Preview View (unchanged)
struct FilePreviewView: View {
    var item: FileSystemItem

    var body: some View {
        VStack {
            FileIcon(item: item, size: 50)
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 80)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 100)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}
