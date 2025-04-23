import SwiftUI

struct MainInterface: View {
    @StateObject private var viewModel = FileSystemViewModel()
    @State private var selectedTab: TabItem = .home
    
    enum TabItem: String, CaseIterable {
        case home = "home"
        case library = "book"
        case notes = "note.text"
        case flashcards = "rectangle.on.rectangle"
        case profile = "person.circle"
        
        var icon: String {
            return self.rawValue
        }
    }
    
    var body: some View {
        ZStack {
            // Main content area
            VStack(spacing: 0) {
                switch selectedTab {
                case .home:
                    HomeView(viewModel: viewModel)
                case .library:
                    // Using the new DocumentLibraryView here instead of LibraryView
                    DocumentLibraryView(viewModel: viewModel)
                case .notes:
                    MyNotesView(viewModel: viewModel,
                                showFullScreen: .constant(false),
                                selectedDocument: .constant(nil))
                case .flashcards:
                    WhiteboardView(viewModel: viewModel)
                case .profile:
                    SettingsView(viewModel: viewModel)
                }
                
                // Bottom navigation bar
                BottomNavigationBar(selectedTab: $selectedTab)
            }
            
            // Notification button (top right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        // Show notifications
                    }) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
        .onAppear {
            // Request notification permission on first launch
            requestNotificationPermission()
        }
    }
}

struct BottomNavigationBar: View {
    @Binding var selectedTab: MainInterface.TabItem
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainInterface.TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == tab ? .green : .gray)
                        
                        Text(tab == .library ? "Library" : tab.rawValue.capitalized)
                            .font(.system(size: 12))
                            .foregroundColor(selectedTab == tab ? .green : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}
