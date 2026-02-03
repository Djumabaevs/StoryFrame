import SwiftUI
import SwiftData

struct ProjectsLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ComicProject.modifiedAt, order: .reverse) private var projects: [ComicProject]
    @Binding var selectedProject: ComicProject?

    @State private var showNewProjectSheet = false
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all
    @State private var isGridView = true
    @State private var projectToDelete: ComicProject?
    @State private var showDeleteAlert = false

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case inProgress = "In Progress"
        case completed = "Completed"
    }

    var filteredProjects: [ComicProject] {
        var result = projects

        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        switch filterMode {
        case .all:
            break
        case .inProgress:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            if filteredProjects.isEmpty {
                emptyStateView
            } else {
                if isGridView {
                    gridView
                } else {
                    listView
                }
            }
        }
        .navigationTitle("StoryFrame")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isGridView.toggle()
                } label: {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewProjectSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search projects")
        .sheet(isPresented: $showNewProjectSheet) {
            NewProjectSheet { newProject in
                modelContext.insert(newProject)
                let page = newProject.addPage()
                modelContext.insert(page)
                try? modelContext.save()
                selectedProject = newProject
            }
        }
        .alert("Delete Project?", isPresented: $showDeleteAlert, presenting: projectToDelete) { project in
            Button("Delete", role: .destructive) {
                deleteProject(project)
            }
            Button("Cancel", role: .cancel) {}
        } message: { project in
            Text("Are you sure you want to delete \"\(project.title)\"? This action cannot be undone.")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    FilterChip(
                        title: mode.rawValue,
                        isSelected: filterMode == mode
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            filterMode = mode
                        }
                        HapticManager.shared.toolSelected()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredProjects) { project in
                    ProjectCardView(project: project)
                        .onTapGesture {
                            HapticManager.shared.tap()
                            selectedProject = project
                        }
                        .contextMenu {
                            projectContextMenu(for: project)
                        }
                }
            }
            .padding()
        }
    }

    private var listView: some View {
        List {
            ForEach(filteredProjects) { project in
                ProjectListRow(project: project)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.shared.tap()
                        selectedProject = project
                    }
                    .contextMenu {
                        projectContextMenu(for: project)
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    projectToDelete = filteredProjects[index]
                    showDeleteAlert = true
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "rectangle.split.3x3")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Projects Yet")
                    .font(.title2.weight(.semibold))

                Text("Create your first comic, manga, or webtoon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showNewProjectSheet = true
            } label: {
                Label("Create Project", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#FF6B35"))

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func projectContextMenu(for project: ComicProject) -> some View {
        Button {
            selectedProject = project
        } label: {
            Label("Open", systemImage: "folder")
        }

        Button {
            duplicateProject(project)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }

        Button {
            project.isCompleted.toggle()
            try? modelContext.save()
        } label: {
            Label(
                project.isCompleted ? "Mark In Progress" : "Mark Completed",
                systemImage: project.isCompleted ? "circle" : "checkmark.circle"
            )
        }

        Divider()

        Button(role: .destructive) {
            projectToDelete = project
            showDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func deleteProject(_ project: ComicProject) {
        modelContext.delete(project)
        try? modelContext.save()
        HapticManager.shared.pageDeleted()
    }

    private func duplicateProject(_ project: ComicProject) {
        let newProject = ComicProject(
            title: "\(project.title) Copy",
            format: project.format,
            width: project.pageWidth,
            height: project.pageHeight,
            direction: project.readingDirection
        )
        newProject.genre = project.genre
        modelContext.insert(newProject)

        for page in project.sortedPages {
            let newPage = ComicPage(pageNumber: page.pageNumber)
            newPage.templateId = page.templateId
            newProject.pages.append(newPage)

            for panel in page.panels {
                let newPanel = Panel(orderIndex: panel.orderIndex, framePoints: panel.framePoints)
                newPanel.backgroundColor = panel.backgroundColor
                newPanel.borderWidth = panel.borderWidth
                newPanel.borderColor = panel.borderColor
                newPage.panels.append(newPanel)
            }
        }

        try? modelContext.save()
        HapticManager.shared.success()
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "#FF6B35") : Color(.systemGray5))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct ProjectListRow: View {
    let project: ComicProject

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 80)
                .overlay {
                    if let coverData = project.coverImageData,
                       let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "doc.richtext")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(project.pages.count) pages")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(project.modifiedAt.relativeFormat())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if project.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "#34C759"))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ProjectsLibraryView(selectedProject: .constant(nil))
    }
    .modelContainer(for: [ComicProject.self, ComicPage.self, Panel.self, SpeechBubble.self, TextElement.self, DrawingLayer.self], inMemory: true)
}
