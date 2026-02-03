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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

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

                if showPagesManager {
                    pagesManagerOverlay
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
            AssetLibraryView()
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(project: project, currentPage: currentPage)
        }
        .onAppear {
            if project.pages.isEmpty {
                let page = project.addPage()
                modelContext.insert(page)
                try? modelContext.save()
            }
        }
    }

    // MARK: - Tool Rail

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
                showPreview.toggle()
            } label: {
                Image(systemName: showPreview ? "eye.fill" : "eye")
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
                    onBubbleCreated: { bubble in
                        if let panel = selectedPanel {
                            panel.bubbles.append(bubble)
                            selectedBubble = bubble
                            try? modelContext.save()
                            HapticManager.shared.bubbleCreated()
                        }
                    },
                    onBubbleTapped: { bubble in
                        selectedBubble = bubble
                        showBubbleEditor = true
                    },
                    onTextTapped: { textElement in
                        selectedTextElement = textElement
                        showTextEditor = true
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
        if let firstPage = project.sortedPages.first {
            // Implementation would render the page to an image
            // For now, we'll skip this as it requires more complex rendering
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

                Section {
                    Button {
                        exportProject()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
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
        }
    }

    private func exportProject() {
        isExporting = true
        let exporter = ComicExporter()

        Task {
            do {
                switch exportFormat {
                case .png:
                    if exportScope == .currentPage, let page = currentPage {
                        if let image = exporter.exportPage(page, project: project) {
                            await shareImage(image)
                        }
                    } else {
                        // Export all pages
                        for page in project.sortedPages {
                            if let image = exporter.exportPage(page, project: project) {
                                await shareImage(image)
                            }
                        }
                    }
                case .pdf:
                    if let pdfData = exporter.exportComic(project) {
                        await sharePDF(pdfData)
                    }
                case .webtoon:
                    if let image = exporter.exportWebtoon(project) {
                        await shareImage(image)
                    }
                }
                HapticManager.shared.exportComplete()
            }
            isExporting = false
            dismiss()
        }
    }

    @MainActor
    private func shareImage(_ image: UIImage) async {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    @MainActor
    private func sharePDF(_ data: Data) async {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(project.title).pdf")
        try? data.write(to: tempURL)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    let project = ComicProject(title: "Test Comic", format: "us_comic", width: 477, height: 738)

    return PageEditorView(project: project)
        .modelContainer(for: [ComicProject.self, ComicPage.self, Panel.self, SpeechBubble.self, TextElement.self, DrawingLayer.self], inMemory: true)
}
