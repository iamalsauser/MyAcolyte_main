import SwiftUI

struct PathView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var showingFolderMenu = false
    @State private var menuPosition: CGPoint = .zero
    @State private var selectedFolderIndex: Int? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Path navigation bar with breadcrumbs
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        // Home button
                        Button(action: {
                            withAnimation {
                                viewModel.navigateToRoot()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                
                                Text("Home")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .id("home")
                        
                        // Navigation actions
                        HStack(spacing: 12) {
                            // Navigate up button
                            Button(action: {
                                viewModel.navigateBack()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 11))
                                    
                                    Text("Up")
                                        .font(.system(size: 12))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(6)
                            }
                            
                            // History action buttons (placeholders for demo)
                            Button(action: {
                                // Back action
                            }) {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(6)
                            }
                            
                            Button(action: {
                                // Forward action
                            }) {
                                Image(systemName: "chevron.forward")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(6)
                            }
                        }
                        
                        if !viewModel.currentPath.isEmpty {
                            // Path separator
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            // Path items
                            ForEach(0..<viewModel.currentPath.count, id: \.self) { index in
                                Button(action: {
                                    navigateToPathIndex(index)
                                }) {
                                    HStack(spacing: 6) {
                                        if index == viewModel.currentPath.count - 1 {
                                            // Current folder
                                            Text(viewModel.currentPath[index])
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.primary)
                                        } else {
                                            // Parent folder
                                            Text(viewModel.currentPath[index])
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        index == viewModel.currentPath.count - 1 ?
                                        Color(UIColor.tertiarySystemBackground) : Color.clear
                                    )
                                    .cornerRadius(8)
                                }
                                .id("folder_\(index)")
                                .contextMenu {
                                    Button(action: {
                                        navigateToPathIndex(index)
                                    }) {
                                        Label("Open Folder", systemImage: "folder")
                                    }
                                    
                                    Button(action: {
                                        // For demo purposes
                                    }) {
                                        Label("Add to Favorites", systemImage: "star")
                                    }
                                    
                                    Button(action: {
                                        // For demo purposes
                                    }) {
                                        Label("Create Shortcut", systemImage: "arrow.right.square")
                                    }
                                }
                                
                                if index < viewModel.currentPath.count - 1 {
                                    // Path separator between folders
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // View options
                        HStack(spacing: 8) {
                            // Sort options menu
                            Menu {
                                ForEach(FileSystemViewModel.SortOrder.allCases, id: \.self) { order in
                                    Button(action: {
                                        viewModel.changeSortOrder(order)
                                    }) {
                                        Label(order.rawValue, systemImage: "arrow.up.arrow.down")
                                            .foregroundColor(.primary)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Sort")
                                        .font(.system(size: 12))
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 10))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(6)
                            }
                            
                            // View mode toggle
                            Button(action: {
                                viewModel.toggleViewMode()
                            }) {
                                Image(systemName: viewModel.viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onChange(of: viewModel.currentPath.count) { _, _ in
                    // Scroll to the last item in the path when it changes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if viewModel.currentPath.isEmpty {
                            scrollProxy.scrollTo("home", anchor: .trailing)
                        } else {
                            scrollProxy.scrollTo("folder_\(viewModel.currentPath.count - 1)", anchor: .trailing)
                        }
                    }
                }
            }
            
            // Navigation context info bar (only show when in a folder)
            if !viewModel.currentPath.isEmpty {
                HStack {
                    // Current folder info
                    VStack(alignment: .leading, spacing: 2) {
                        if let currentFolderId = viewModel.currentFolder,
                           let folder = viewModel.fileSystem.first(where: { $0.id == currentFolderId }) {
                            
                            // Item counts
                            
                            let items = viewModel.getCurrentItems()
                            let folderCount = items.filter { $0.type == .folder }.count
                            let fileCount = items.filter { $0.type == .file }.count
                            let whiteboardCount = items.filter { $0.type == .whiteboard }.count
                            
                            HStack(spacing: 12) {
                                // Folder name with path length
                                HStack(spacing: 6) {
                                    Text(folder.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    if viewModel.currentPath.count > 1 {
                                        Text("(\(viewModel.currentPath.count) levels)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Item counts
                                if folderCount > 0 {
                                    ItemCountBadge(count: folderCount, iconName: "folder.fill", color: .yellow)
                                }
                                
                                if fileCount > 0 {
                                    ItemCountBadge(count: fileCount, iconName: "doc.fill", color: .red)
                                }
                                
                                if whiteboardCount > 0 {
                                    ItemCountBadge(count: whiteboardCount, iconName: "scribble", color: .blue)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
    }
    
    // Navigate to specific path index
    private func navigateToPathIndex(_ index: Int) {
        // Need a helper method to find the folder ID for the path at this index
        // For now, if it's the last item, we're already there. If not, navigate back until we reach this level
        if index < viewModel.currentPath.count - 1 {
            // Calculate how many levels to go back
            let levelsBack = viewModel.currentPath.count - 1 - index
            for _ in 0..<levelsBack {
                viewModel.navigateBack()
            }
        }
    }
}

// Badge showing item counts
struct ItemCountBadge: View {
    let count: Int
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}
