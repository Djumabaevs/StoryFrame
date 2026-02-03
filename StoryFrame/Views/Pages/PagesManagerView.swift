import SwiftUI

struct PagesManagerView: View {
    @Bindable var project: ComicProject
    @Binding var currentPageIndex: Int

    let onDismiss: () -> Void
    let onAddPage: () -> Void
    let onDeletePage: (Int) -> Void

    @State private var draggedPage: ComicPage?
    @State private var showDeleteConfirmation = false
    @State private var pageToDelete: Int?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            pagesList

            Divider()

            footer
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .alert("Delete Page?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let index = pageToDelete {
                    onDeletePage(index)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var header: some View {
        HStack {
            Text("Pages")
                .font(.headline)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var pagesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(project.sortedPages.enumerated()), id: \.element.id) { index, page in
                    PageThumbnailRow(
                        page: page,
                        pageNumber: index + 1,
                        isSelected: currentPageIndex == index,
                        onTap: {
                            currentPageIndex = index
                            HapticManager.shared.pageChanged()
                            onDismiss()
                        },
                        onDelete: {
                            if project.pages.count > 1 {
                                pageToDelete = index
                                showDeleteConfirmation = true
                            }
                        },
                        onDuplicate: {
                            duplicatePage(at: index)
                        }
                    )
                    .onDrag {
                        draggedPage = page
                        return NSItemProvider(object: page.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: PageDropDelegate(
                        page: page,
                        pages: project.sortedPages,
                        draggedPage: $draggedPage,
                        onReorder: { from, to in
                            reorderPages(from: from, to: to)
                        }
                    ))
                }
            }
            .padding()
        }
    }

    private var footer: some View {
        HStack {
            Button {
                onAddPage()
            } label: {
                Label("Add Page", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .tint(Color(hex: "#FF6B35"))

            Spacer()

            Text("\(project.pages.count) pages")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func duplicatePage(at index: Int) {
        let originalPage = project.sortedPages[index]
        let newPage = ComicPage(pageNumber: project.pages.count + 1)
        newPage.templateId = originalPage.templateId

        // Copy panels
        for panel in originalPage.panels {
            let newPanel = Panel(orderIndex: panel.orderIndex, framePoints: panel.framePoints)
            newPanel.backgroundColor = panel.backgroundColor
            newPanel.borderWidth = panel.borderWidth
            newPanel.borderColor = panel.borderColor
            newPage.panels.append(newPanel)
        }

        project.pages.append(newPage)
        HapticManager.shared.success()
    }

    private func reorderPages(from: Int, to: Int) {
        guard from != to else { return }

        var pages = project.sortedPages
        let movedPage = pages.remove(at: from)
        pages.insert(movedPage, at: to)

        // Update page numbers
        for (index, page) in pages.enumerated() {
            page.pageNumber = index + 1
        }

        // Update current page index if needed
        if currentPageIndex == from {
            currentPageIndex = to
        } else if from < currentPageIndex && to >= currentPageIndex {
            currentPageIndex -= 1
        } else if from > currentPageIndex && to <= currentPageIndex {
            currentPageIndex += 1
        }

        HapticManager.shared.drop()
    }
}

// MARK: - Page Thumbnail Row

struct PageThumbnailRow: View {
    let page: ComicPage
    let pageNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    if let thumbnailData = page.thumbnailData,
                       let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // Draw panel outlines as placeholder
                        PageMiniPreview(page: page)
                    }
                }
                .frame(width: 60, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color(hex: "#FF6B35") : Color.clear, lineWidth: 2)
                )

                // Page info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Page \(pageNumber)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isSelected ? Color(hex: "#FF6B35") : .primary)

                    HStack(spacing: 8) {
                        Label("\(page.panels.count)", systemImage: "rectangle.split.3x3")
                        Label("\(totalBubbles)", systemImage: "bubble.left")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "#FF6B35").opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.2), value: isPressed)
        .contextMenu {
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var totalBubbles: Int {
        page.panels.reduce(0) { $0 + $1.bubbles.count }
    }
}

// MARK: - Page Mini Preview

struct PageMiniPreview: View {
    let page: ComicPage

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw panel outlines
                for panel in page.panels {
                    let points = panel.framePoints
                    guard points.count >= 3 else { continue }

                    // Scale points to fit preview
                    let scale = min(size.width / 300, size.height / 400)
                    let scaledPoints = points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }

                    let path = Path.polygon(points: scaledPoints)
                    context.stroke(path, with: .color(.gray), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Page Drop Delegate

struct PageDropDelegate: DropDelegate {
    let page: ComicPage
    let pages: [ComicPage]
    @Binding var draggedPage: ComicPage?
    let onReorder: (Int, Int) -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggedPage = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedPage = draggedPage,
              draggedPage.id != page.id,
              let fromIndex = pages.firstIndex(where: { $0.id == draggedPage.id }),
              let toIndex = pages.firstIndex(where: { $0.id == page.id }) else {
            return
        }

        withAnimation(.spring(response: 0.3)) {
            onReorder(fromIndex, toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

#Preview {
    let project = ComicProject(title: "Test", format: "us_comic", width: 477, height: 738)
    let page1 = ComicPage(pageNumber: 1)
    let page2 = ComicPage(pageNumber: 2)
    let page3 = ComicPage(pageNumber: 3)
    project.pages.append(contentsOf: [page1, page2, page3])

    return PagesManagerView(
        project: project,
        currentPageIndex: .constant(0),
        onDismiss: {},
        onAddPage: {},
        onDeletePage: { _ in }
    )
    .frame(width: 280, height: 500)
    .padding()
}
