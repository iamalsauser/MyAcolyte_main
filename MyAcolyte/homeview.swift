import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var showDocumentPicker = false
    @State private var selectedDocument: DocumentItem?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Search bar at the top
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search pdf", text: .constant(""))
                        .font(.system(size: 16))
                }
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)
                
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
                            // Show recent files
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
                            RecentFileRow(item: item)
                        }
                        
                        // If no recent files, add some dummy data
                        if viewModel.recentFiles.isEmpty {
                            RecentFileRow(item: FileSystemItem(id: "1", name: "NEET_PG_Preparation_Materials_2025.pdf", type: .file, fileType: .pdf))
                            RecentFileRow(item: FileSystemItem(id: "2", name: "NEET_PG_Preparation_Materials_2025.pdf", type: .file, fileType: .pdf))
                            RecentFileRow(item: FileSystemItem(id: "3", name: "NEET_PG_Preparation_Materials_2025.pdf", type: .file, fileType: .pdf))
                        }
                    }
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Library section (heading only)
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
                
                // Continue reading section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Continue reading")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ContinueReadingItem(
                            title: "Unit 9- Anatomy",
                            lastStudied: "Last studied",
                            progress: 0.5,
                            percentage: "50%",
                            user: "LOPYSTEP",
                            timeSpent: "20mins",
                            date: "Today"
                        )
                        
                        ContinueReadingItem(
                            title: "Unit 9- Anatomy",
                            lastStudied: "Last studied",
                            progress: 0.7,
                            percentage: "70%",
                            user: "LOPYSTEP",
                            timeSpent: "15mins",
                            date: "Yesterday"
                        )
                        
                        ContinueReadingItem(
                            title: "Unit 9- Anatomy",
                            lastStudied: "Last studied",
                            progress: 0.4,
                            percentage: "40%",
                            user: "LOPYSTEP",
                            timeSpent: "5mins",
                            date: "12days ago"
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Optimize your study section
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
                            ]
                        )
                        
                        ReviewCard(
                            subject: "Anatomy",
                            title: "Due for review",
                            bulletPoints: [
                                "Key improvement areas",
                                "Low understanding - start here"
                            ]
                        )
                        
                        ReviewCard(
                            subject: "Anatomy",
                            title: "Improvement Zones",
                            bulletPoints: [
                                "These topics are due for review",
                                "Time to reinforce key concepts"
                            ]
                        )
                        
                        ReviewCard(
                            subject: "Anatomy",
                            title: "Due for review",
                            bulletPoints: [
                                "These topics are due for review",
                                "Time to reinforce key concepts"
                            ]
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
    }
}

// Components for the Home View

struct RecentFileRow: View {
    let item: FileSystemItem
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            Text(item.name)
                .font(.system(size: 14))
                .lineLimit(1)
            
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
            
            Button(action: {
                // Show more options
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
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
    
    var body: some View {
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
    }
}

struct ReviewCard: View {
    let subject: String
    let title: String
    let bulletPoints: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(subject)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
            
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
            
            Button(action: {
                // Review action
            }) {
                Text("Review now")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
