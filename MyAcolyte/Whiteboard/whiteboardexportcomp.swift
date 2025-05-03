// WhiteboardExportComponents.swift
import SwiftUI
import PencilKit

// Template selector sheet
struct TemplateSelector: View {
    @Binding var canvasView: PKCanvasView
    @Environment(\.dismiss) var dismiss
    
    let templates = [
        "Blank", "Grid", "Cornell Notes", "Weekly Planner",
        "To-Do List", "Meeting Notes", "Mind Map"
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.self) { template in
                    Button(action: {
                        // Apply template (placeholder)
                        canvasView.drawing = PKDrawing() // Just clear for now
                        // In a real app, you would load a template here
                        dismiss()
                    }) {
                        HStack {
                            Text(template)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Export options sheet
struct ExportOptionsView: View {
    let canvasView: PKCanvasView
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Export Format")) {
                    ExportOptionRow(title: "Image (PNG)", subtitle: "High-quality image file", icon: "photo") {
                        exportAsImage()
                    }
                    
                    ExportOptionRow(title: "PDF", subtitle: "Portable Document Format", icon: "doc.richtext") {
                        exportAsPDF()
                    }
                }
                
                Section(header: Text("Share")) {
                    ExportOptionRow(title: "Share", subtitle: "Send to other apps or people", icon: "square.and.arrow.up") {
                        shareDrawing()
                    }
                }
            }
            .navigationTitle("Export Options")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportAsImage() {
        // Convert PKDrawing to image
        let image = canvasView.drawing.image(
            from: canvasView.bounds,
            scale: UIScreen.main.scale
        )
        
        // Save to Photos
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Show confirmation notification
        NotificationManager.shared.sendNotification(
            title: "Image Saved",
            message: "Whiteboard exported as image to Photos."
        )
        
        dismiss()
    }
    
    private func exportAsPDF() {
        // In a real app, you would implement PDF export
        // For now, just show a notification
        NotificationManager.shared.sendNotification(
            title: "PDF Export",
            message: "This feature would export as PDF (placeholder)."
        )
        
        dismiss()
    }
    
    private func shareDrawing() {
        // Convert PKDrawing to image for sharing
        let image = canvasView.drawing.image(
            from: canvasView.bounds,
            scale: UIScreen.main.scale
        )
        
        // Present share sheet
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
        
        // Dismiss after a delay to allow the share sheet to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// Export option row
//struct ExportOptionRow: View {
//    let title: String
//    let subtitle: String
//    let icon: String
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                Image(systemName: icon)
//                    .font(.system(size: 18))
//                    .foregroundColor(.blue)
//                    .frame(width: 30, height: 30)
//                
//                VStack(alignment: .leading, spacing: 2) {
//                    Text(title)
//                        .font(.headline)
//                    
//                    Text(subtitle)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                
//                Spacer()
//                
//                Image(systemName: "chevron.right")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            .padding(.vertical, 4)
//        }
//    }
//}
