import SwiftUI

struct TextEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    var textElement: TextElement?
    var panel: Panel?
    let onSave: ((String) -> Void)?
    let onUpdate: (() -> Void)?

    @State private var text: String
    @State private var fontSize: Double
    @State private var fontColor: Color
    @State private var fontName: String
    @State private var alignment: String
    @State private var isVertical: Bool
    @State private var effect: TextEffect
    @State private var effectIntensity: Double
    @State private var isSoundEffect: Bool
    @State private var furiganaText: String
    @State private var rotation: Double

    init(textElement: TextElement, onUpdate: @escaping () -> Void) {
        self.textElement = textElement
        self.panel = nil
        self.onSave = nil
        self.onUpdate = onUpdate

        _text = State(initialValue: textElement.text)
        _fontSize = State(initialValue: textElement.fontSize)
        _fontColor = State(initialValue: Color(hex: textElement.fontColor))
        _fontName = State(initialValue: textElement.fontName)
        _alignment = State(initialValue: textElement.alignment)
        _isVertical = State(initialValue: textElement.isVertical)
        _effect = State(initialValue: TextEffect(rawValue: textElement.effect) ?? .none)
        _effectIntensity = State(initialValue: textElement.effectIntensity)
        _isSoundEffect = State(initialValue: textElement.isSoundEffect)
        _furiganaText = State(initialValue: textElement.furiganaText ?? "")
        _rotation = State(initialValue: textElement.rotation)
    }

    init(panel: Panel, onSave: @escaping (String) -> Void) {
        self.textElement = nil
        self.panel = panel
        self.onSave = onSave
        self.onUpdate = nil

        _text = State(initialValue: "")
        _fontSize = State(initialValue: 24)
        _fontColor = State(initialValue: .black)
        _fontName = State(initialValue: "AvenirNext-Bold")
        _alignment = State(initialValue: "center")
        _isVertical = State(initialValue: false)
        _effect = State(initialValue: .none)
        _effectIntensity = State(initialValue: 1.0)
        _isSoundEffect = State(initialValue: false)
        _furiganaText = State(initialValue: "")
        _rotation = State(initialValue: 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    TextField("Enter text...", text: $text, axis: .vertical)
                        .lineLimit(3...8)

                    if !furiganaText.isEmpty || isVertical {
                        TextField("Furigana (reading)", text: $furiganaText)
                            .font(.caption)
                    }
                }

                Section("Font") {
                    fontPicker

                    HStack {
                        Text("Size")
                        Spacer()
                        Slider(value: $fontSize, in: 8...72, step: 1)
                            .frame(width: 120)
                        Text("\(Int(fontSize))")
                            .font(.caption.monospacedDigit())
                            .frame(width: 30)
                    }

                    ColorPicker("Color", selection: $fontColor)

                    Picker("Alignment", selection: $alignment) {
                        Image(systemName: "text.alignleft").tag("left")
                        Image(systemName: "text.aligncenter").tag("center")
                        Image(systemName: "text.alignright").tag("right")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Layout") {
                    Toggle("Vertical Text (Manga)", isOn: $isVertical)

                    HStack {
                        Text("Rotation")
                        Spacer()
                        Slider(value: $rotation, in: -180...180, step: 5)
                            .frame(width: 100)
                        Text("\(Int(rotation))°")
                            .font(.caption.monospacedDigit())
                            .frame(width: 40)
                    }

                    Toggle("Sound Effect Style", isOn: $isSoundEffect)
                }

                Section("Effect") {
                    effectPicker

                    if effect != .none {
                        HStack {
                            Text("Intensity")
                            Spacer()
                            Slider(value: $effectIntensity, in: 0.1...2.0, step: 0.1)
                                .frame(width: 120)
                            Text("\(effectIntensity, specifier: "%.1f")")
                                .font(.caption.monospacedDigit())
                                .frame(width: 30)
                        }
                    }
                }

                Section {
                    textPreview
                        .frame(height: 100)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color(.systemGroupedBackground))
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(textElement == nil ? "Add Text" : "Edit Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveText()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var fontPicker: some View {
        Menu {
            Button("Bold (Default)") { fontName = "AvenirNext-Bold" }
            Button("Regular") { fontName = "AvenirNext-Regular" }
            Button("Heavy") { fontName = "AvenirNext-Heavy" }
            Divider()
            Button("Marker Felt") { fontName = "MarkerFelt-Wide" }
            Button("Chalkboard") { fontName = "ChalkboardSE-Bold" }
            Button("Noteworthy") { fontName = "Noteworthy-Bold" }
            Divider()
            Button("Courier") { fontName = "Courier-Bold" }
            Button("Menlo") { fontName = "Menlo-Bold" }
        } label: {
            HStack {
                Text("Font")
                Spacer()
                Text(fontDisplayName)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fontDisplayName: String {
        switch fontName {
        case "AvenirNext-Bold": return "Bold"
        case "AvenirNext-Regular": return "Regular"
        case "AvenirNext-Heavy": return "Heavy"
        case "MarkerFelt-Wide": return "Marker Felt"
        case "ChalkboardSE-Bold": return "Chalkboard"
        case "Noteworthy-Bold": return "Noteworthy"
        case "Courier-Bold": return "Courier"
        case "Menlo-Bold": return "Menlo"
        default: return fontName
        }
    }

    private var effectPicker: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 70, maximum: 90), spacing: 8)
        ], spacing: 8) {
            ForEach(TextEffect.allCases) { eff in
                EffectCell(
                    effect: eff,
                    isSelected: effect == eff
                ) {
                    effect = eff
                    HapticManager.shared.toolSelected()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var textPreview: some View {
        ZStack {
            Color(.systemGroupedBackground)

            if !text.isEmpty {
                previewText
                    .rotationEffect(.degrees(rotation))
            } else {
                Text("Preview")
                    .font(.system(size: fontSize))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
    }

    @ViewBuilder
    private var previewText: some View {
        let displayText = text.isEmpty ? "Sample" : text

        if isSoundEffect {
            SoundEffectTextView(
                text: displayText,
                fontSize: fontSize,
                color: fontColor,
                effect: effect,
                intensity: effectIntensity
            )
        } else if isVertical {
            VerticalTextView(
                text: displayText,
                fontSize: fontSize,
                fontName: fontName,
                color: fontColor,
                furigana: furiganaText.isEmpty ? nil : furiganaText
            )
        } else {
            ComicTextPreview(
                text: displayText,
                fontSize: fontSize,
                fontName: fontName,
                color: fontColor,
                alignment: alignment,
                effect: effect,
                intensity: effectIntensity
            )
        }
    }

    private func saveText() {
        if let element = textElement {
            element.text = text
            element.fontSize = fontSize
            element.fontColor = fontColor.toHex()
            element.fontName = fontName
            element.alignment = alignment
            element.isVertical = isVertical
            element.effect = effect.rawValue
            element.effectIntensity = effectIntensity
            element.isSoundEffect = isSoundEffect
            element.furiganaText = furiganaText.isEmpty ? nil : furiganaText
            element.rotation = rotation
            onUpdate?()
        } else {
            onSave?(text)
        }
        HapticManager.shared.textConfirmed()
    }
}

// MARK: - Effect Cell

struct EffectCell: View {
    let effect: TextEffect
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("Aa")
                    .font(.system(size: 16, weight: .bold))
                    .modifier(EffectPreviewModifier(effect: effect))

                Text(effect.displayName)
                    .font(.caption2)
            }
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#7B68EE").opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#7B68EE") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EffectPreviewModifier: ViewModifier {
    let effect: TextEffect
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(EffectApplier(effect: effect, phase: phase))
            .onAppear {
                if effect != .none {
                    withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                        phase = 1
                    }
                }
            }
    }
}

struct EffectApplier: ViewModifier {
    let effect: TextEffect
    let phase: CGFloat

    func body(content: Content) -> some View {
        switch effect {
        case .none:
            content
        case .shake:
            content.offset(x: sin(phase * .pi * 4) * 2)
        case .grow:
            content.scaleEffect(1 + phase * 0.15)
        case .shrink:
            content.scaleEffect(1 - phase * 0.15)
        case .glow:
            content.shadow(color: .yellow.opacity(phase * 0.8), radius: 8)
        case .shadow:
            content.shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
        }
    }
}

// MARK: - Comic Text Preview

struct ComicTextPreview: View {
    let text: String
    let fontSize: Double
    let fontName: String
    let color: Color
    let alignment: String
    let effect: TextEffect
    let intensity: Double

    @State private var phase: CGFloat = 0

    var textAlignment: TextAlignment {
        switch alignment {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }

    var body: some View {
        Text(text)
            .font(.custom(fontName, size: fontSize))
            .foregroundColor(color)
            .multilineTextAlignment(textAlignment)
            .modifier(EffectApplier(effect: effect, phase: phase))
            .onAppear {
                if effect != .none {
                    withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                        phase = 1
                    }
                }
            }
    }
}

#Preview {
    let textElement = TextElement(text: "Hello World!", position: CGPoint(x: 100, y: 100))
    return TextEditorSheet(textElement: textElement) {}
}
