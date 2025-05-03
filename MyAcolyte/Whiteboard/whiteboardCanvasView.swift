// WhiteboardCanvasComponents.swift
import SwiftUI
import PencilKit

// Canvas View Representable
struct CanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// Grid background overlay
struct GridBackground: View {
    let type: GridType
    let spacing: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            if type == .lines {
                // Lines grid
                ZStack {
                    // Vertical lines
                    ForEach(0..<Int(geometry.size.width / spacing) + 1, id: \.self) { i in
                        Path { path in
                            let x = CGFloat(i) * spacing
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: i % 5 == 0 ? 0.5 : 0.2)
                    }
                    
                    // Horizontal lines
                    ForEach(0..<Int(geometry.size.height / spacing) + 1, id: \.self) { i in
                        Path { path in
                            let y = CGFloat(i) * spacing
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: i % 5 == 0 ? 0.5 : 0.2)
                    }
                }
            } else if type == .dots {
                // Dots grid
                ForEach(0..<Int(geometry.size.width / spacing) + 1, id: \.self) { i in
                    ForEach(0..<Int(geometry.size.height / spacing) + 1, id: \.self) { j in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 2, height: 2)
                            .position(x: CGFloat(i) * spacing, y: CGFloat(j) * spacing)
                    }
                }
            }
        }
    }
}

// Shape drawing overlay
struct ShapeOverlay: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let shapeType: ShapeType
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        Canvas { context, size in
            context.stroke(
                Path { path in
                    switch shapeType {
                    case .line:
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    case .rectangle:
                        let rect = CGRect(
                            x: min(startPoint.x, endPoint.x),
                            y: min(startPoint.y, endPoint.y),
                            width: abs(endPoint.x - startPoint.x),
                            height: abs(endPoint.y - startPoint.y)
                        )
                        path.addRect(rect)
                    case .oval:
                        let rect = CGRect(
                            x: min(startPoint.x, endPoint.x),
                            y: min(startPoint.y, endPoint.y),
                            width: abs(endPoint.x - startPoint.x),
                            height: abs(endPoint.y - startPoint.y)
                        )
                        path.addEllipse(in: rect)
                    case .arrow:
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                        
                        // Calculate arrow head
                        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
                        let arrowLength = lineWidth * 4
                        let arrowAngle = CGFloat.pi / 6 // 30 degrees
                        
                        let arrowPoint1 = CGPoint(
                            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
                            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
                        )
                        
                        let arrowPoint2 = CGPoint(
                            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
                            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
                        )
                        
                        // Draw arrow head
                        path.move(to: endPoint)
                        path.addLine(to: arrowPoint1)
                        path.move(to: endPoint)
                        path.addLine(to: arrowPoint2)
                    }
                },
                with: .color(color),
                lineWidth: lineWidth
            )
        }
    }
}
