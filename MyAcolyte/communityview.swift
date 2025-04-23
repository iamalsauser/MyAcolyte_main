import SwiftUI

struct CommunityView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showingLoginPrompt = false
    @State private var isLogged = false
    
    // Sample data for demo
    let featuredContent = [
        CommunityItem(title: "Advanced Math Notes", author: "MathGenius", type: .notes, downloads: 2453, rating: 4.7),
        CommunityItem(title: "Physics Formulas Collection", author: "ScienceTeacher", type: .pdf, downloads: 1876, rating: 4.5),
        CommunityItem(title: "Biology Diagrams", author: "BioStudies", type: .whiteboard, downloads: 1245, rating: 4.3),
        CommunityItem(title: "Chemistry Equations", author: "ChemMaster", type: .notes, downloads: 987, rating: 4.1)
    ]
    
    let popularTemplates = [
        CommunityItem(title: "Cornell Notes Template", author: "StudyPro", type: .notes, downloads: 5678, rating: 4.9),
        CommunityItem(title: "Weekly Planner", author: "Organizer", type: .whiteboard, downloads: 4567, rating: 4.8),
        CommunityItem(title: "Mind Map Template", author: "CreativeThinking", type: .whiteboard, downloads: 3456, rating: 4.6),
        CommunityItem(title: "Research Paper Notes", author: "AcademicWriter", type: .notes, downloads: 2345, rating: 4.5)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search community content", text: $searchText)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top)
            
            // Tab selector
            Picker("Content Type", selection: $selectedTab) {
                Text("Featured").tag(0)
                Text("Templates").tag(1)
                Text("My Shared").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Content based on selected tab
                    if selectedTab == 0 {
                        // Featured Content
                        SectionHeader(title: "Featured Content", buttonTitle: "See All")
                        
                        contentCarousel(items: featuredContent)
                        
                        SectionHeader(title: "Popular This Week", buttonTitle: "More")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(featuredContent.shuffled().prefix(4)) { item in
                                    SmallContentCard(item: item)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        SectionHeader(title: "Recently Added", buttonTitle: "Browse")
                        
                        // Grid layout for recent items
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                            ForEach(featuredContent.shuffled()) { item in
                                GridContentCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                        
                    } else if selectedTab == 1 {
                        // Templates
                        SectionHeader(title: "Popular Templates", buttonTitle: "See All")
                        
                        contentCarousel(items: popularTemplates)
                        
                        SectionHeader(title: "Categories", buttonTitle: "")
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                            CommunityCategoryButton(title: "Study Notes", systemImage: "note.text", color: .green)
                            CommunityCategoryButton(title: "Planning", systemImage: "calendar", color: .blue)
                            CommunityCategoryButton(title: "Science", systemImage: "atom", color: .purple)
                            CommunityCategoryButton(title: "Math", systemImage: "function", color: .red)
                            CommunityCategoryButton(title: "Languages", systemImage: "textformat", color: .orange)
                            CommunityCategoryButton(title: "Business", systemImage: "chart.bar", color: .teal)
                        }
                        .padding(.horizontal)
                        
                        SectionHeader(title: "Study Templates", buttonTitle: "More")
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                            ForEach(popularTemplates.shuffled()) { item in
                                GridContentCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                        
                    } else {
                        // My Shared Items
                        if isLogged {
                            VStack(spacing: 20) {
                                SectionHeader(title: "My Shared Content", buttonTitle: "Upload New")
                                
                                Text("You haven't shared any content yet.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                
                                Button(action: {
                                    // Share content action
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share Your First Content")
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Sharing Benefits")
                                        .font(.headline)
                                    
                                    BenefitRow(icon: "person.2.fill", text: "Help other students learn")
                                    BenefitRow(icon: "star.fill", text: "Earn reputation in the community")
                                    BenefitRow(icon: "arrow.up.heart.fill", text: "Get feedback on your content")
                                    BenefitRow(icon: "lock.fill", text: "Control sharing permissions")
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        } else {
                            // Login prompt
                            VStack(spacing: 25) {
                                Image(systemName: "person.crop.circle.badge.exclamationmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                Text("Sign In Required")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("You need to sign in to share content and access your shared items.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    // For demo purposes, toggle logged status
                                    isLogged = true
                                }) {
                                    Text("Sign In")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    // Create account action
                                }) {
                                    Text("Create Account")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .foregroundColor(.blue)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Community")
    }
    
    @ViewBuilder
    private func contentCarousel(items: [CommunityItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(items) { item in
                    FeaturedContentCard(item: item)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Models

struct CommunityItem: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let type: ContentType
    let downloads: Int
    let rating: Double
    
    enum ContentType {
        case pdf
        case notes
        case whiteboard
        
        var iconName: String {
            switch self {
            case .pdf: return "doc.fill"
            case .notes: return "note.text"
            case .whiteboard: return "scribble"
            }
        }
        
        var color: Color {
            switch self {
            case .pdf: return .red
            case .notes: return .green
            case .whiteboard: return .blue
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let buttonTitle: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
            
            if !buttonTitle.isEmpty {
                Button(action: {
                    // See all action
                }) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct FeaturedContentCard: View {
    let item: CommunityItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Type icon and indicator
            HStack {
                Image(systemName: item.type.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(item.type.color)
                    .cornerRadius(8)
                
                Spacer()
                
                // Ratings
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", item.rating))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            }
            
            // Title
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            // Author and downloads
            HStack {
                Text("By \(item.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down.circle")
                        .font(.caption2)
                    
                    Text("\(item.downloads)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            // Download button
            Button(action: {
                // Download action
            }) {
                Text("Download")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 220, height: 180)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct SmallContentCard: View {
    let item: CommunityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.type.iconName)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(item.type.color)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(item.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", item.rating))
                        .font(.caption)
                }
            }
        }
        .padding(8)
        .frame(width: 200)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct GridContentCard: View {
    let item: CommunityItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with type icon
            HStack {
                Image(systemName: item.type.iconName)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(item.type.color)
                    .cornerRadius(6)
                
                Spacer()
                
                Text(String(format: "%.1f", item.rating))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .padding(.top, 2)
            
            Text(item.author)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 1)
            
            Spacer()
            
            Button(action: {
                // Download action
            }) {
                HStack {
                    Text("Download")
                        .font(.caption)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.down.circle")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(6)
            }
        }
        .padding(12)
        .frame(height: 140)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct CommunityCategoryButton: View {
    let title: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Category action
        }) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(color)
                    .cornerRadius(8)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct CommunityView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommunityView(viewModel: FileSystemViewModel())
        }
    }
}
