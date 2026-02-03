import SwiftUI

// MARK: - Panel Context Bar

struct PanelContextBar: View {
    @Binding var showTemplates: Bool
    @State private var gutterWidth: CGFloat = 10
    @State private var snapEnabled = true

    var body: some View {
        HStack(spacing: 20) {
            Button {
                showTemplates = true
            } label: {
                Label("Templates", systemImage: "rectangle.split.3x3")
            }
            .buttonStyle(.bordered)
            .tint(Color(hex: "#FF6B35"))

            Divider()
                .frame(height: 30)

            HStack(spacing: 8) {
                Text("Gutter")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: $gutterWidth, in: 0...30, step: 1)
                    .frame(width: 100)

                Text("\(Int(gutterWidth))")
                    .font(.caption.monospacedDigit())
                    .frame(width: 24)
            }

            Toggle(isOn: $snapEnabled) {
                Label("Snap", systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                    .labelStyle(.iconOnly)
            }
            .toggleStyle(.button)
            .tint(snapEnabled ? Color(hex: "#4A90D9") : .secondary)

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Brush Context Bar

struct BrushContextBar: View {
    @Binding var brushType: BrushType
    @Binding var brushSize: CGFloat
    @Binding var brushOpacity: CGFloat
    @Binding var currentColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Brush type carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BrushType.allCases) { type in
                        BrushTypeButton(
                            type: type,
                            isSelected: brushType == type
                        ) {
                            brushType = type
                            HapticManager.shared.toolSelected()
                        }
                    }
                }
            }
            .frame(maxWidth: 200)

            Divider()
                .frame(height: 30)

            // Size slider
            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(.secondary)

                Slider(value: $brushSize, in: 1...50, step: 1)
                    .frame(width: 100)

                Image(systemName: "circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Text("\(Int(brushSize))")
                    .font(.caption.monospacedDigit())
                    .frame(width: 24)
            }

            Divider()
                .frame(height: 30)

            // Opacity slider
            HStack(spacing: 8) {
                Image(systemName: "circle.dotted")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: $brushOpacity, in: 0.1...1, step: 0.1)
                    .frame(width: 80)

                Text("\(Int(brushOpacity * 100))%")
                    .font(.caption.monospacedDigit())
                    .frame(width: 36)
            }

            Divider()
                .frame(height: 30)

            // Color picker
            ColorPicker("", selection: $currentColor)
                .labelsHidden()
                .frame(width: 30, height: 30)

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct BrushTypeButton: View {
    let type: BrushType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                Text(type.displayName)
                    .font(.system(size: 9))
            }
            .frame(width: 50, height: 40)
            .background(isSelected ? Color(hex: "#FF6B35").opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? Color(hex: "#FF6B35") : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bubble Context Bar

struct BubbleContextBar: View {
    @Binding var bubbleType: BubbleType
    var selectedBubble: SpeechBubble?
    @Binding var showEditor: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Bubble type carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BubbleType.allCases) { type in
                        BubbleTypeButton(
                            type: type,
                            isSelected: bubbleType == type
                        ) {
                            bubbleType = type
                            HapticManager.shared.bubbleTypeChanged()
                        }
                    }
                }
            }
            .frame(maxWidth: 300)

            Divider()
                .frame(height: 30)

            if selectedBubble != nil {
                Button {
                    showEditor = true
                } label: {
                    Label("Edit Bubble", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .tint(Color(hex: "#7B68EE"))
            }

            Spacer()

            Text("Tap on panel to add bubble")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

struct BubbleTypeButton: View {
    let type: BubbleType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                Text(type.displayName)
                    .font(.system(size: 9))
            }
            .frame(width: 55, height: 40)
            .background(isSelected ? Color(hex: "#7B68EE").opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? Color(hex: "#7B68EE") : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Text Context Bar

struct TextContextBar: View {
    @Binding var showEditor: Bool
    @State private var fontSize: CGFloat = 16
    @State private var fontName = "AvenirNext-Bold"

    var body: some View {
        HStack(spacing: 16) {
            Button {
                showEditor = true
            } label: {
                Label("Add Text", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .tint(Color(hex: "#FF6B35"))

            Divider()
                .frame(height: 30)

            HStack(spacing: 8) {
                Text("Size")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: $fontSize, in: 8...72, step: 1)
                    .frame(width: 100)

                Text("\(Int(fontSize))")
                    .font(.caption.monospacedDigit())
                    .frame(width: 24)
            }

            Divider()
                .frame(height: 30)

            Menu {
                Button("Bold") { fontName = "AvenirNext-Bold" }
                Button("Regular") { fontName = "AvenirNext-Regular" }
                Button("Comic") { fontName = "Comic Sans MS" }
            } label: {
                Label("Font", systemImage: "textformat")
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Eraser Context Bar

struct EraserContextBar: View {
    @Binding var brushSize: CGFloat

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "circle")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)

                Slider(value: $brushSize, in: 5...100, step: 1)
                    .frame(width: 150)

                Image(systemName: "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                Text("\(Int(brushSize))")
                    .font(.caption.monospacedDigit())
                    .frame(width: 30)
            }

            Spacer()

            Text("Draw to erase")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Selection Context Bar

struct SelectionContextBar: View {
    var selectedPanel: Panel?
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if selectedPanel != nil {
                Button {
                    // Duplicate action
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }

                Button {
                    // Bring to front
                } label: {
                    Label("Front", systemImage: "square.3.layers.3d.top.filled")
                }

                Button {
                    // Send to back
                } label: {
                    Label("Back", systemImage: "square.3.layers.3d.bottom.filled")
                }

                Divider()
                    .frame(height: 30)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            } else {
                Text("Tap to select panels, bubbles, or text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 20) {
        PanelContextBar(showTemplates: .constant(false))
            .frame(height: 60)
            .background(Color(.systemBackground))

        BrushContextBar(
            brushType: .constant(.pen),
            brushSize: .constant(4),
            brushOpacity: .constant(1),
            currentColor: .constant(.black)
        )
        .frame(height: 60)
        .background(Color(.systemBackground))

        BubbleContextBar(
            bubbleType: .constant(.oval),
            selectedBubble: nil,
            showEditor: .constant(false)
        )
        .frame(height: 60)
        .background(Color(.systemBackground))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
