import SwiftUI

struct BubbleEditorSheet: View {
    @Bindable var bubble: SpeechBubble
    @Environment(\.dismiss) private var dismiss

    let onSave: () -> Void

    @State private var text: String
    @State private var bubbleType: BubbleType
    @State private var tailStyle: String
    @State private var fontSize: Double
    @State private var fontColor: Color
    @State private var textAlignment: String
    @State private var isVertical: Bool
    @State private var borderWidth: Double
    @State private var borderColor: Color
    @State private var fillColor: Color
    @State private var fillOpacity: Double
    @State private var hasShadow: Bool

    init(bubble: SpeechBubble, onSave: @escaping () -> Void) {
        self.bubble = bubble
        self.onSave = onSave

        _text = State(initialValue: bubble.text)
        _bubbleType = State(initialValue: BubbleType(rawValue: bubble.bubbleType) ?? .oval)
        _tailStyle = State(initialValue: bubble.tailStyle)
        _fontSize = State(initialValue: bubble.fontSize)
        _fontColor = State(initialValue: Color(hex: bubble.fontColor))
        _textAlignment = State(initialValue: bubble.textAlignment)
        _isVertical = State(initialValue: bubble.isVertical)
        _borderWidth = State(initialValue: bubble.borderWidth)
        _borderColor = State(initialValue: Color(hex: bubble.borderColor))
        _fillColor = State(initialValue: Color(hex: bubble.fillColor))
        _fillOpacity = State(initialValue: bubble.fillOpacity)
        _hasShadow = State(initialValue: bubble.hasShadow)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    TextField("Enter text...", text: $text, axis: .vertical)
                        .lineLimit(3...6)

                    HStack {
                        Text("Size")
                        Spacer()
                        Slider(value: $fontSize, in: 8...48, step: 1)
                            .frame(width: 120)
                        Text("\(Int(fontSize))")
                            .font(.caption.monospacedDigit())
                            .frame(width: 24)
                    }

                    ColorPicker("Color", selection: $fontColor)

                    Picker("Alignment", selection: $textAlignment) {
                        Text("Left").tag("left")
                        Text("Center").tag("center")
                        Text("Right").tag("right")
                    }
                    .pickerStyle(.segmented)

                    Toggle("Vertical Text (Manga)", isOn: $isVertical)
                }

                Section("Bubble Type") {
                    BubbleTypeGallery(selectedType: $bubbleType)
                }

                Section("Tail") {
                    Picker("Style", selection: $tailStyle) {
                        Text("Curved").tag("curved")
                        Text("Straight").tag("straight")
                        Text("None").tag("none")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Style") {
                    HStack {
                        Text("Border Width")
                        Spacer()
                        Slider(value: $borderWidth, in: 0...8, step: 0.5)
                            .frame(width: 100)
                        Text("\(borderWidth, specifier: "%.1f")")
                            .font(.caption.monospacedDigit())
                            .frame(width: 30)
                    }

                    ColorPicker("Border Color", selection: $borderColor)

                    ColorPicker("Fill Color", selection: $fillColor)

                    HStack {
                        Text("Fill Opacity")
                        Spacer()
                        Slider(value: $fillOpacity, in: 0...1, step: 0.1)
                            .frame(width: 100)
                        Text("\(Int(fillOpacity * 100))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 36)
                    }

                    Toggle("Shadow", isOn: $hasShadow)
                }

                Section {
                    bubblePreview
                        .frame(height: 120)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color(.systemGroupedBackground))
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Edit Bubble")
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
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var bubblePreview: some View {
        ZStack {
            Color(.systemGroupedBackground)

            BubbleShape(
                bubbleType: bubbleType.rawValue,
                tailPosition: CGPoint(x: 150, y: 100),
                tailStyle: tailStyle,
                center: CGPoint(x: 120, y: 50),
                size: CGSize(width: 160, height: 70)
            )
            .fill(fillColor.opacity(fillOpacity))
            .overlay(
                BubbleShape(
                    bubbleType: bubbleType.rawValue,
                    tailPosition: CGPoint(x: 150, y: 100),
                    tailStyle: tailStyle,
                    center: CGPoint(x: 120, y: 50),
                    size: CGSize(width: 160, height: 70)
                )
                .stroke(borderColor, lineWidth: borderWidth)
            )
            .if(hasShadow) { view in
                view.shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
            }

            if !text.isEmpty {
                Text(text)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(fontColor)
                    .multilineTextAlignment(textAlignmentValue)
                    .frame(width: 140)
                    .position(x: 120, y: 50)
            } else {
                Text("Sample Text")
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(fontColor.opacity(0.5))
                    .position(x: 120, y: 50)
            }
        }
    }

    private var textAlignmentValue: TextAlignment {
        switch textAlignment {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }

    private func applyChanges() {
        bubble.text = text
        bubble.bubbleType = bubbleType.rawValue
        bubble.tailStyle = tailStyle
        bubble.fontSize = fontSize
        bubble.fontColor = fontColor.toHex()
        bubble.textAlignment = textAlignment
        bubble.isVertical = isVertical
        bubble.borderWidth = borderWidth
        bubble.borderColor = borderColor.toHex()
        bubble.fillColor = fillColor.toHex()
        bubble.fillOpacity = fillOpacity
        bubble.hasShadow = hasShadow
    }
}

// MARK: - Bubble Type Gallery

struct BubbleTypeGallery: View {
    @Binding var selectedType: BubbleType

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 70, maximum: 90), spacing: 12)
        ], spacing: 12) {
            ForEach(BubbleType.allCases) { type in
                BubbleTypeCell(
                    type: type,
                    isSelected: selectedType == type
                ) {
                    selectedType = type
                    HapticManager.shared.bubbleTypeChanged()
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct BubbleTypeCell: View {
    let type: BubbleType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    BubbleShape(
                        bubbleType: type.rawValue,
                        tailPosition: CGPoint(x: 35, y: 50),
                        tailStyle: type == .burst ? "none" : "curved",
                        center: CGPoint(x: 30, y: 25),
                        size: CGSize(width: 45, height: 30)
                    )
                    .fill(Color.white)
                    .overlay(
                        BubbleShape(
                            bubbleType: type.rawValue,
                            tailPosition: CGPoint(x: 35, y: 50),
                            tailStyle: type == .burst ? "none" : "curved",
                            center: CGPoint(x: 30, y: 25),
                            size: CGSize(width: 45, height: 30)
                        )
                        .stroke(isSelected ? Color(hex: "#7B68EE") : Color.black, lineWidth: isSelected ? 2 : 1)
                    )
                }
                .frame(width: 60, height: 55)

                Text(type.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color(hex: "#7B68EE") : .primary)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#7B68EE").opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#7B68EE") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let bubble = SpeechBubble(
        type: "oval",
        center: CGPoint(x: 100, y: 100),
        size: CGSize(width: 150, height: 80)
    )
    bubble.text = "Hello!"

    return BubbleEditorSheet(bubble: bubble) {}
}
