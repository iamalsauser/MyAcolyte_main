//import SwiftUI
//
//struct ToDoListView: View {
//    @Binding var showingTodoList: Bool
//    @State private var filterText = ""
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // Header with title and count
//            HStack {
//                Text("To Do")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                
//                Spacer()
//                
//                Text("4")
//                    .font(.caption)
//                    .foregroundColor(.purple)
//                    .padding(4)
//                    .background(Circle().fill(Color.purple.opacity(0.2)))
//                
//                Button(action: {
//                    withAnimation(.easeInOut) {
//                        showingTodoList = false
//                    }
//                }) {
//                    Image(systemName: "plus")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(.white)
//                        .padding(4)
//                        .background(Circle().fill(Color.purple))
//                }
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 12)
//            
//            Divider()
//            
//            // Task list
//            ScrollView {
//                VStack(spacing: 16) {
//                    ToDoCardView(
//                        priority: "Low",
//                        priorityColor: .orange,
//                        title: "Assignment Management",
//                        description: "Break down the research paper into manageable tasks.",
//                        avatars: ["person.circle.fill", "person.circle.fill"],
//                        fileCount: 0
//                    )
//                    
//                    ToDoCardView(
//                        priority: "High",
//                        priorityColor: .red,
//                        title: "Exam Preparation",
//                        description: "Create chapter summaries, practice past exam questions, and schedule group study for upcoming final examinations.",
//                        avatars: ["person.circle.fill"],
//                        fileCount: 3
//                    )
//                    
//                    ToDoCardView(
//                        priority: "High",
//                        priorityColor: .red,
//                        title: "Patient Case Analysis",
//                        description: "Review 5 complex patient cases focusing on differential diagnosis.",
//                        avatars: ["person.circle.fill", "person.circle.fill"],
//                        fileCount: 0
//                    )
//                }
//                .padding()
//            }
//            
//            Spacer()
//            
//            // Chat bot footer
//            HStack(spacing: 12) {
//                Image("logo") // Replace with actual logo asset
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 28, height: 28)
//                
//                VStack(alignment: .leading, spacing: 2) {
//                    Text("Acolyte Chat Bot")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(.primary)
//                }
//                
//                Spacer()
//            }
//            .padding()
//            .background(Color(.systemBackground).opacity(0.95))
//            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -2)
//        }
//        .background(Color(.systemBackground))
//    }
//}
//
//struct ToDoCardView: View {
//    let priority: String
//    let priorityColor: Color
//    let title: String
//    let description: String
//    let avatars: [String]
//    let fileCount: Int
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            // Priority label and menu
//            HStack {
//                Text(priority)
//                    .font(.caption)
//                    .fontWeight(.medium)
//                    .foregroundColor(priorityColor)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(priorityColor.opacity(0.1))
//                    .cornerRadius(6)
//                
//                Spacer()
//                
//                Image(systemName: "ellipsis")
//                    .foregroundColor(.gray)
//            }
//            
//            // Title and description
//            Text(title)
//                .font(.headline)
//                .foregroundColor(.primary)
//            
//            Text(description)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .lineLimit(2)
//                .multilineTextAlignment(.leading)
//            
//            // Avatars and files
//            HStack {
//                // Avatars
//                HStack(spacing: -8) {
//                    ForEach(avatars.indices, id: \.self) { index in
//                        Image(systemName: avatars[index])
//                            .font(.system(size: 16))
//                            .foregroundColor(.white)
//                            .frame(width: 24, height: 24)
//                            .background(
//                                Circle()
//                                    .fill(index % 2 == 0 ? Color.blue : Color.green)
//                            )
//                            .overlay(
//                                Circle()
//                                    .stroke(Color.white, lineWidth: 1.5)
//                            )
//                    }
//                }
//                
//                Spacer()
//                
//                // Files
//                if fileCount > 0 {
//                    HStack(spacing: 4) {
//                        Image(systemName: "doc.fill")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                        
//                        Text("\(fileCount) files")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                }
//            }
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.05), radius: 2)
//    }
//}
//
//struct ToDoListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ToDoListView(showingTodoList: .constant(true))
//            .frame(width: 280)
//            .previewLayout(.sizeThatFits)
//    }
//}
