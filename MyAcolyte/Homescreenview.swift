import SwiftUI

struct HomeScreenView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @State private var showingFilter = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Tracker Section
                trackerSection
                
                // Subjects Section
                subjectsSection
                
                // Collaborative Study Section
                collaborativeStudySection
                
                // Continue Reading Section
                continueReadingSection
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingFilter.toggle()
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.primary)
                        Text("Filter")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Tracker Section
    
    private var trackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tracker")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 15) {
                // Conceptual Usage
                VStack(alignment: .leading, spacing: 16) {
                    Text("Conceptual usage")
                        .font(.headline)
                    
                    // List of texts with progress bars
                    VStack(spacing: 12) {
                        ProgressItemView(
                            title: "Human Anatomy by Vishram Singh",
                            progress: 0.44,
                            progressColor: .red,
                            percentage: "44%"
                        )
                        
                        ProgressItemView(
                            title: "Guyton and Hall Textbook of Medical...",
                            progress: 0.56,
                            progressColor: .blue,
                            percentage: "56%"
                        )
                        
                        ProgressItemView(
                            title: "K.D. Tripathi's Essentials of Medical...",
                            progress: 0.22,
                            progressColor: .purple,
                            percentage: "22%"
                        )
                        
                        ProgressItemView(
                            title: "Davidson's Principles and Practice...",
                            progress: 0.79,
                            progressColor: .orange,
                            percentage: "79%"
                        )
                    }
                }
                .frame(width: 450)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2)
                
                // Right side stats (cards)
                VStack(spacing: 12) {
                    // Row 1: Cumulative Progress and Knowledge
                    HStack(spacing: 12) {
                        // Cumulative Progress
                        StatCard(title: "Cumulative Progress") {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .trim(from: 0, to: 0.75)
                                    .stroke(Color.green, lineWidth: 10)
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("75%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 10)
                        }
                        
                        // Current Knowledge
                        StatCard(title: "Current Knowledge") {
                            VStack(alignment: .leading) {
                                Text("86%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                // Simple line chart
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 20))
                                    path.addCurve(
                                        to: CGPoint(x: 150, y: 20),
                                        control1: CGPoint(x: 30, y: 10),
                                        control2: CGPoint(x: 80, y: 30)
                                    )
                                }
                                .stroke(Color.green, lineWidth: 2)
                                .frame(height: 40)
                            }
                        }
                    }
                    
                    // Row 2: Total study hour and Subject Activity
                    HStack(spacing: 12) {
                        // Total study hour
                        StatCard(title: "Total study hour") {
                            VStack(alignment: .leading) {
                                Text("23")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                // Simple line chart
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 20))
                                    path.addCurve(
                                        to: CGPoint(x: 150, y: 20),
                                        control1: CGPoint(x: 30, y: 10),
                                        control2: CGPoint(x: 80, y: 30)
                                    )
                                }
                                .stroke(Color.green, lineWidth: 2)
                                .frame(height: 40)
                            }
                        }
                        
                        // Subject Activity
                        StatCard(title: "Subject Activity") {
                            Path { path in
                                // Create a wavy line for subject activity
                                let height: CGFloat = 80
                                let points = 50
                                let segment = 180 / CGFloat(points)
                                
                                path.move(to: CGPoint(x: 0, y: height/2))
                                
                                for i in 1...points {
                                    let x = CGFloat(i) * segment
                                    let y = height/2 + 20 * sin(CGFloat(i) / 5)
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            .stroke(Color.green, lineWidth: 2)
                            .frame(height: 100)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subjects Section
    
    private var subjectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subjects")
                .font(.title2)
                .fontWeight(.bold)
            
            // Folder grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 16) {
                // New Folder button
                Button(action: {
                    // Create new folder
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .frame(width: 80, height: 70)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        
                        Text("New Folder")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
                
                // Quick Revision Anatomy folders
                ForEach(0..<5) { _ in
                    VStack(spacing: 8) {
                        Image("folder-blue") // Replace with actual folder image or use system image
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 70)
                        
                        Text("Quick Revision\nAnatomy")
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2)
        }
    }
    
    // MARK: - Collaborative Study Section
    
    private var collaborativeStudySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Collaborative study")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                ForEach(0..<4) { index in
                    HStack(spacing: 12) {
                        // Document icon
                        Image(systemName: "doc.text")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        // Title and subject
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Guyton and hall")
                                .font(.headline)
                            Text("- physiology")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Collaborators
                        HStack(spacing: 6) {
                            ForEach(0..<4) { _ in
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("+3 more")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Notification count
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 1)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2)
        }
    }
    
    // MARK: - Continue Reading Section
    
    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Continue reading")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // View All action
                }) {
                    HStack {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            VStack(spacing: 16) {
                ForEach([
                    ("Unit 5- Medical Apparatus", 0.25, Color.orange),
                    ("Unit 1- Medical Apparatus", 0.60, Color.red),
                    ("Unit 2- Medical Apparatus", 0.45, Color.blue),
                    ("Unit 6- Medical Apparatus", 0.15, Color.purple)
                ], id: \.0) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.0)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(Int(item.1 * 100))%")
                                .font(.subheadline)
                                .foregroundColor(item.2)
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 8)
                                    .opacity(0.2)
                                    .foregroundColor(item.2)
                                
                                Rectangle()
                                    .frame(width: geometry.size.width * item.1, height: 8)
                                    .foregroundColor(item.2)
                            }
                            .cornerRadius(4)
                        }
                        .frame(height: 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 1)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2)
        }
    }
}

// MARK: - Supporting Components

struct ProgressItemView: View {
    let title: String
    let progress: Double
    let progressColor: Color
    let percentage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            HStack(spacing: 8) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 6)
                            .opacity(0.2)
                            .foregroundColor(progressColor)
                        
                        Rectangle()
                            .frame(width: geometry.size.width * progress, height: 6)
                            .foregroundColor(progressColor)
                    }
                    .cornerRadius(3)
                }
                .frame(height: 6)
                
                // Percentage
                Text(percentage)
                    .font(.caption)
                    .foregroundColor(progressColor)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
}

struct StatCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2)
    }
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView(viewModel: FileSystemViewModel())
    }
}
