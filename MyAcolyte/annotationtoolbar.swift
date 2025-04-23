import Foundation
import SwiftUI
import Combine
import UIKit
import PencilKit
import PDFKit

struct AnnotationToolbar: View {
    @Binding var selectedColor: Color
    @Binding var selectedThickness: CGFloat
    @Binding var isErasing: Bool

    let undoAction: () -> Void  // 🔹 Pass undo function
    let redoAction: () -> Void  // 🔹 Pass redo function
    
    let colors: [Color] = [.black, .red, .blue, .green, .yellow]
    
    var body: some View {
        HStack {
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        selectedColor = color
                        isErasing = false
                    }
            }
            
            Slider(value: $selectedThickness, in: 1...10, step: 1)
                .frame(width: 100)
            
            Button(action: { isErasing.toggle() }) {
                Image(systemName: isErasing ? "pencil.slash" : "pencil")
            }
            
            Button(action: { undoAction() }) {  // 🔹 Calls undo from parent
                Image(systemName: "arrow.uturn.backward.circle")
            }

            Button(action: { redoAction() }) {  // 🔹 Calls redo from parent
                Image(systemName: "arrow.uturn.forward.circle")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}
