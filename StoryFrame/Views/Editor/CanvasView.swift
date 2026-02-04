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
    let onBubbleCreated: (SpeechBubble, Panel?) -> Void
    let onTextCreated: (TextElement, Panel?) -> Void
    let onBubbleTapped: (SpeechBubble) -> Void
    let onTextTapped: (TextElement) -> Void
    let onShapeCreated: ((CGRect) -> Void)?
    let onAssetRequested: (() -> Void)?
    var onDrawingChanged: ((Data?) -> Void)?
    var onElementMoved: (() -> Void)?

    @State private var drawingPoints: [CGPoint] = []
    @State private var isDrawing = false
    @State private var currentDrawing: PKDrawing = PKDrawing()
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    // Element manipulation state
    @State private var isDraggingElement = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var elementStartPosition: CGPoint = .zero
    @State private var isResizing = false
    @State private var resizeCorner: Int = -1
    @State private var elementStartSize: CGSize = .zero

    var pageSize: CGSize {
        CGSize(width: project.pageWidth, height: project.pageHeight)
    }

    var body: some View {
        GeometryReader { geometry in
            let fitScale = min(
                (geometry.size.width - 40) / pageSize.width,
                (geometry.size.height - 40) / pageSize.height
            )
            let displayScale = fitScale * scale * magnifyBy

            ZStack {
                // Background - allows pan gesture (drag on gray area around canvas)
                Color(.systemGroupedBackground)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                offset.width += value.translation.width
                                offset.height += value.translation.height
                            }
                    )

                pageCanvas(displayScale: displayScale, fitScale: fitScale)
                    .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
            }
            // Pinch to zoom - always works
            .simultaneousGesture(magnificationGesture(fitScale: fitScale))
        }
        .onAppear {
            loadDrawing()
        }
    }

    private func loadDrawing() {
        if let layer = page.sortedLayers.first,
           let drawingData = layer.drawingData,
           let drawing = try? PKDrawing(data: drawingData) {
            currentDrawing = drawing
        }
    }

    private func pageCanvas(displayScale: CGFloat, fitScale: CGFloat) -> some View {
        let canvasWidth = pageSize.width * displayScale
        let canvasHeight = pageSize.height * displayScale

        return ZStack {
            // Page background with shadow
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: canvasWidth, height: canvasHeight)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)

            // Canvas content - panels layer
            Canvas { context, size in
                let scale = displayScale

                // Draw panels
                for panel in page.sortedPanels {
                    drawPanel(panel, in: context, scale: scale)
                }

                // Draw current drawing stroke for panel creation
                if !drawingPoints.isEmpty && selectedTool == .panel {
                    drawCurrentStroke(in: context, scale: scale)
                }

                // Draw shape preview
                if drawingPoints.count >= 2 && selectedTool == .shape {
                    drawShapePreview(in: context, scale: scale)
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)

            // PencilKit Drawing Layer (for brush, eraser tools)
            if selectedTool == .brush || selectedTool == .eraser {
                DrawingCanvasWrapper(
                    drawing: $currentDrawing,
                    brushType: brushType,
                    brushSize: brushSize,
                    brushOpacity: brushOpacity,
                    currentColor: currentColor,
                    isEraser: selectedTool == .eraser,
                    pageSize: pageSize,
                    displayScale: displayScale,
                    onDrawingChanged: { newDrawing in
                        saveDrawingToLayer(newDrawing)
                    }
                )
                .frame(width: canvasWidth, height: canvasHeight)
            }

            // Drawing layers (render existing drawings)
            ForEach(page.sortedLayers) { layer in
                if layer.isVisible && selectedTool != .brush && selectedTool != .eraser {
                    DrawingLayerPreview(layer: layer, displayScale: displayScale, pageSize: pageSize)
                }
            }

            // Interaction layer for panels, bubbles, selection
            Color.clear
                .frame(width: canvasWidth, height: canvasHeight)
                .contentShape(Rectangle())
                .gesture(drawingGesture(displayScale: displayScale))
                .allowsHitTesting(selectedTool != .brush && selectedTool != .eraser)

            // Bubbles and text overlays - wrapped in container with proper frame
            ZStack {
                ForEach(page.sortedPanels) { panel in
                    panelOverlays(panel: panel, displayScale: displayScale)
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)

            // Selection indicators - these use .position() for absolute positioning
            if !showPreview {
                selectionOverlays(displayScale: displayScale)
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .clipped()
    }

    private func saveDrawingToLayer(_ drawing: PKDrawing) {
        // Get or create first layer
        let layer: DrawingLayer
        if let existingLayer = page.sortedLayers.first {
            layer = existingLayer
        } else {
            layer = DrawingLayer(name: "Layer 1", orderIndex: 0)
            page.layers.append(layer)
        }
        layer.drawingData = drawing.dataRepresentation()
        onDrawingChanged?(drawing.dataRepresentation())
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

    private func drawShapePreview(in context: GraphicsContext, scale: CGFloat) {
        guard drawingPoints.count >= 2 else { return }

        let p1 = CGPoint(x: drawingPoints[0].x * scale, y: drawingPoints[0].y * scale)
        let p2 = CGPoint(x: drawingPoints[1].x * scale, y: drawingPoints[1].y * scale)

        let rect = CGRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )

        let path = Path(roundedRect: rect, cornerRadius: 4)

        context.fill(path, with: .color(Color(hex: "#4A90D9").opacity(0.2)))
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
        let canvasWidth = pageSize.width * displayScale
        let canvasHeight = pageSize.height * displayScale
        let canvasSize = CGSize(width: canvasWidth, height: canvasHeight)

        return Group {
            if let panel = selectedPanel {
                PanelSelectionOverlay(panel: panel, scale: displayScale, canvasSize: canvasSize) {
                    onElementMoved?()
                }
            }

            if let bubble = selectedBubble {
                BubbleSelectionOverlay(bubble: bubble, scale: displayScale, canvasSize: canvasSize) {
                    onElementMoved?()
                }
            }

            if let textElement = selectedTextElement {
                TextSelectionOverlay(textElement: textElement, scale: displayScale, canvasSize: canvasSize) {
                    onElementMoved?()
                }
            }
        }
    }

    // MARK: - Gestures

    private func drawingGesture(displayScale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // The gesture location is in the local coordinate space of the canvas frame
                // which is already transformed by displayScale and centered.
                // We need to convert to page coordinates (0 to pageWidth/pageHeight)
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
                        // Find which panel the bubble is in
                        let targetPanel = findPanel(at: location)
                        onBubbleCreated(bubble, targetPanel)
                    }
                case .text:
                    if !isDrawing {
                        isDrawing = true
                        // Create text element at tap location
                        let textElement = TextElement(
                            text: "Text",
                            position: location
                        )
                        // Find which panel the text is in
                        let targetPanel = findPanel(at: location)
                        onTextCreated(textElement, targetPanel)
                    }
                case .shape:
                    if !isDrawing {
                        isDrawing = true
                        drawingPoints = [location]
                    } else {
                        // Update the end point for shape preview
                        if drawingPoints.count > 1 {
                            drawingPoints[1] = location
                        } else {
                            drawingPoints.append(location)
                        }
                    }
                case .asset:
                    if !isDrawing {
                        isDrawing = true
                        onAssetRequested?()
                    }
                case .selection:
                    // When nothing is selected, allow panning by dragging on canvas
                    if selectedPanel == nil && selectedBubble == nil && selectedTextElement == nil {
                        handleCanvasPan(translation: value.translation)
                    }
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
                case .shape:
                    finishShapeDrawing()
                case .selection:
                    // Only handle tap for selection if we weren't panning
                    if !isPanning {
                        handleSelectionTap(at: location)
                    }
                    finishCanvasPan()
                default:
                    break
                }

                isDrawing = false
            }
    }

    @State private var isPanning = false
    @State private var panStartOffset: CGSize = .zero

    private func handleCanvasPan(translation: CGSize) {
        if !isPanning {
            isPanning = true
            panStartOffset = offset
        }
        offset = CGSize(
            width: panStartOffset.width + translation.width,
            height: panStartOffset.height + translation.height
        )
    }

    private func finishCanvasPan() {
        isPanning = false
    }

    private func magnificationGesture(fitScale: CGFloat) -> some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, state, _ in
                // Smooth live update during gesture - clamp the multiplier
                state = max(0.5 / lastScale, min(3.0 / lastScale, value))
            }
            .onEnded { value in
                // Commit the final scale
                scale = max(0.5, min(3.0, scale * value))
                lastScale = 1.0
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

    private func finishShapeDrawing() {
        guard drawingPoints.count >= 2 else {
            drawingPoints.removeAll()
            return
        }

        let minX = min(drawingPoints[0].x, drawingPoints[1].x)
        let maxX = max(drawingPoints[0].x, drawingPoints[1].x)
        let minY = min(drawingPoints[0].y, drawingPoints[1].y)
        let maxY = max(drawingPoints[0].y, drawingPoints[1].y)

        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        onShapeCreated?(rect)

        drawingPoints.removeAll()
    }

    private func findPanel(at point: CGPoint) -> Panel? {
        for panel in page.sortedPanels.reversed() {
            if GeometryHelpers.pointInPolygon(point, polygon: panel.framePoints) {
                return panel
            }
        }
        return page.sortedPanels.first // Default to first panel if not in any
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

}

// MARK: - Panel Selection Overlay

struct PanelSelectionOverlay: View {
    @Bindable var panel: Panel
    let scale: CGFloat
    let canvasSize: CGSize
    var onMoved: (() -> Void)?

    @State private var isDragging = false
    @State private var dragStartPoints: [CGPoint] = []
    @State private var isResizing = false
    @State private var resizeCorner: Int = -1
    @State private var resizeStartRect: CGRect = .zero

    var body: some View {
        let rect = panel.boundingRect.scaled(by: scale)

        ZStack {
            // Selection rectangle - draggable for moving
            Rectangle()
                .stroke(Color(hex: "#4A90D9"), lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if !isDragging && !isResizing {
                                isDragging = true
                                dragStartPoints = panel.framePoints
                            }
                            if isDragging {
                                let deltaX = value.translation.width / scale
                                let deltaY = value.translation.height / scale
                                let newPoints = dragStartPoints.map { point in
                                    CGPoint(x: point.x + deltaX, y: point.y + deltaY)
                                }
                                panel.framePoints = newPoints
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            onMoved?()
                        }
                )

            // Corner handles for resizing
            ForEach(0..<4, id: \.self) { index in
                let corner = cornerPosition(index: index, rect: rect)
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color(hex: "#4A90D9"), lineWidth: 2))
                    .position(corner)
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if !isResizing {
                                    isResizing = true
                                    resizeCorner = index
                                    resizeStartRect = panel.boundingRect
                                }
                                handlePanelResize(value: value, corner: index)
                            }
                            .onEnded { _ in
                                isResizing = false
                                resizeCorner = -1
                                onMoved?()
                            }
                    )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private func handlePanelResize(value: DragGesture.Value, corner: Int) {
        let deltaX = value.translation.width / scale
        let deltaY = value.translation.height / scale

        var newRect = resizeStartRect

        switch corner {
        case 0: // Top-left
            newRect.origin.x = min(resizeStartRect.maxX - 30, resizeStartRect.minX + deltaX)
            newRect.origin.y = min(resizeStartRect.maxY - 30, resizeStartRect.minY + deltaY)
            newRect.size.width = resizeStartRect.maxX - newRect.origin.x
            newRect.size.height = resizeStartRect.maxY - newRect.origin.y
        case 1: // Top-right
            newRect.origin.y = min(resizeStartRect.maxY - 30, resizeStartRect.minY + deltaY)
            newRect.size.width = max(30, resizeStartRect.width + deltaX)
            newRect.size.height = resizeStartRect.maxY - newRect.origin.y
        case 2: // Bottom-right
            newRect.size.width = max(30, resizeStartRect.width + deltaX)
            newRect.size.height = max(30, resizeStartRect.height + deltaY)
        case 3: // Bottom-left
            newRect.origin.x = min(resizeStartRect.maxX - 30, resizeStartRect.minX + deltaX)
            newRect.size.width = resizeStartRect.maxX - newRect.origin.x
            newRect.size.height = max(30, resizeStartRect.height + deltaY)
        default:
            break
        }

        // Update panel points to match new rect
        panel.framePoints = [
            CGPoint(x: newRect.minX, y: newRect.minY),
            CGPoint(x: newRect.maxX, y: newRect.minY),
            CGPoint(x: newRect.maxX, y: newRect.maxY),
            CGPoint(x: newRect.minX, y: newRect.maxY)
        ]
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
    @Bindable var bubble: SpeechBubble
    let scale: CGFloat
    let canvasSize: CGSize
    var onMoved: (() -> Void)?

    @State private var isDragging = false
    @State private var dragStartCenter: CGPoint = .zero
    @State private var isResizing = false
    @State private var resizeCorner: Int = -1
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartCenter: CGPoint = .zero

    var body: some View {
        let scaledCenterX = bubble.centerX * scale
        let scaledCenterY = bubble.centerY * scale
        let scaledWidth = bubble.width * scale
        let scaledHeight = bubble.height * scale

        ZStack {
            // Selection rectangle - draggable for moving
            Rectangle()
                .stroke(Color(hex: "#7B68EE"), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .frame(width: scaledWidth + 8, height: scaledHeight + 8)
                .position(x: scaledCenterX, y: scaledCenterY)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                dragStartCenter = CGPoint(x: bubble.centerX, y: bubble.centerY)
                            }
                            // Convert drag translation to page coordinates
                            let deltaX = value.translation.width / scale
                            let deltaY = value.translation.height / scale
                            bubble.centerX = dragStartCenter.x + deltaX
                            bubble.centerY = dragStartCenter.y + deltaY
                            // Also move the tail
                            if !isResizing {
                                bubble.tailX = bubble.centerX + (bubble.tailX - dragStartCenter.x)
                                bubble.tailY = bubble.centerY + (bubble.tailY - dragStartCenter.y)
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            onMoved?()
                        }
                )

            // Corner handles for resizing
            ForEach(0..<4, id: \.self) { index in
                let corner = bubbleCornerPosition(index: index, centerX: scaledCenterX, centerY: scaledCenterY, width: scaledWidth, height: scaledHeight)
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color(hex: "#7B68EE"), lineWidth: 2))
                    .position(corner)
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if !isResizing {
                                    isResizing = true
                                    resizeCorner = index
                                    resizeStartSize = CGSize(width: bubble.width, height: bubble.height)
                                    resizeStartCenter = CGPoint(x: bubble.centerX, y: bubble.centerY)
                                }
                                handleResize(value: value, corner: index)
                            }
                            .onEnded { _ in
                                isResizing = false
                                resizeCorner = -1
                                onMoved?()
                            }
                    )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private func handleResize(value: DragGesture.Value, corner: Int) {
        let deltaX = value.translation.width / scale
        let deltaY = value.translation.height / scale

        var newWidth = resizeStartSize.width
        var newHeight = resizeStartSize.height
        var newCenterX = resizeStartCenter.x
        var newCenterY = resizeStartCenter.y

        switch corner {
        case 0: // Top-left
            newWidth = max(40, resizeStartSize.width - deltaX)
            newHeight = max(30, resizeStartSize.height - deltaY)
            newCenterX = resizeStartCenter.x + (resizeStartSize.width - newWidth) / 2
            newCenterY = resizeStartCenter.y + (resizeStartSize.height - newHeight) / 2
        case 1: // Top-right
            newWidth = max(40, resizeStartSize.width + deltaX)
            newHeight = max(30, resizeStartSize.height - deltaY)
            newCenterX = resizeStartCenter.x + (newWidth - resizeStartSize.width) / 2
            newCenterY = resizeStartCenter.y + (resizeStartSize.height - newHeight) / 2
        case 2: // Bottom-right
            newWidth = max(40, resizeStartSize.width + deltaX)
            newHeight = max(30, resizeStartSize.height + deltaY)
            newCenterX = resizeStartCenter.x + (newWidth - resizeStartSize.width) / 2
            newCenterY = resizeStartCenter.y + (newHeight - resizeStartSize.height) / 2
        case 3: // Bottom-left
            newWidth = max(40, resizeStartSize.width - deltaX)
            newHeight = max(30, resizeStartSize.height + deltaY)
            newCenterX = resizeStartCenter.x + (resizeStartSize.width - newWidth) / 2
            newCenterY = resizeStartCenter.y + (newHeight - resizeStartSize.height) / 2
        default:
            break
        }

        bubble.width = newWidth
        bubble.height = newHeight
        bubble.centerX = newCenterX
        bubble.centerY = newCenterY
    }

    private func bubbleCornerPosition(index: Int, centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat) -> CGPoint {
        let halfWidth = (width + 8) / 2
        let halfHeight = (height + 8) / 2
        switch index {
        case 0: return CGPoint(x: centerX - halfWidth, y: centerY - halfHeight)
        case 1: return CGPoint(x: centerX + halfWidth, y: centerY - halfHeight)
        case 2: return CGPoint(x: centerX + halfWidth, y: centerY + halfHeight)
        case 3: return CGPoint(x: centerX - halfWidth, y: centerY + halfHeight)
        default: return .zero
        }
    }
}

// MARK: - Text Selection Overlay

struct TextSelectionOverlay: View {
    @Bindable var textElement: TextElement
    let scale: CGFloat
    let canvasSize: CGSize
    var onMoved: (() -> Void)?

    @State private var isDragging = false
    @State private var dragStartPosition: CGPoint = .zero
    @State private var isResizing = false
    @State private var resizeStartWidth: CGFloat = 0

    var body: some View {
        let scaledX = textElement.x * scale
        let scaledY = textElement.y * scale
        let scaledWidth = textElement.width * scale
        let estimatedHeight: CGFloat = textElement.fontSize * scale * 1.5

        ZStack {
            // Selection rectangle - draggable for moving
            Rectangle()
                .stroke(Color(hex: "#4CAF50"), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .frame(width: scaledWidth + 8, height: estimatedHeight + 8)
                .position(x: scaledX, y: scaledY)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                dragStartPosition = CGPoint(x: textElement.x, y: textElement.y)
                            }
                            let deltaX = value.translation.width / scale
                            let deltaY = value.translation.height / scale
                            textElement.x = dragStartPosition.x + deltaX
                            textElement.y = dragStartPosition.y + deltaY
                        }
                        .onEnded { _ in
                            isDragging = false
                            onMoved?()
                        }
                )

            // Corner handles for resizing width
            ForEach([1, 2], id: \.self) { index in // Only right corners for width resize
                let corner = textCornerPosition(index: index, x: scaledX, y: scaledY, width: scaledWidth, height: estimatedHeight)
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color(hex: "#4CAF50"), lineWidth: 2))
                    .position(corner)
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if !isResizing {
                                    isResizing = true
                                    resizeStartWidth = textElement.width
                                }
                                let deltaX = value.translation.width / scale
                                textElement.width = max(50, resizeStartWidth + deltaX)
                            }
                            .onEnded { _ in
                                isResizing = false
                                onMoved?()
                            }
                    )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private func textCornerPosition(index: Int, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGPoint {
        let halfWidth = (width + 8) / 2
        let halfHeight = (height + 8) / 2
        switch index {
        case 0: return CGPoint(x: x - halfWidth, y: y - halfHeight) // Top-left
        case 1: return CGPoint(x: x + halfWidth, y: y - halfHeight) // Top-right
        case 2: return CGPoint(x: x + halfWidth, y: y + halfHeight) // Bottom-right
        case 3: return CGPoint(x: x - halfWidth, y: y + halfHeight) // Bottom-left
        default: return .zero
        }
    }
}

// MARK: - Bubble View

struct BubbleView: View {
    let bubble: SpeechBubble
    let scale: CGFloat

    var body: some View {
        let scaledSize = CGSize(width: bubble.width * scale, height: bubble.height * scale)
        // Tail position relative to bubble center (for local drawing)
        let tailOffsetX = (bubble.tailX - bubble.centerX) * scale
        let tailOffsetY = (bubble.tailY - bubble.centerY) * scale

        // Draw bubble centered at (0,0) in local coords, then position the whole view
        let frameSize = CGSize(width: scaledSize.width + 60, height: scaledSize.height + 60)
        let localCenter = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        let localTail = CGPoint(x: localCenter.x + tailOffsetX, y: localCenter.y + tailOffsetY)

        ZStack {
            BubbleShape(
                bubbleType: bubble.bubbleType,
                tailPosition: localTail,
                tailStyle: bubble.tailStyle,
                center: localCenter,
                size: scaledSize
            )
            .fill(Color(hex: bubble.fillColor).opacity(bubble.fillOpacity))

            BubbleShape(
                bubbleType: bubble.bubbleType,
                tailPosition: localTail,
                tailStyle: bubble.tailStyle,
                center: localCenter,
                size: scaledSize
            )
            .stroke(Color(hex: bubble.borderColor), lineWidth: max(1, bubble.borderWidth * scale / 2))

            if !bubble.text.isEmpty {
                Text(bubble.text)
                    .font(.system(size: max(8, bubble.fontSize * scale), weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: bubble.fontColor))
                    .multilineTextAlignment(textAlignment)
                    .frame(width: scaledSize.width * 0.85, height: scaledSize.height * 0.85)
                    .position(localCenter)
            }
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .position(x: bubble.centerX * scale, y: bubble.centerY * scale)
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

// MARK: - Drawing Canvas Wrapper (UIKit Integration)

struct DrawingCanvasWrapper: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let brushType: BrushType
    let brushSize: CGFloat
    let brushOpacity: CGFloat
    let currentColor: Color
    let isEraser: Bool
    let pageSize: CGSize
    let displayScale: CGFloat
    var onDrawingChanged: ((PKDrawing) -> Void)?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 1.0
        canvasView.isScrollEnabled = false
        canvasView.overrideUserInterfaceStyle = .light

        // Set initial tool
        updateTool(canvasView)

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        // Update drawing if changed externally
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }

        // Update tool
        updateTool(canvasView)
    }

    private func updateTool(_ canvasView: PKCanvasView) {
        if isEraser {
            canvasView.tool = PKEraserTool(.bitmap, width: brushSize * 2)
        } else {
            let uiColor = UIColor(currentColor).withAlphaComponent(brushOpacity)
            canvasView.tool = BrushToolFactory.createTool(type: brushType, color: uiColor, width: brushSize)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvasWrapper

        init(_ parent: DrawingCanvasWrapper) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onDrawingChanged?(canvasView.drawing)
        }
    }
}

// MARK: - Drawing Layer Preview

struct DrawingLayerPreview: View {
    let layer: DrawingLayer
    let displayScale: CGFloat
    let pageSize: CGSize

    var body: some View {
        if let drawingData = layer.drawingData,
           let drawing = try? PKDrawing(data: drawingData) {
            Image(uiImage: drawing.image(from: CGRect(origin: .zero, size: pageSize), scale: displayScale))
                .opacity(layer.opacity)
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
        onBubbleCreated: { _, _ in },
        onTextCreated: { _, _ in },
        onBubbleTapped: { _ in },
        onTextTapped: { _ in },
        onShapeCreated: nil,
        onAssetRequested: nil
    )
}
