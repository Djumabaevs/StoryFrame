import SwiftUI
import SwiftData
import PencilKit

struct PageEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var project: ComicProject

    @State private var currentPageIndex = 0
    @State private var selectedTool: EditorTool = .selection
    @State private var selectedBrushType: BrushType = .pen
    @State private var selectedBubbleType: BubbleType = .oval
    @State private var brushSize: CGFloat = 4
    @State private var brushOpacity: CGFloat = 1
    @State private var currentColor: Color = .black
    @State private var showPreview = false
    @State private var showPagesManager = false
    @State private var showPanelTemplates = false
    @State private var showBubbleEditor = false
    @State private var showTextEditor = false
    @State private var showAssetLibrary = false
    @State private var showExportSheet = false
    @State private var showRightSidebar = true
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGSize = .zero
    @State private var selectedPanel: Panel?
    @State private var selectedBubble: SpeechBubble?
    @State private var selectedTextElement: TextElement?
    @State private var undoManager = UndoStack()

    var currentPage: ComicPage? {
        guard currentPageIndex < project.sortedPages.count else { return nil }
        return project.sortedPages[currentPageIndex]
    }

    var isPortrait: Bool {
        UIScreen.main.bounds.height > UIScreen.main.bounds.width
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 700

            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isCompact {
                    // Vertical/Portrait layout
                    VStack(spacing: 0) {
                        topToolbar

                        canvasArea(geometry: geometry)

                        // Bottom toolbar with tools
                        bottomToolBar

                        contextBar
                    }
                } else {
                    // Horizontal/Landscape layout
                    HStack(spacing: 0) {
                        toolRail

                        VStack(spacing: 0) {
                            topToolbar

                            canvasArea(geometry: geometry)

                            contextBar
                        }

                        if showRightSidebar {
                            rightSidebar
                        }
                    }
                }

                if showPagesManager {
                    pagesManagerOverlay
                }

                // Floating sidebar for portrait mode
                if isCompact && showRightSidebar {
                    floatingSidebar
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPanelTemplates) {
            PanelTemplatesSheet(pageSize: CGSize(width: project.pageWidth, height: project.pageHeight)) { template in
                applyTemplate(template)
            }
        }
        .sheet(isPresented: $showBubbleEditor) {
            if let bubble = selectedBubble {
                BubbleEditorSheet(bubble: bubble) {
                    try? modelContext.save()
                }
            }
        }
        .sheet(isPresented: $showTextEditor) {
            if let textElement = selectedTextElement {
                TextEditorSheet(textElement: textElement) {
                    try? modelContext.save()
                }
            } else if let panel = selectedPanel {
                TextEditorSheet(panel: panel) { newText in
                    let textElement = TextElement(text: newText, position: panel.boundingRect.center)
                    panel.textElements.append(textElement)
                    try? modelContext.save()
                }
            }
        }
        .sheet(isPresented: $showAssetLibrary) {
            AssetLibraryView { asset in
                addAssetToCanvas(asset)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(project: project, currentPage: currentPage)
        }
        .fullScreenCover(isPresented: $showPreview) {
            ComicPreviewView(project: project, startingPage: currentPageIndex) {
                showPreview = false
            }
        }
        .onAppear {
            if project.pages.isEmpty {
                let page = project.addPage()
                modelContext.insert(page)
                try? modelContext.save()
            }
        }
    }

    // MARK: - Tool Rail (Landscape)

    private var toolRail: some View {
        VStack(spacing: 4) {
            ForEach(EditorTool.allCases) { tool in
                ToolButton(
                    tool: tool,
                    isSelected: selectedTool == tool
                ) {
                    selectedTool = tool
                    HapticManager.shared.toolSelected()
                }
            }

            Spacer()

            Divider()
                .padding(.horizontal, 8)

            Button {
                showAssetLibrary = true
            } label: {
                Image(systemName: "folder")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .frame(width: 56)
        .background(Color(.systemBackground))
    }

    // MARK: - Bottom Tool Bar (Portrait)

    private var bottomToolBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EditorTool.allCases) { tool in
                    Button {
                        selectedTool = tool
                        HapticManager.shared.toolSelected()
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tool.icon)
                                .font(.title3)
                            Text(tool.displayName)
                                .font(.system(size: 9))
                        }
                        .frame(width: 50, height: 50)
                        .background(selectedTool == tool ? Color(hex: "#FF6B35").opacity(0.2) : Color.clear)
                        .foregroundStyle(selectedTool == tool ? Color(hex: "#FF6B35") : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 40)

                Button {
                    showAssetLibrary = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "folder")
                            .font(.title3)
                        Text("Assets")
                            .font(.system(size: 9))
                    }
                    .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .frame(height: 60)
        .background(Color(.systemBackground))
    }

    // MARK: - Floating Sidebar (Portrait)

    private var floatingSidebar: some View {
        HStack {
            Spacer()

            VStack {
                Spacer()

                RightSidebarView(
                    page: currentPage,
                    selectedPanel: $selectedPanel,
                    currentColor: $currentColor,
                    brushSize: $brushSize
                )
                .frame(width: 250, height: 400)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                .padding()

                Spacer()
            }
        }
        .transition(.move(edge: .trailing))
        .animation(.spring(response: 0.3), value: showRightSidebar)
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack {
            Button {
                saveAndExit()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }

            Spacer()

            Button {
                undoManager.undo()
                HapticManager.shared.undoRedo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!undoManager.canUndo)

            Button {
                undoManager.redo()
                HapticManager.shared.undoRedo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!undoManager.canRedo)

            Spacer()

            pageSelector

            Spacer()

            Button {
                showPreview = true
            } label: {
                Image(systemName: "eye")
            }

            Button {
                showExportSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }

            Button {
                showRightSidebar.toggle()
            } label: {
                Image(systemName: "sidebar.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var pageSelector: some View {
        Button {
            showPagesManager.toggle()
        } label: {
            HStack(spacing: 4) {
                Text("Page \(currentPageIndex + 1)")
                    .fontWeight(.medium)
                Text("of \(project.pages.count)")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Canvas Area

    private func canvasArea(geometry: GeometryProxy) -> some View {
        ZStack {
            Color(.systemGroupedBackground)

            if let page = currentPage {
                CanvasView(
                    page: page,
                    project: project,
                    selectedTool: $selectedTool,
                    selectedPanel: $selectedPanel,
                    selectedBubble: $selectedBubble,
                    selectedTextElement: $selectedTextElement,
                    brushSize: brushSize,
                    brushOpacity: brushOpacity,
                    brushType: selectedBrushType,
                    bubbleType: selectedBubbleType,
                    currentColor: currentColor,
                    showPreview: showPreview,
                    scale: $canvasScale,
                    offset: $canvasOffset,
                    onPanelCreated: { panel in
                        page.panels.append(panel)
                        try? modelContext.save()
                        HapticManager.shared.panelCreated()
                    },
                    onBubbleCreated: { bubble, targetPanel in
                        // Add bubble to target panel or first panel
                        if let panel = targetPanel ?? page.sortedPanels.first {
                            panel.bubbles.append(bubble)
                            selectedBubble = bubble
                            selectedPanel = panel
                            try? modelContext.save()
                            HapticManager.shared.bubbleCreated()
                            // Open editor immediately
                            showBubbleEditor = true
                        }
                    },
                    onTextCreated: { textElement, targetPanel in
                        // Add text to target panel or first panel
                        if let panel = targetPanel ?? page.sortedPanels.first {
                            panel.textElements.append(textElement)
                            selectedTextElement = textElement
                            selectedPanel = panel
                            try? modelContext.save()
                            HapticManager.shared.tap()
                            // Open editor immediately
                            showTextEditor = true
                        }
                    },
                    onBubbleTapped: { bubble in
                        selectedBubble = bubble
                        showBubbleEditor = true
                    },
                    onTextTapped: { textElement in
                        selectedTextElement = textElement
                        showTextEditor = true
                    },
                    onShapeCreated: { rect in
                        // Create a panel from the shape
                        let rectPoints = [
                            CGPoint(x: rect.minX, y: rect.minY),
                            CGPoint(x: rect.maxX, y: rect.minY),
                            CGPoint(x: rect.maxX, y: rect.maxY),
                            CGPoint(x: rect.minX, y: rect.maxY)
                        ]
                        let panel = Panel(orderIndex: page.panels.count, framePoints: rectPoints)
                        page.panels.append(panel)
                        selectedPanel = panel
                        try? modelContext.save()
                        HapticManager.shared.panelCreated()
                    },
                    onAssetRequested: {
                        showAssetLibrary = true
                    },
                    onElementMoved: {
                        try? modelContext.save()
                    }
                )
            } else {
                Text("No page selected")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Context Bar

    private var contextBar: some View {
        Group {
            switch selectedTool {
            case .panel:
                PanelContextBar(
                    showTemplates: $showPanelTemplates
                )
            case .brush:
                BrushContextBar(
                    brushType: $selectedBrushType,
                    brushSize: $brushSize,
                    brushOpacity: $brushOpacity,
                    currentColor: $currentColor
                )
            case .bubble:
                BubbleContextBar(
                    bubbleType: $selectedBubbleType,
                    selectedBubble: selectedBubble,
                    showEditor: $showBubbleEditor
                )
            case .text:
                TextContextBar(
                    showEditor: $showTextEditor
                )
            case .eraser:
                EraserContextBar(
                    brushSize: $brushSize
                )
            default:
                SelectionContextBar(
                    selectedPanel: selectedPanel,
                    onDelete: deleteSelected
                )
            }
        }
        .frame(height: 60)
        .background(Color(.systemBackground))
    }

    // MARK: - Right Sidebar

    private var rightSidebar: some View {
        RightSidebarView(
            page: currentPage,
            selectedPanel: $selectedPanel,
            currentColor: $currentColor,
            brushSize: $brushSize
        )
    }

    // MARK: - Pages Manager Overlay

    private var pagesManagerOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showPagesManager = false
                }

            PagesManagerView(
                project: project,
                currentPageIndex: $currentPageIndex,
                onDismiss: { showPagesManager = false },
                onAddPage: addPage,
                onDeletePage: deletePage
            )
            .frame(maxWidth: 300)
            .transition(.move(edge: .leading))
        }
        .animation(.spring(response: 0.3), value: showPagesManager)
    }

    // MARK: - Actions

    private func saveAndExit() {
        project.modifiedAt = Date()
        generateThumbnail()
        try? modelContext.save()
        dismiss()
    }

    private func generateThumbnail() {
        // Generate thumbnail from first page
        guard let page = project.sortedPages.first else { return }
        let exporter = ComicExporter()
        if let image = exporter.exportPage(page, project: project, scale: 0.5) {
            project.coverImageData = image.pngData()
        }
    }

    private func applyTemplate(_ panels: [[CGPoint]]) {
        guard let page = currentPage else { return }

        // Clear existing panels
        page.panels.removeAll()

        // Add new panels from template
        for (index, points) in panels.enumerated() {
            let panel = Panel(orderIndex: index, framePoints: points)
            page.panels.append(panel)
        }

        try? modelContext.save()
        HapticManager.shared.panelSnapped()
    }

    private func addPage() {
        let newPage = project.addPage()
        modelContext.insert(newPage)
        currentPageIndex = project.pages.count - 1
        try? modelContext.save()
        HapticManager.shared.pageChanged()
    }

    private func deletePage(at index: Int) {
        guard project.pages.count > 1 else { return }
        let page = project.sortedPages[index]
        modelContext.delete(page)

        // Renumber remaining pages
        for (i, p) in project.sortedPages.enumerated() {
            p.pageNumber = i + 1
        }

        if currentPageIndex >= project.pages.count {
            currentPageIndex = max(0, project.pages.count - 1)
        }

        try? modelContext.save()
        HapticManager.shared.pageDeleted()
    }

    private func deleteSelected() {
        if let panel = selectedPanel, let page = currentPage {
            page.panels.removeAll { $0.id == panel.id }
            selectedPanel = nil
            try? modelContext.save()
        }
    }

    private func addAssetToCanvas(_ asset: BuiltInAsset) {
        guard let page = currentPage else { return }

        // Get target panel (selected panel or first panel)
        var targetPanel = selectedPanel ?? page.sortedPanels.first

        // If no panel exists, create one covering the full page first
        if targetPanel == nil {
            let fullPagePoints = [
                CGPoint(x: 20, y: 20),
                CGPoint(x: project.pageWidth - 20, y: 20),
                CGPoint(x: project.pageWidth - 20, y: project.pageHeight - 20),
                CGPoint(x: 20, y: project.pageHeight - 20)
            ]
            let newPanel = Panel(orderIndex: 0, framePoints: fullPagePoints)
            page.panels.append(newPanel)
            targetPanel = newPanel
            selectedPanel = newPanel
        }

        guard let panel = targetPanel else { return }

        addAssetToPanel(asset, panel: panel)

        // Ensure the panel is selected so the user can see the asset was added
        selectedPanel = panel

        try? modelContext.save()
        HapticManager.shared.tap()
    }

    private func addAssetToPanel(_ asset: BuiltInAsset, panel: Panel) {
        let panelCenter = panel.boundingRect.center

        switch asset.category {
        case .soundeffects:
            // Create a text element for sound effects
            let textElement = TextElement(
                text: asset.name,
                position: panelCenter
            )
            textElement.isSoundEffect = true
            textElement.fontSize = 36
            textElement.fontColor = "#FF0000"
            textElement.effect = "shadow"
            panel.textElements.append(textElement)
            selectedTextElement = textElement

        case .emotions:
            // Create emotion symbols as text elements
            let emotionText = getEmotionText(for: asset.name)
            let textElement = TextElement(
                text: emotionText,
                position: panelCenter
            )
            textElement.fontSize = 48
            textElement.fontColor = "#000000"
            textElement.effect = "none"
            panel.textElements.append(textElement)
            selectedTextElement = textElement

        case .speedlines, .effects, .screentones, .backgrounds:
            // For visual effects that don't have dedicated storage yet,
            // add a placeholder text element indicating the effect
            // In a full implementation, these would be stored as panel properties
            let textElement = TextElement(
                text: "[\(asset.name)]",
                position: panelCenter
            )
            textElement.fontSize = 28
            textElement.fontColor = "#333333"
            textElement.effect = "shadow"
            panel.textElements.append(textElement)
            selectedTextElement = textElement
        }
    }

    private func getEmotionText(for name: String) -> String {
        switch name.lowercased() {
        case "sweat drop": return "💧"
        case "anger veins": return "💢"
        case "heart": return "❤️"
        case "question": return "❓"
        case "exclamation": return "❗"
        case "zzz": return "💤"
        default: return "✨"
        }
    }
}

// MARK: - Comic Preview View

struct ComicPreviewView: View {
    let project: ComicProject
    let startingPage: Int
    let onDismiss: () -> Void

    @State private var currentPageIndex: Int
    @GestureState private var dragOffset: CGFloat = 0

    init(project: ComicProject, startingPage: Int, onDismiss: @escaping () -> Void) {
        self.project = project
        self.startingPage = startingPage
        self.onDismiss = onDismiss
        _currentPageIndex = State(initialValue: startingPage)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Page viewer with swipe
            TabView(selection: $currentPageIndex) {
                ForEach(Array(project.sortedPages.enumerated()), id: \.element.id) { index, page in
                    PreviewPageView(page: page, project: project)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // Close button
            VStack {
                HStack {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }

                    Spacer()

                    Text("Page \(currentPageIndex + 1) of \(project.pages.count)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding()
                }

                Spacer()
            }
        }
        .statusBarHidden()
    }
}

struct PreviewPageView: View {
    let page: ComicPage
    let project: ComicProject

    var body: some View {
        GeometryReader { geometry in
            let pageSize = CGSize(width: project.pageWidth, height: project.pageHeight)
            let fitScale = min(
                geometry.size.width / pageSize.width,
                geometry.size.height / pageSize.height
            ) * 0.95
            let canvasWidth = pageSize.width * fitScale
            let canvasHeight = pageSize.height * fitScale

            VStack {
                Spacer()
                HStack {
                    Spacer()

                    // Render the page - all elements in same coordinate space
                    ZStack {
                        // White background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: canvasWidth, height: canvasHeight)
                            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)

                        // Panels
                        Canvas { context, size in
                            for panel in page.sortedPanels {
                                drawPanel(panel, in: context, scale: fitScale)
                            }
                        }
                        .frame(width: canvasWidth, height: canvasHeight)

                        // Drawing layers
                        ForEach(page.sortedLayers) { layer in
                            if layer.isVisible {
                                DrawingLayerPreview(layer: layer, displayScale: fitScale, pageSize: pageSize)
                            }
                        }

                        // Bubbles and text - wrapped in a container with proper frame
                        ZStack {
                            ForEach(page.sortedPanels) { panel in
                                ForEach(panel.bubbles) { bubble in
                                    BubbleView(bubble: bubble, scale: fitScale)
                                }
                                ForEach(panel.textElements) { textElement in
                                    ComicTextView(textElement: textElement, scale: fitScale)
                                }
                            }
                        }
                        .frame(width: canvasWidth, height: canvasHeight)
                    }
                    .frame(width: canvasWidth, height: canvasHeight)
                    .clipped()

                    Spacer()
                }
                Spacer()
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
}

// MARK: - Tool Button

struct ToolButton: View {
    let tool: EditorTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tool.icon)
                    .font(.title3)
                Text(tool.displayName)
                    .font(.system(size: 9))
            }
            .frame(width: 44, height: 50)
            .background(isSelected ? Color(hex: "#FF6B35").opacity(0.2) : Color.clear)
            .foregroundStyle(isSelected ? Color(hex: "#FF6B35") : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

// MARK: - Undo Stack

class UndoStack: ObservableObject {
    private var undoStack: [() -> Void] = []
    private var redoStack: [() -> Void] = []
    private let maxSize = 50

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func push(_ action: @escaping () -> Void, redo: @escaping () -> Void) {
        undoStack.append(action)
        redoStack.removeAll()
        if undoStack.count > maxSize {
            undoStack.removeFirst()
        }
    }

    func undo() {
        guard let action = undoStack.popLast() else { return }
        action()
    }

    func redo() {
        guard let action = redoStack.popLast() else { return }
        action()
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let project: ComicProject
    let currentPage: ComicPage?

    @State private var exportFormat: ExportFormat = .png
    @State private var exportScope: ExportScope = .currentPage
    @State private var isExporting = false
    @State private var exportedItems: [Any] = []
    @State private var showShareSheet = false
    @State private var exportError: String?

    enum ExportFormat: String, CaseIterable {
        case png = "PNG"
        case pdf = "PDF"
        case webtoon = "Webtoon"
    }

    enum ExportScope: String, CaseIterable {
        case currentPage = "Current Page"
        case allPages = "All Pages"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Export Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Scope") {
                    Picker("Export Scope", selection: $exportScope) {
                        ForEach(ExportScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let error = exportError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        exportProject()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Exporting...")
                            } else {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: exportedItems) {
                    dismiss()
                }
            }
        }
    }

    private func exportProject() {
        isExporting = true
        exportError = nil
        let exporter = ComicExporter()

        Task { @MainActor in
            var items: [Any] = []

            switch exportFormat {
            case .png:
                if exportScope == .currentPage, let page = currentPage {
                    if let image = exporter.exportPage(page, project: project) {
                        items.append(image)
                    }
                } else {
                    // Export all pages as separate images
                    var images: [UIImage] = []
                    for page in project.sortedPages {
                        if let image = exporter.exportPage(page, project: project) {
                            images.append(image)
                        }
                    }
                    items.append(contentsOf: images)
                }
            case .pdf:
                if let pdfData = exporter.exportComic(project) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(project.title).pdf")
                    try? pdfData.write(to: tempURL)
                    items.append(tempURL)
                }
            case .webtoon:
                if let image = exporter.exportWebtoon(project) {
                    items.append(image)
                }
            }

            isExporting = false

            if items.isEmpty {
                exportError = "Failed to export. Please try again."
            } else {
                exportedItems = items
                HapticManager.shared.exportComplete()
                showShareSheet = true
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }

        // For iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
            popover.permittedArrowDirections = []
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let project = ComicProject(title: "Test Comic", format: "us_comic", width: 477, height: 738)

    return PageEditorView(project: project)
        .modelContainer(for: [ComicProject.self, ComicPage.self, Panel.self, SpeechBubble.self, TextElement.self, DrawingLayer.self], inMemory: true)
}
