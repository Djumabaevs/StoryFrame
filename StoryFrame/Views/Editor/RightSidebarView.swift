import SwiftUI

struct RightSidebarView: View {
    var page: ComicPage?
    @Binding var selectedPanel: Panel?
    @Binding var currentColor: Color
    @Binding var brushSize: CGFloat

    @State private var expandedSection: SidebarSection? = .layers

    enum SidebarSection: String, CaseIterable {
        case layers = "Layers"
        case colors = "Colors"
        case properties = "Properties"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section headers
            ForEach(SidebarSection.allCases, id: \.self) { section in
                SidebarSectionView(
                    section: section,
                    isExpanded: expandedSection == section,
                    onToggle: {
                        withAnimation(.spring(response: 0.3)) {
                            expandedSection = expandedSection == section ? nil : section
                        }
                    }
                ) {
                    sectionContent(for: section)
                }
            }

            Spacer()
        }
        .frame(width: 200)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1),
            alignment: .leading
        )
    }

    @ViewBuilder
    private func sectionContent(for section: SidebarSection) -> some View {
        switch section {
        case .layers:
            layersContent
        case .colors:
            colorsContent
        case .properties:
            propertiesContent
        }
    }

    private var layersContent: some View {
        VStack(spacing: 8) {
            if let page = page {
                ForEach(page.sortedLayers) { layer in
                    LayerRow(layer: layer)
                }

                if page.layers.isEmpty {
                    Text("No layers yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                }

                Button {
                    addLayer()
                } label: {
                    Label("Add Layer", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var colorsContent: some View {
        VStack(spacing: 12) {
            // Current color picker
            ColorPicker("Current", selection: $currentColor)
                .font(.caption)

            // Recent colors
            VStack(alignment: .leading, spacing: 6) {
                Text("Quick Colors")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(24), spacing: 6), count: 6), spacing: 6) {
                    ForEach(quickColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(currentColor == color ? Color.primary : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                currentColor = color
                            }
                    }
                }
            }

            // Brush size preview
            VStack(alignment: .leading, spacing: 6) {
                Text("Brush Preview")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack {
                    Spacer()
                    Circle()
                        .fill(currentColor)
                        .frame(width: brushSize, height: brushSize)
                    Spacer()
                }
                .frame(height: 50)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var propertiesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let panel = selectedPanel {
                panelProperties(panel)
            } else {
                Text("Select a panel to edit properties")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private func panelProperties(_ panel: Panel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Panel Properties")
                .font(.caption.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Border Width")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Slider(value: Binding(
                    get: { panel.borderWidth },
                    set: { panel.borderWidth = $0 }
                ), in: 0...10, step: 0.5)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Border Color")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ColorPicker("", selection: Binding(
                    get: { Color(hex: panel.borderColor) },
                    set: { panel.borderColor = $0.toHex() }
                ))
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Background")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ColorPicker("", selection: Binding(
                    get: { Color(hex: panel.backgroundColor ?? "#FFFFFF") },
                    set: { panel.backgroundColor = $0.toHex() }
                ))
                .labelsHidden()
            }

            Divider()

            Text("Contains")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(panel.bubbles.count)", systemImage: "bubble.left")
                Spacer()
                Label("\(panel.textElements.count)", systemImage: "textformat")
            }
            .font(.caption)
        }
    }

    private var quickColors: [Color] {
        [
            .black, .white, Color(.systemGray),
            .red, .orange, .yellow,
            .green, .blue, .purple,
            .pink, .brown, .cyan
        ]
    }

    private func addLayer() {
        guard let page = page else { return }
        let layer = DrawingLayer(name: "Layer \(page.layers.count + 1)", orderIndex: page.layers.count)
        page.layers.append(layer)
    }
}

struct SidebarSectionView<Content: View>: View {
    let section: RightSidebarView.SidebarSection
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Text(section.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct LayerRow: View {
    @Bindable var layer: DrawingLayer

    var body: some View {
        HStack(spacing: 8) {
            Button {
                layer.isVisible.toggle()
            } label: {
                Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                    .font(.caption)
                    .foregroundStyle(layer.isVisible ? .primary : .secondary)
            }
            .buttonStyle(.plain)

            Text(layer.name)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            Button {
                layer.isLocked.toggle()
            } label: {
                Image(systemName: layer.isLocked ? "lock" : "lock.open")
                    .font(.caption2)
                    .foregroundStyle(layer.isLocked ? Color(hex: "#FF6B35") : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    RightSidebarView(
        page: nil,
        selectedPanel: .constant(nil),
        currentColor: .constant(.black),
        brushSize: .constant(4)
    )
}
