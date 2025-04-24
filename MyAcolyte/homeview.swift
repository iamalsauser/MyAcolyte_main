import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var showDocumentPicker = false
    @State private var selectedDocument: DocumentItem?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Top heading
                Text("Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Progress cards section
                HStack(spacing: 15) {
                    // Cumulative Progress
                    ProgressCard(
                        title: "Cumulative Progress",
                        content: {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: 0.75)
                                    .stroke(Color.green, lineWidth: 10)
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("75%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 10)
                        }
                    )
                    
                    // Current Knowledge
                    ProgressCard(
                        title: "Current Knowledge",
                        content: {
                            VStack(alignment: .leading) {
                                Text("86%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                // Simple line chart
                                HStack(spacing: 2) {
                                    ForEach(0..<10) { i in
                                        let height = [0.3, 0.5, 0.4, 0.6, 0.7, 0.6, 0.8, 0.7, 0.9, 0.85][i]
                                        
                                        Rectangle()
                                            .fill(Color.green.opacity(0.7))
                                            .frame(width: 10, height: 40 * CGFloat(height))
                                    }
                                }
                                .frame(height: 50, alignment: .bottom)
                            }
                        }
                    )
                    
                    // Total study hours
                    ProgressCard(
                        title: "Total study hour",
                        content: {
                            VStack(alignment: .leading) {
                                Text("23")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                // Simple line chart
                                HStack(spacing: 2) {
                                    ForEach(0..<10) { i in
                                        let height = [0.2, 0.4, 0.3, 0.5, 0.6, 0.5, 0.7, 0.6, 0.8, 0.9][i]
                                        
                                        Rectangle()
                                            .fill(Color.green.opacity(0.7))
                                            .frame(width: 10, height: 40 * CGFloat(height))
                                    }
                                }
                                .frame(height: 50, alignment: .bottom)
                            }
                        }
                    )
                }
                .padding(.horizontal)
                
                // Conceptual usage
                VStack(alignment: .leading, spacing: 15) {
                    Text("Conceptual usage")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        // Human Anatomy
                        UsageItem(
                            title: "Human Anatomy by Vishram Singh",
                            progress: 0.44,
                            progressColor: .red
                        )
                        
                        // Guyton and Hall
                        UsageItem(
                            title: "Guyton and Hall Textbook of Medical...",
                            progress: 0.56,
                            progressColor: .blue
                        )
                        
                        // K.D. Tripathi
                        UsageItem(
                            title: "K.D. Tripathi's Essentials of Medical...",
                            progress: 0.22,
                            progressColor: .purple
                        )
                        
                        // Davidson's
                        UsageItem(
                            title: "Davidson's Principles and Practice...",
                            progress: 0.79,
                            progressColor: .orange
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Subject activity chart
                VStack(alignment: .leading, spacing: 15) {
                    Text("Subject Activity")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ZStack {
                        // Line chart placeholder
                        HStack(spacing: 2) {
                            ForEach(0..<30) { i in
                                let x = Double(i) / 30.0
                                let y1 = 0.5 + 0.3 * sin(Double(i) / 5.0)
                                let y2 = 0.5 + 0.3 * sin(Double(i) / 3.0 + 1.0)
                                
                                ZStack {
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 50 * (1-y1)))
                                        path.addLine(to: CGPoint(x: 0, y: 100))
                                    }
                                    .stroke(Color.green.opacity(0.2), lineWidth: 10)
                                    
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 50 * (1-y2)))
                                        path.addLine(to: CGPoint(x: 0, y: 100))
                                    }
                                    .stroke(Color.blue.opacity(0.1), lineWidth: 10)
                                }
                                .frame(width: 10)
                            }
                        }
                        .frame(height: 100)
                        
                        // Curve lines
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 50))
                            
                            for i in 0..<30 {
                                let x = CGFloat(i) * 10
                                let y = 50 + 30 * sin(CGFloat(i) / 5.0)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(Color.green, lineWidth: 2)
                        
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 50))
                            
                            for i in 0..<30 {
                                let x = CGFloat(i) * 10
                                let y = 50 + 30 * sin(CGFloat(i) / 3.0 + 1.0)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                        
                        // Activity point
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .offset(x: 150, y: -20)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Subjects
                VStack(alignment: .leading, spacing: 15) {
                    Text("Subjects")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            // New Folder
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.purple.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                        .frame(width: 80, height: 60)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(.purple)
                                }
                                .frame(width: 80, height: 60)
                                
                                Text("New Folder")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 100)
                            
                            // Create 3 folders for Quick Revision Anatomy
                            ForEach(0..<3) { _ in
                                VStack {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.blue)
                                    
                                    Text("Quick Revision\nAnatomy")
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 100)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Collaborative study
                VStack(alignment: .leading, spacing: 15) {
                    Text("Collaborative study")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text("Guyton and hall")
                                .font(.headline)
                            Text("- physiology")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                        
                        // Profile pictures
                        HStack(spacing: -5) {
                            ForEach(0..<3) { _ in
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                        }
                        
                        Text("+3 more")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                            
                            Text("1")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                        }
                        .frame(width: 25, height: 25)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Continue reading
                VStack(alignment: .leading, spacing: 15) {
                    Text("Continue reading")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("Unit 5- Medical Apparatus")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("25%")
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                    
                    ProgressBar(value: 0.25, color: .orange)
                        .frame(height: 10)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full-screen layout
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

// MARK: - Supporting Components

struct ProgressCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct UsageItem: View {
    let title: String
    let progress: Double
    let progressColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .lineLimit(1)
            
            HStack {
                ProgressBar(value: progress, color: progressColor)
                    .frame(height: 8)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(progressColor)
                    .frame(width: 40)
            }
        }
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(.systemGray5))
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(color)
            }
            .cornerRadius(45)
        }
    }
}

// MARK: - Previews

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock FileSystemViewModel for preview
        let viewModel = FileSystemViewModel()
        
        Group {
            // Preview for HomeView
            HomeView(viewModel: viewModel)
                .previewDevice("iPhone 14")
                .previewDisplayName("Home View")
            
            // Preview for ProgressCard
            ProgressCard(title: "Sample Progress") {
                Text("Sample Content")
                    .font(.title)
                    .foregroundColor(.green)
            }
            .previewDisplayName("Progress Card")
            .padding()
            .previewLayout(.sizeThatFits)
            
            // Preview for UsageItem
            UsageItem(
                title: "Sample Book Title",
                progress: 0.65,
                progressColor: .blue
            )
            .previewDisplayName("Usage Item")
            .padding()
            .previewLayout(.sizeThatFits)
            
            // Preview for ProgressBar
            ProgressBar(value: 0.75, color: .orange)
                .frame(height: 10)
                .previewDisplayName("Progress Bar")
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
