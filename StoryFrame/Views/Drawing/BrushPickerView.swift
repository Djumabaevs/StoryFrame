import SwiftUI

struct BrushPickerView: View {
    @Binding var selectedBrush: BrushType
    @Binding var brushSize: CGFloat
    @Binding var brushOpacity: CGFloat
    @Binding var color: Color

    @State private var showColorPicker = false

    var body: some View {
        VStack(spacing: 16) {
            // Brush types
            brushTypeSelector

            Divider()

            // Size and opacity sliders
            controlSliders

            Divider()

            // Color section
            colorSection

            // Preview
            brushPreview
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var brushTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Brush Type")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 8)
            ], spacing: 8) {
                ForEach(BrushType.allCases) { brush in
                    BrushTypeCell(
                        brush: brush,
                        isSelected: selectedBrush == brush
                    ) {
                        selectedBrush = brush
                        HapticManager.shared.toolSelected()
                    }
                }
            }
        }
    }

    private var controlSliders: some View {
        VStack(spacing: 12) {
            // Size slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Size")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(brushSize)) pt")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .foregroundStyle(.secondary)

                    Slider(value: $brushSize, in: 1...50, step: 1)
                        .tint(Color(hex: "#FF6B35"))

                    Image(systemName: "circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }

            // Opacity slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Opacity")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(brushOpacity * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Image(systemName: "circle.dotted")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Slider(value: $brushOpacity, in: 0.1...1.0, step: 0.1)
                        .tint(Color(hex: "#FF6B35"))

                    Image(systemName: "circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Color")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                ColorPicker("", selection: $color)
                    .labelsHidden()
            }

            // Quick colors
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 6), count: 8), spacing: 6) {
                ForEach(quickColors, id: \.self) { quickColor in
                    Circle()
                        .fill(quickColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(color == quickColor ? Color.primary : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            color = quickColor
                            HapticManager.shared.tap()
                        }
                }
            }
        }
    }

    private var brushPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))

                // Brush stroke preview
                Path { path in
                    path.move(to: CGPoint(x: 30, y: 40))
                    path.addCurve(
                        to: CGPoint(x: 170, y: 40),
                        control1: CGPoint(x: 70, y: 10),
                        control2: CGPoint(x: 130, y: 70)
                    )
                }
                .stroke(
                    color.opacity(brushOpacity),
                    style: StrokeStyle(
                        lineWidth: brushSize,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .frame(height: 80)
        }
    }

    private var quickColors: [Color] {
        [
            .black, Color(.darkGray), Color(.gray), Color(.lightGray),
            .white, .red, .orange, .yellow,
            .green, .blue, .purple, .pink,
            .brown, .cyan, .indigo, .mint
        ]
    }
}

struct BrushTypeCell: View {
    let brush: BrushType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: brush.icon)
                    .font(.system(size: 20))

                Text(brush.displayName)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#FF6B35").opacity(0.15) : Color(.systemGray6))
            )
            .foregroundStyle(isSelected ? Color(hex: "#FF6B35") : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#FF6B35") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Brush Picker

struct CompactBrushPicker: View {
    @Binding var selectedBrush: BrushType
    @Binding var brushSize: CGFloat
    @Binding var color: Color

    var body: some View {
        HStack(spacing: 12) {
            // Brush type menu
            Menu {
                ForEach(BrushType.allCases) { brush in
                    Button {
                        selectedBrush = brush
                    } label: {
                        Label(brush.displayName, systemImage: brush.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: selectedBrush.icon)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Size stepper
            HStack(spacing: 4) {
                Button {
                    brushSize = max(1, brushSize - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.caption)
                }

                Text("\(Int(brushSize))")
                    .font(.caption.monospacedDigit())
                    .frame(width: 24)

                Button {
                    brushSize = min(50, brushSize + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Color picker
            ColorPicker("", selection: $color)
                .labelsHidden()
        }
    }
}

#Preview {
    BrushPickerView(
        selectedBrush: .constant(.pen),
        brushSize: .constant(4),
        brushOpacity: .constant(1),
        color: .constant(.black)
    )
    .frame(width: 280)
    .padding()
}
