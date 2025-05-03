import SwiftUI

struct FileSystemView: View {
    @State private var showingSplash = true
    
    var body: some View {
        ZStack {
            if showingSplash {
                SplashScreenView()
            } else {
                MainInterface()
            }
        }
        .onAppear {
            // Show splash screen for 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showingSplash = false
                }
            }
        }
    }
}
