import SwiftUI
import PDFKit
import PencilKit
import UIKit

struct PDFViewerView: View {
    let pdfId: String
    @ObservedObject var viewModel: FileSystemViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedColor: Color = .black
    @State private var selectedThickness: CGFloat = 2.0
    @State private var isErasing: Bool = false
    @State private var showControls: Bool = true
    @State private var isFullScreen: Bool = true
    @State private var isAnnotating = false
    @State private var canvasView = PKCanvasView()
    @State private var viewMode: PDFDisplayMode = .singlePage
    @State private var currentPage: Int = 0
    @State private var totalPages: Int = 1
    @State private var studyTime: Int = 0 // Track study time in seconds
    @State private var showingProgressView = false
    @State private var studyProgress: StudyProgress?
    
    // Timer for tracking study time
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect() // Update every minute
    
    // Gesture state
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: DragGesture.Value?
    
    var body: some View {
        ZStack {
            // PDF Content
            if let pdfUrl = viewModel.getPdfById(id: pdfId) {
                PDFKitView(
                    url: pdfUrl,
                    currentPage: $currentPage,
                    totalPages: $totalPages
                )
                .edgesIgnoringSafeArea(.all)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if lastDragValue == nil {
                                lastDragValue = value
                                return
                            }
                            
                            let deltaX = value.translation.width - (lastDragValue?.translation.width ?? 0)
                            if abs(deltaX) > 20 { // threshold to avoid accidental swipes
                                if deltaX < 0 && currentPage < totalPages - 1 {
                                    nextPage()
                                    lastDragValue = nil
                                } else if deltaX > 0 && currentPage > 0 {
                                    previousPage()
                                    lastDragValue = nil
                                }
                            }
                            lastDragValue = value
                        }
                        .onEnded { _ in
                            lastDragValue = nil
                        }
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                }
            } else {
                Text("PDF not found")
                    .foregroundColor(.red)
            }
            
            // Top Controls Overlay
            if showControls {
                VStack {
                    // Top toolbar with progress
                    HStack {
                        // Close button
                        Button(action: {
                            // Save progress before closing
                            viewModel.updateStudyProgress(for: pdfId, incrementTimeBy: studyTime / 60)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Progress indicator
                        Button(action: {
                            showingProgressView.toggle()
                        }) {
                            HStack(spacing: 6) {
                                Text("\(currentPage + 1)/\(totalPages)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                if let progress = studyProgress {
                                    Text("•")
                                        .foregroundColor(.white)
                                    
                                    Text("\(progress.percentComplete)%")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // Tools menu
                        Menu {
                            Button(action: {
                                withAnimation {
                                    viewMode = (viewMode == .singlePage) ? .twoUp : .singlePage
                                }
                            }) {
                                Label(
                                    viewMode == .singlePage ? "Two Page View" : "Single Page View",
                                    systemImage: viewMode == .singlePage ? "rectangle.grid.1x2" : "rectangle"
                                )
                            }
                            
                            Button(action: {
                                withAnimation {
                                    isAnnotating.toggle()
                                }
                            }) {
                                Label(
                                    isAnnotating ? "Hide Annotation Tools" : "Show Annotation Tools",
                                    systemImage: isAnnotating ? "pencil.slash" : "pencil"
                                )
                            }
                            
                            Button(action: {
                                saveAnnotatedPDF()
                            }) {
                                Label("Save Annotations", systemImage: "square.and.arrow.down")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                withAnimation {
                                    isFullScreen.toggle()
                                    showControls = !isFullScreen
                                }
                            }) {
                                Label(
                                    isFullScreen ? "Exit Full Screen" : "Enter Full Screen",
                                    systemImage: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                                )
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom navigation controls
                    HStack {
                        Button(action: { previousPage() }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .disabled(currentPage == 0)
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                        
                        Spacer()
                        
                        // Reading stats
                        VStack {
                            Text("Time: \(formatStudyTime(studyTime))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(4)
                            
                            if let progress = studyProgress {
                                Text("\(progress.percentComplete)% Complete")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .padding(4)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { nextPage() }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .disabled(currentPage == totalPages - 1)
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
                .transition(.opacity)
            }
            
            // Annotation toolbar (conditionally shown)
            if isAnnotating {
                VStack {
                    Spacer()
                    AnnotationToolbar(
                        selectedColor: $selectedColor,
                        selectedThickness: $selectedThickness,
                        isErasing: $isErasing,
                        undoAction: undo,
                        redoAction: redo
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom))
                }
            }
            
            // Study progress sheet
            if showingProgressView {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showingProgressView = false
                    }
                
                VStack(spacing: 20) {
                    Text("Study Progress")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let progress = studyProgress {
                        // Progress circle
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(progress.progress))
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(progress.percentComplete)%")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Complete")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        // Statistics
                        VStack(spacing: 15) {
                            StudyStatRow(label: "Total Time", value: "\(progress.totalTimeSpent) mins")
                            StudyStatRow(label: "Last Studied", value: progress.lastStudiedText)
                            StudyStatRow(label: "Current Session", value: formatStudyTime(studyTime))
                            StudyStatRow(label: "Pages Read", value: "\(currentPage + 1) of \(totalPages)")
                        }
                        .padding(.vertical)
                    } else {
                        Text("No study data available")
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        showingProgressView = false
                    }) {
                        Text("Continue Reading")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding(30)
                .background(Color(.systemGray6).opacity(0.9))
                .cornerRadius(20)
                .padding(40)
            }
        }
        .statusBar(hidden: isFullScreen)
        .alert(isPresented: .constant(false)) {  // Placeholder alert
            Alert(title: Text("Success"), message: Text("Your annotations have been saved."), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // Initialize study progress
            studyProgress = viewModel.getStudyProgress(for: pdfId)
            
            // Load PDF document details
            if let pdfUrl = viewModel.getPdfById(id: pdfId),
               let document = PDFDocument(url: pdfUrl) {
                totalPages = document.pageCount
            }
        }
        .onReceive(timer) { _ in
            studyTime += 60 // Increment by 1 minute
            
            // Update progress in viewModel every 5 minutes
            if studyTime % 300 == 0 {
                viewModel.updateStudyProgress(for: pdfId, incrementTimeBy: 5)
                studyProgress = viewModel.getStudyProgress(for: pdfId)
            }
        }
    }
    
    func undo() {
        if let manager = canvasView.undoManager, manager.canUndo {
            manager.undo()
        }
    }
    
    func redo() {
        if let manager = canvasView.undoManager, manager.canRedo {
            manager.redo()
        }
    }
    
    func saveAnnotatedPDF() {
        // In a real app, this would actually save annotations
        NotificationManager.shared.sendNotification(title: "PDF Saved", message: "Your annotations have been saved.")
    }

    func previousPage() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }

    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        }
    }
    
    func formatStudyTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StudyStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// PDF Kit View Representable
struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        pdfView.delegate = context.coordinator
        
        // Enhanced zooming
        pdfView.minScaleFactor = 1.0
        pdfView.maxScaleFactor = 4.0
        pdfView.scaleFactor = 1.0
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            totalPages = document.pageCount
        } else {
            print("Failed to load PDF document")
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = uiView.document,
           currentPage >= 0 && currentPage < document.pageCount,
           let page = document.page(at: currentPage) {
            uiView.go(to: page)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFKitView
        
        init(_ parent: PDFKitView) {
            self.parent = parent
        }
        
        func pdfViewPageChanged(_ pdfView: PDFView) {
            if let currentPage = pdfView.currentPage,
               let document = pdfView.document {
                let pageIndex = document.index(for: currentPage)
                DispatchQueue.main.async {
                    self.parent.currentPage = pageIndex
                }
            }
        }
    }
}
