import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0
    @State private var scale = 0.8
    @State private var showAppName = false
    @State private var showTagline = false
    @State private var showProgress = false
    
    var body: some View {
        ZStack {
            // Background gradient - using green to match the app theme
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1A8E5F"), Color(hex: "#166D4A")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative elements - medical theme
            ZStack {
                // Medical themed background elements
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat(80 + index * 40))
                        .offset(
                            x: CGFloat.random(in: -120...120),
                            y: CGFloat.random(in: -250...250)
                        )
                        .blur(radius: 5)
                }
                
                // Animated particles
                ForEach(0..<15) { index in
                    Image(systemName: ["cross.fill", "heart.fill", "staroflife.fill"][index % 3])
                        .font(.system(size: CGFloat.random(in: 12...20)))
                        .foregroundColor(.white.opacity(0.4))
                        .offset(
                            x: CGFloat.random(in: -180...180),
                            y: CGFloat.random(in: -300...300)
                        )
                        .opacity(isAnimating ? Double.random(in: 0.3...0.7) : 0)
                        .animation(
                            Animation
                                .easeInOut(duration: Double.random(in: 1.0...2.0))
                                .repeatForever()
                                .delay(Double.random(in: 0...0.5)),
                            value: isAnimating
                        )
                }
            }
            .opacity(isAnimating ? 1 : 0)
            .animation(.easeIn(duration: 1.2), value: isAnimating)
            
            // Main content
            VStack(spacing: 20) {
                // App logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "#1A8E5F"))
                }
                .opacity(opacity)
                .scaleEffect(scale)
                
                // App name
                Text("MedStudy")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(showAppName ? 1 : 0)
                    .offset(y: showAppName ? 0 : 20)
                
                // Tagline
                Text("Your Medical Education Companion")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 15)
                
                // Progress indicator
                if showProgress {
                    VStack(spacing: 15) {
                        // Loading dots
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(isAnimating ? 1 : 0.5)
                                    .opacity(isAnimating ? 1 : 0.3)
                                    .animation(
                                        Animation
                                            .easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(0.2 * Double(index)),
                                        value: isAnimating
                                    )
                            }
                        }
                        
                        // Loading message
                        Text("Loading your study materials...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 30)
                    .opacity(showProgress ? 1 : 0)
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Start animations in sequence
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                opacity = 1
                scale = 1
                isAnimating = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                showAppName = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(1.2)) {
                showTagline = true
            }
            
            withAnimation(.easeOut(duration: 0.4).delay(1.8)) {
                showProgress = true
            }
        }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Preview provider for SwiftUI canvas
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
