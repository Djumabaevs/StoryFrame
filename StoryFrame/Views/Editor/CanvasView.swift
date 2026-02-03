import SwiftUI
import PencilKit

struct CanvasView: View {
    let page: ComicPage
    let project: ComicProject
    @Binding var selectedTool: EditorTool
    @Binding var selectedPanel: Panel?
    @Binding var selectedBubble: SpeechBubble?
    @Binding var selectedTextElement: TextElement?
    let brushSize: CGFloat
    let brushOpacity: CGFloat
    let brushType: BrushType
    let bubbleType: BubbleType
    let currentColor: Color
    let showPreview: Bool
    @Binding var scale: CGFloat
    @Binding var offset: CGSize

    let onPanelCreated: (Panel) -> Void
    let onBubbleCreated: (SpeechBubble) -> Void
    let onBubbleTapped: (SpeechBubble) -> Void
    let onTextTapped: (TextElement) -> Void

    @State private var drawingPoints: [CGPoint] = []
    @State private var isDrawing = false
    @GestureState private var magnifyBy: CGFloat = 1
    @GestureState private var dragOffset: CGSize = .zero

    var pageSize: CGSize {
        CGSize(width: project.pageWidth, height: project.pageHeight)
    }

    var body: some View {
        GeometryReader { geometry in
            let fitScale = min(
                (geometry.size.width - 40) / pageSize.width,
                (geometry.size.height - 40) / pageSize.height
            )
            let displayScale = fitScale * scale

            ZStack {
                Color(.systemGroupedBackground)

                pageCanvas(displayScale: displayScale)
                    .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                    .gesture(panGesture)
                    .gesture(magnificationGesture(fitScale: fitScale))
            }
        }
    }

    private func pageCanvas(displayScale: CGFloat) -> some View {
        ZStack {
            // Page background with shadow
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: pageSize.width * displayScale, height: pageSize.height * displayScale)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)

            // Canvas content
            Canvas { context, size in
                let scale = displayScale

                // Draw panels
                for panel in page.sortedPanels {
                    drawPanel(panel, in: context, scale: scale)
                }

                // Draw current drawing stroke
                if !drawingPoints.isEmpty && selectedTool == .panel {
                    drawCurrentStroke(in: context, scale: scale)
                }
            }
            .frame(width: pageSize.width * displayScale, height: pageSize.height * displayScale)
            .contentShape(Rectangle())
            .gesture(drawingGesture(displayScale: displayScale))

            // Bubbles and text overlays
            ForEach(page.sortedPanels) { panel in
                panelOverlays(panel: panel, displayScale: displayScale)
            }

            // Selection indicators
            if !showPreview {
                selectionOverlays(displayScale: displayScale)
            }
        }
    }

    private func drawPanel(_ panel: Panel, in context: GraphicsContext, scale: CGFloat) {
        let points = panel.framePoints.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
        guard points.count >= 3 else { return }

        let path = Path.polygon(points: points)

        // Fill background
        if let bgColor = panel.backgroundColor {
            context.fill(path, with: .color(Color(hex: bgColor)))
        } else {
            context.fill(path, with: .color(.white))
        }

        // Draw border
        context.stroke(
            path,
            with: .color(Color(hex: panel.borderColor)),
            lineWidth: panel.borderWidth * scale / 2
        )
    }

    private func drawCurrentStroke(in context: GraphicsContext, scale: CGFloat) {
        guard drawingPoints.count >= 2 else { return }

        let scaledPoints = drawingPoints.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }

        var path = Path()
        path.move(to: scaledPoints[0])
        for point in scaledPoints.dropFirst() {
            path.addLine(to: point)
        }

        context.stroke(
            path,
            with: .color(Color(hex: "#4A90D9")),
            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
        )
    }

    private func panelOverlays(panel: Panel, displayScale: CGFloat) -> some View {
        Group {
            // Speech bubbles
            ForEach(panel.bubbles) { bubble in
                BubbleView(bubble: bubble, scale: displayScale)
                    .onTapGesture {
                        if selectedTool == .selection || selectedTool == .bubble {
                            selectedBubble = bubble
                            onBubbleTapped(bubble)
                        }
                    }
            }

            // Text elements
            ForEach(panel.textElements) { textElement in
                ComicTextView(textElement: textElement, scale: displayScale)
                    .onTapGesture {
                        if selectedTool == .selection || selectedTool == .text {
                            selectedTextElement = textElement
                            onTextTapped(textElement)
                        }
                    }
            }
        }
    }

    private func selectionOverlays(displayScale: CGFloat) -> some View {
        Group {
            if let panel = selectedPanel {
                PanelSelectionOverlay(panel: panel, scale: displayScale)
            }

            if let bubble = selectedBubble {
                BubbleSelectionOverlay(bubble: bubble, scale: displayScale)
            }
        }
    }

    // MARK: - Gestures

    private func drawingGesture(displayScale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = CGPoint(
                    x: value.location.x / displayScale,
                    y: value.location.y / displayScale
                )

                switch selectedTool {
                case .panel:
                    if !isDrawing {
                        isDrawing = true
                        drawingPoints = [location]
                    } else {
                        drawingPoints.append(location)
                    }
                case .bubble:
                    if !isDrawing {
                        isDrawing = true
                        // Create bubble at tap location
                        let bubble = SpeechBubble(
                            type: bubbleType.rawValue,
                            center: location,
                            size: AppConstants.defaultBubbleSize
                        )
                        onBubbleCreated(bubble)
                    }
                case .selection:
                    // Handle selection/drag
                    handleSelectionDrag(at: location)
                default:
                    break
                }
            }
            .onEnded { value in
                let location = CGPoint(
                    x: value.location.x / displayScale,
                    y: value.location.y / displayScale
                )

                switch selectedTool {
                case .panel:
                    finishPanelDrawing()
                case .selection:
                    handleSelectionTap(at: location)
                default:
                    break
                }

                isDrawing = false
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                if selectedTool == .selection && selectedPanel == nil && selectedBubble == nil {
                    state = value.translation
                }
            }
            .onEnded { value in
                if selectedTool == .selection && selectedPanel == nil && selectedBubble == nil {
                    offset.width += value.translation.width
                    offset.height += value.translation.height
                }
            }
    }

    private func magnificationGesture(fitScale: CGFloat) -> some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, state, _ in
                state = value
            }
            .onEnded { value in
                scale = max(0.5, min(3.0, scale * value))
            }
    }

    // MARK: - Drawing Actions

    private func finishPanelDrawing() {
        guard drawingPoints.count >= 3 else {
            drawingPoints.removeAll()
            return
        }

        // Simplify to rectangle if roughly rectangular
        let minX = drawingPoints.map { $0.x }.min() ?? 0
        let maxX = drawingPoints.map { $0.x }.max() ?? 0
        let minY = drawingPoints.map { $0.y }.min() ?? 0
        let maxY = drawingPoints.map { $0.y }.max() ?? 0

        let rectPoints = [
            CGPoint(x: minX, y: minY),
            CGPoint(x: maxX, y: minY),
            CGPoint(x: maxX, y: maxY),
            CGPoint(x: minX, y: maxY)
        ]

        let panel = Panel(orderIndex: page.panels.count, framePoints: rectPoints)
        onPanelCreated(panel)

        drawingPoints.removeAll()
    }

    private func handleSelectionTap(at point: CGPoint) {
        // Check if tapped on a panel
        for panel in page.sortedPanels.reversed() {
            if GeometryHelpers.pointInPolygon(point, polygon: panel.framePoints) {
                selectedPanel = panel
                selectedBubble = nil
                selectedTextElement = nil
                return
            }
        }

        // Deselect if tapped on empty area
        selectedPanel = nil
        selectedBubble = nil
        selectedTextElement = nil
    }

    private func handleSelectionDrag(at point: CGPoint) {
        // Could implement drag-to-move for selected elements
    }
}

// MARK: - Panel Selection Overlay

struct PanelSelectionOverlay: View {
    let panel: Panel
    let scale: CGFloat

    var body: some View {
        let rect = panel.boundingRect.scaled(by: scale)

        Rectangle()
            .stroke(Color(hex: "#4A90D9"), lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)

        // Corner handles
        ForEach(0..<4, id: \.self) { index in
            let corner = cornerPosition(index: index, rect: rect)
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color(hex: "#4A90D9"), lineWidth: 2))
                .position(corner)
        }
    }

    private func cornerPosition(index: Int, rect: CGRect) -> CGPoint {
        switch index {
        case 0: return CGPoint(x: rect.minX, y: rect.minY)
        case 1: return CGPoint(x: rect.maxX, y: rect.minY)
        case 2: return CGPoint(x: rect.maxX, y: rect.maxY)
        case 3: return CGPoint(x: rect.minX, y: rect.maxY)
        default: return .zero
        }
    }
}

// MARK: - Bubble Selection Overlay

struct BubbleSelectionOverlay: View {
    let bubble: SpeechBubble
    let scale: CGFloat

    var body: some View {
        let frame = bubble.frame.scaled(by: scale)

        Rectangle()
            .stroke(Color(hex: "#7B68EE"), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .frame(width: frame.width + 8, height: frame.height + 8)
            .position(x: frame.midX, y: frame.midY)
    }
}

// MARK: - Bubble View

struct BubbleView: View {
    let bubble: SpeechBubble
    let scale: CGFloat

    var body: some View {
        let scaledCenter = CGPoint(x: bubble.centerX * scale, y: bubble.centerY * scale)
        let scaledSize = CGSize(width: bubble.width * scale, height: bubble.height * scale)
        let scaledTail = CGPoint(x: bubble.tailX * scale, y: bubble.tailY * scale)

        ZStack {
            BubbleShape(
                bubbleType: bubble.bubbleType,
                tailPosition: scaledTail,
                tailStyle: bubble.tailStyle,
                center: scaledCenter,
                size: scaledSize
            )
            .fill(Color(hex: bubble.fillColor).opacity(bubble.fillOpacity))

            BubbleShape(
                bubbleType: bubble.bubbleType,
                tailPosition: scaledTail,
                tailStyle: bubble.tailStyle,
                center: scaledCenter,
                size: scaledSize
            )
            .stroke(Color(hex: bubble.borderColor), lineWidth: bubble.borderWidth * scale / 2)

            if !bubble.text.isEmpty {
                Text(bubble.text)
                    .font(.system(size: bubble.fontSize * scale, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: bubble.fontColor))
                    .multilineTextAlignment(textAlignment)
                    .frame(width: scaledSize.width * 0.85, height: scaledSize.height * 0.85)
                    .position(scaledCenter)
            }
        }
        .if(bubble.hasShadow) { view in
            view.shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
        }
    }

    private var textAlignment: TextAlignment {
        switch bubble.textAlignment {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }
}

#Preview {
    let page = ComicPage(pageNumber: 1)
    let project = ComicProject(title: "Test", format: "us_comic", width: 477, height: 738)

    return CanvasView(
        page: page,
        project: project,
        selectedTool: .constant(.selection),
        selectedPanel: .constant(nil),
        selectedBubble: .constant(nil),
        selectedTextElement: .constant(nil),
        brushSize: 4,
        brushOpacity: 1,
        brushType: .pen,
        bubbleType: .oval,
        currentColor: .black,
        showPreview: false,
        scale: .constant(1),
        offset: .constant(.zero),
        onPanelCreated: { _ in },
        onBubbleCreated: { _ in },
        onBubbleTapped: { _ in },
        onTextTapped: { _ in }
    )
}
