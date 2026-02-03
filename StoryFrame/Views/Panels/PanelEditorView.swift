import SwiftUI

struct PanelEditorView: View {
    @Bindable var panel: Panel
    @Environment(\.dismiss) private var dismiss

    @State private var borderWidth: Double
    @State private var borderColor: Color
    @State private var backgroundColor: Color
    @State private var hasBackground: Bool

    init(panel: Panel) {
        self.panel = panel
        _borderWidth = State(initialValue: panel.borderWidth)
        _borderColor = State(initialValue: Color(hex: panel.borderColor))
        _backgroundColor = State(initialValue: Color(hex: panel.backgroundColor ?? "#FFFFFF"))
        _hasBackground = State(initialValue: panel.backgroundColor != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Border") {
                    HStack {
                        Text("Width")
                        Spacer()
                        Slider(value: $borderWidth, in: 0...10, step: 0.5)
                            .frame(width: 150)
                        Text("\(borderWidth, specifier: "%.1f")")
                            .font(.caption.monospacedDigit())
                            .frame(width: 30)
                    }

                    ColorPicker("Color", selection: $borderColor)
                }

                Section("Background") {
                    Toggle("Fill Background", isOn: $hasBackground)

                    if hasBackground {
                        ColorPicker("Color", selection: $backgroundColor)
                    }
                }

                Section("Info") {
                    LabeledContent("Points", value: "\(panel.framePoints.count)")
                    LabeledContent("Bubbles", value: "\(panel.bubbles.count)")
                    LabeledContent("Text Elements", value: "\(panel.textElements.count)")
                }
            }
            .navigationTitle("Panel Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applyChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func applyChanges() {
        panel.borderWidth = borderWidth
        panel.borderColor = borderColor.toHex()
        panel.backgroundColor = hasBackground ? backgroundColor.toHex() : nil
    }
}

// MARK: - Panel Resize Handles

struct PanelResizeHandle: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
    }

    let position: Position
    let onDrag: (CGSize) -> Void

    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .stroke(Color(hex: "#4A90D9"), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                        onDrag(value.translation)
                    }
            )
    }
}

// MARK: - Panel Transform Manager

class PanelTransformManager: ObservableObject {
    @Published var selectedPanel: Panel?
    @Published var transformMode: TransformMode = .none

    enum TransformMode {
        case none
        case move
        case resize
        case rotate
    }

    func startTransform(_ mode: TransformMode, panel: Panel) {
        selectedPanel = panel
        transformMode = mode
    }

    func endTransform() {
        transformMode = .none
    }

    func applyMove(_ offset: CGSize, to panel: Panel) {
        let newPoints = panel.framePoints.map { point in
            CGPoint(x: point.x + offset.width, y: point.y + offset.height)
        }
        panel.framePoints = newPoints
    }

    func applyResize(_ scale: CGFloat, anchor: CGPoint, to panel: Panel) {
        let newPoints = panel.framePoints.map { point in
            let dx = point.x - anchor.x
            let dy = point.y - anchor.y
            return CGPoint(
                x: anchor.x + dx * scale,
                y: anchor.y + dy * scale
            )
        }
        panel.framePoints = newPoints
    }
}

#Preview {
    let panel = Panel(orderIndex: 0, framePoints: [
        CGPoint(x: 20, y: 20),
        CGPoint(x: 200, y: 20),
        CGPoint(x: 200, y: 300),
        CGPoint(x: 20, y: 300)
    ])

    return PanelEditorView(panel: panel)
}
