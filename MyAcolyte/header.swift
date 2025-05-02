//import SwiftUI
//
//struct UpdatedHomeHeaderBar: View {
//    @State private var searchText = ""
//    @Binding var showingTodoList: Bool
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            // App logo
//            Image("logo") // Make sure to add logo asset
//                .resizable()
//                .scaledToFit()
//                .frame(width: 40, height: 40)
//                .padding(.leading, 16)
//            
//            // Search bar
//            HStack {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(.gray)
//                    .padding(.leading, 8)
//                
//                TextField("Spotlight search", text: $searchText)
//                    .font(.system(size: 16))
//            }
//            .padding(.vertical, 8)
//            .padding(.horizontal, 12)
//            .background(Color(.systemGray6))
//            .cornerRadius(20)
//            .padding(.horizontal, 8)
//            
//            Spacer()
//            
//            // Theme toggle (with sun icon)
//            HStack(spacing: 4) {
//                Circle()
//                    .fill(Color.yellow)
//                    .frame(width: 14, height: 14)
//                
//                Toggle("", isOn: .constant(true))
//                    .toggleStyle(SwitchToggleStyle(tint: .blue))
//                    .labelsHidden()
//                    .frame(width: 36)
//            }
//            .padding(.horizontal, 4)
//            
//            // Notification button
//            Button(action: {
//                // Show notifications
//            }) {
//                Image(systemName: "bell")
//                    .font(.system(size: 20))
//                    .foregroundColor(.primary)
//            }
//            .padding(.horizontal, 8)
//            
//            // Message button (To-Do List)
//            Button(action: {
//                withAnimation(.spring()) {
//                    showingTodoList.toggle()
//                }
//            }) {
//                Image(systemName: "message")
//                    .font(.system(size: 20))
//                    .foregroundColor(.primary)
//            }
//            .padding(.horizontal, 8)
//            
//            // Calendar button
//            Button(action: {
//                // Show calendar
//            }) {
//                Image(systemName: "calendar")
//                    .font(.system(size: 20))
//                    .foregroundColor(.primary)
//            }
//            .padding(.horizontal, 8)
//            
//            // Profile button
//            Button(action: {
//                // Show profile
//            }) {
//                Circle()
//                    .fill(Color.gray)
//                    .frame(width: 32, height: 32)
//                    .overlay(
//                        Image(systemName: "person.fill")
//                            .foregroundColor(.white)
//                            .font(.system(size: 16))
//                    )
//            }
//            .padding(.horizontal, 8)
//            .padding(.trailing, 16)
//        }
//        .frame(height: 60)
//        .background(Color(.systemBackground))
//    }
//}
//
//struct UpdatedHomeHeaderBar_Previews: PreviewProvider {
//    static var previews: some View {
//        UpdatedHomeHeaderBar(showingTodoList: .constant(false))
//            .previewLayout(.sizeThatFits)
//    }
//}
