import SwiftUI

struct LibraryView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var showDocumentPicker = false
    @State private var searchText = ""
    @State private var selectedFolder: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with search and filters
                HStack {
                    Text("Library")
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                    
                    HStack {
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
                        
                        // Filter dropdown
                        Menu {
                            Button("All Documents", action: { selectedFolder = nil })
                            Button("Anatomy", action: { selectedFolder = "Anatomy" })
                            Button("Physiology", action: { selectedFolder = "Physiology" })
                            Button("Biochemistry", action: { selectedFolder = "Biochemistry" })
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Course folders
                VStack(spacing: 16) {
                    // Anatomy section (7 entries in the example)
                    ForEach(1...7, id: \.self) { index in
                        StudyFolderRow(
                            title: "Anatomy & Physiology",
                            category: "Anatomy",
                            progress: Double.random(in: 0.3...0.8),
                            completionText: "3/5 completed",
                            daysAgo: index == 4 ? "Today" : "\(index) days ago"
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 60)
            }
            .padding(.top)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(showPicker: $showDocumentPicker) { url in
                viewModel.importPDF(url: url)
            }
        }
    }
}

struct StudyFolderRow: View {
    let title: String
    let category: String
    let progress: Double
    let completionText: String
    let daysAgo: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Folder icon
            Image(systemName: "folder.fill")
                .foregroundColor(.green)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .padding(4)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(category)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                // Progress bar
                HStack {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(height: 5)
                            .foregroundColor(Color.gray.opacity(0.3))
                            .cornerRadius(2.5)
                        
                        Rectangle()
                            .frame(width: 150 * progress, height: 5)
                            .foregroundColor(.green)
                            .cornerRadius(2.5)
                    }
                    .frame(width: 150)
                    
                    Text(completionText)
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Time indicator
            Text(daysAgo)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
