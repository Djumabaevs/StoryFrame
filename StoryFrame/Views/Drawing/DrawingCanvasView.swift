import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: PKInkingTool
    let isEnabled: Bool
    let backgroundColor: UIColor

    var onDrawingChanged: ((PKDrawing) -> Void)?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.tool = tool
        canvasView.backgroundColor = backgroundColor
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.isUserInteractionEnabled = isEnabled

        // Enable ruler
        canvasView.isRulerActive = false

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
        canvasView.tool = tool
        canvasView.isUserInteractionEnabled = isEnabled
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvasView

        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onDrawingChanged?(canvasView.drawing)
        }
    }
}

// MARK: - Brush Tool Factory

struct BrushToolFactory {
    static func createTool(type: BrushType, color: UIColor, width: CGFloat) -> PKInkingTool {
        switch type {
        case .brush:
            return PKInkingTool(.pen, color: color, width: width)
        case .pen:
            return PKInkingTool(.pen, color: color, width: width)
        case .pencil:
            return PKInkingTool(.pencil, color: color, width: width)
        case .marker:
            return PKInkingTool(.marker, color: color, width: width)
        case .gpen:
            // G-pen simulated with pen and specific settings
            return PKInkingTool(.pen, color: color, width: width * 0.8)
        case .marupen:
            // Maru-pen simulated with finer pen
            return PKInkingTool(.pen, color: color, width: width * 0.5)
        }
    }

    static func createEraser(width: CGFloat) -> PKEraserTool {
        return PKEraserTool(.bitmap, width: width)
    }
}

// MARK: - Drawing Layer View

struct DrawingLayerView: View {
    @Bindable var layer: DrawingLayer
    let canvasSize: CGSize
    let tool: PKInkingTool
    let isActive: Bool

    @State private var drawing: PKDrawing

    init(layer: DrawingLayer, canvasSize: CGSize, tool: PKInkingTool, isActive: Bool) {
        self.layer = layer
        self.canvasSize = canvasSize
        self.tool = tool
        self.isActive = isActive
        _drawing = State(initialValue: layer.drawing ?? PKDrawing())
    }

    var body: some View {
        DrawingCanvasView(
            drawing: $drawing,
            tool: tool,
            isEnabled: isActive && !layer.isLocked,
            backgroundColor: .clear
        ) { newDrawing in
            layer.drawing = newDrawing
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .opacity(layer.isVisible ? layer.opacity : 0)
        .allowsHitTesting(isActive && !layer.isLocked)
    }
}

// MARK: - Screentone Pattern Generator

struct ScreentonePattern {
    enum PatternType {
        case dots
        case lines
        case crosshatch
        case gradient
    }

    static func generateImage(
        type: PatternType,
        size: CGSize,
        density: CGFloat = 0.5,
        angle: CGFloat = 0
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            UIColor.black.setFill()

            switch type {
            case .dots:
                let spacing = 8 / density
                let dotSize: CGFloat = 2

                var y: CGFloat = 0
                var row = 0
                while y < size.height + spacing {
                    var x: CGFloat = row % 2 == 0 ? 0 : spacing / 2
                    while x < size.width + spacing {
                        ctx.fillEllipse(in: CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize))
                        x += spacing
                    }
                    y += spacing * 0.866 // Hexagonal pattern
                    row += 1
                }

            case .lines:
                let spacing = 6 / density
                ctx.setLineWidth(1)

                ctx.rotate(by: angle)

                var x: CGFloat = -size.height
                while x < size.width + size.height {
                    ctx.move(to: CGPoint(x: x, y: -size.height))
                    ctx.addLine(to: CGPoint(x: x, y: size.height * 2))
                    x += spacing
                }
                ctx.strokePath()

            case .crosshatch:
                let spacing = 6 / density
                ctx.setLineWidth(0.5)

                // Horizontal lines
                var y: CGFloat = 0
                while y < size.height {
                    ctx.move(to: CGPoint(x: 0, y: y))
                    ctx.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }

                // Vertical lines
                var x: CGFloat = 0
                while x < size.width {
                    ctx.move(to: CGPoint(x: x, y: 0))
                    ctx.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }

                ctx.strokePath()

            case .gradient:
                let spacing = 4 / density

                for y in stride(from: 0, to: size.height, by: spacing) {
                    let progress = y / size.height
                    let dotSize = 1 + progress * 3

                    for x in stride(from: 0, to: size.width, by: spacing) {
                        if CGFloat.random(in: 0...1) < progress {
                            ctx.fillEllipse(in: CGRect(x: x, y: y, width: dotSize, height: dotSize))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Speed Lines Generator

struct SpeedLinesGenerator {
    static func generate(
        in rect: CGRect,
        direction: CGFloat = 0,
        density: Int = 20,
        variance: CGFloat = 0.3
    ) -> Path {
        var path = Path()

        let center = rect.center

        for _ in 0..<density {
            let angle = direction + CGFloat.random(in: -variance...variance)
            let length = min(rect.width, rect.height) * CGFloat.random(in: 0.6...1.0)
            let offset = CGFloat.random(in: 0...50)

            let startX = center.x + cos(angle) * offset
            let startY = center.y + sin(angle) * offset
            let endX = center.x + cos(angle) * length
            let endY = center.y + sin(angle) * length

            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }

        return path
    }

    static func generateRadial(
        center: CGPoint,
        radius: CGFloat,
        lineCount: Int = 30
    ) -> Path {
        var path = Path()

        for i in 0..<lineCount {
            let angle = (CGFloat(i) / CGFloat(lineCount)) * 2 * .pi
            let innerRadius = radius * CGFloat.random(in: 0.3...0.5)
            // Line width is implicitly handled by stroke style when drawing
            _ = CGFloat.random(in: 1...3)

            let startX = center.x + cos(angle) * innerRadius
            let startY = center.y + sin(angle) * innerRadius
            let endX = center.x + cos(angle) * radius
            let endY = center.y + sin(angle) * radius

            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }

        return path
    }
}

// MARK: - Impact Effect Generator

struct ImpactEffectGenerator {
    static func generateStarburst(
        center: CGPoint,
        size: CGFloat,
        points: Int = 8
    ) -> Path {
        var path = Path()

        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.4

        for i in 0..<(points * 2) {
            let angle = (CGFloat(i) / CGFloat(points * 2)) * 2 * .pi - .pi/2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        return path
    }

    static func generateShockwave(
        center: CGPoint,
        radius: CGFloat,
        rings: Int = 3
    ) -> [Path] {
        var paths: [Path] = []

        for i in 0..<rings {
            let ringRadius = radius * CGFloat(i + 1) / CGFloat(rings)
            var path = Path()
            path.addEllipse(in: CGRect(
                x: center.x - ringRadius,
                y: center.y - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            ))
            paths.append(path)
        }

        return paths
    }
}

#Preview {
    @Previewable @State var drawing = PKDrawing()

    return DrawingCanvasView(
        drawing: $drawing,
        tool: PKInkingTool(.pen, color: .black, width: 4),
        isEnabled: true,
        backgroundColor: .white
    )
    .frame(width: 300, height: 400)
    .border(Color.gray)
}
