import SwiftUI

struct PanelTemplatesSheet: View {
    @Environment(\.dismiss) private var dismiss

    let pageSize: CGSize
    let onSelectTemplate: ([[CGPoint]]) -> Void

    @State private var selectedCategory: TemplateCategory = .conversation
    @State private var templates: [(name: String, category: String, panels: [[CGPoint]])] = []

    var filteredTemplates: [(name: String, category: String, panels: [[CGPoint]])] {
        templates.filter { $0.category == selectedCategory.rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPicker

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(filteredTemplates.enumerated()), id: \.offset) { index, template in
                            TemplateCard(
                                template: template,
                                pageSize: pageSize
                            ) {
                                onSelectTemplate(template.panels)
                                HapticManager.shared.panelSnapped()
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Panel Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            templates = PanelTemplatePresets.createBuiltInTemplates(pageSize: pageSize)
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TemplateCategory.allCases) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
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
}

struct CategoryChip: View {
    let category: TemplateCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(category.displayName)
                    .font(.subheadline.weight(.medium))
                Text(category.description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#FF6B35") : Color(.systemGray5))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct TemplateCard: View {
    let template: (name: String, category: String, panels: [[CGPoint]])
    let pageSize: CGSize
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                TemplatePreview(panels: template.panels, pageSize: pageSize)
                    .aspectRatio(pageSize.width / pageSize.height, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)

                HStack {
                    Text(template.name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)

                    Spacer()

                    Text("\(template.panels.count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.spring(response: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct TemplatePreview: View {
    let panels: [[CGPoint]]
    let pageSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / pageSize.width, geometry.size.height / pageSize.height)

            ZStack {
                Rectangle()
                    .fill(Color.white)

                ForEach(Array(panels.enumerated()), id: \.offset) { _, points in
                    let scaledPoints = points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
                    Path.polygon(points: scaledPoints)
                        .stroke(Color.black, lineWidth: 1)
                }
            }
        }
    }
}

#Preview {
    PanelTemplatesSheet(
        pageSize: CGSize(width: 477, height: 738)
    ) { _ in }
}
