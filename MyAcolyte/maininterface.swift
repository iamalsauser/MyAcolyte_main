import SwiftUI

//@main
//struct MyAcolyteApp: App {
//    var body: some Scene {
//        WindowGroup {
//            MainInterface()
//        }
//    }
//}

struct MainInterface: View {
    @StateObject private var viewModel = FileSystemViewModel()
    @State private var selectedTab: TabItem? = .home // Optional to allow no selection initially
    
    enum TabItem: String, CaseIterable {
        case home = "house.fill"
        case library = "doc.fill"
        case notes = "note.text.fill"
        case whiteboard = "scribble"
        case profile = "person.circle.fill"
        
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
        NavigationSplitView {
            // Sidebar: List of navigation items
            List(TabItem.allCases, id: \.self, selection: $selectedTab) { tab in
                Label {
                    Text(tab.title)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: tab.rawValue)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Menu")
            .listStyle(SidebarListStyle()) // Ensure sidebar appearance
        } detail: {
            // Detail: Content based on selected tab
            Group {
                if let selectedTab = selectedTab {
                    switch selectedTab {
                    case .home:
                        HomeView(viewModel: viewModel)
                    case .library:
//                        NavigationView {
                            DocumentLibraryView(viewModel: viewModel)
//                        }
                    case .notes:
//                        NavigationView {
                            MyNotesView(viewModel: viewModel,
                                        showFullScreen: .constant(false),
                                        selectedDocument: .constant(nil))
//                        }
                    case .whiteboard:
//                        NavigationView {
                            WhiteboardView(viewModel: viewModel)
//                        }
                    case .profile:
//                        NavigationView {
                            SettingsView(viewModel: viewModel)
//                        }
                    }
                } else {
                    // Placeholder when no tab is selected
                    Text("Select a section from the sidebar")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .accentColor(.green) // Maintain green accent color
        }
        .onAppear {
            // Request notification permission on first launch
            requestNotificationPermission()
            
            // Set the tab bar appearance (optional, as TabView is removed)
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

// Add PreviewProvider for MainInterface
struct MainInterface_Previews: PreviewProvider {
    static var previews: some View {
        MainInterface()
            .previewDevice("iPhone 14")
            .previewDisplayName("Main Interface")
        
        // Additional preview for iPad to show sidebar
        MainInterface()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("Main Interface - iPad")
    }
}
