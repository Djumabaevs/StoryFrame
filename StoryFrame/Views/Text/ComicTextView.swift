import SwiftUI

// MARK: - Main Comic Text View

struct ComicTextView: View {
    let textElement: TextElement
    let scale: CGFloat

    @State private var animationPhase: CGFloat = 0

    var body: some View {
        let scaledFontSize = max(8, textElement.fontSize * scale)

        Group {
            if textElement.isSoundEffect {
                SoundEffectTextView(
                    text: textElement.text,
                    fontSize: scaledFontSize,
                    color: Color(hex: textElement.fontColor),
                    effect: TextEffect(rawValue: textElement.effect) ?? .none,
                    intensity: textElement.effectIntensity
                )
            } else if textElement.isVertical {
                VerticalTextView(
                    text: textElement.text,
                    fontSize: scaledFontSize,
                    fontName: textElement.fontName,
                    color: Color(hex: textElement.fontColor),
                    furigana: textElement.furiganaText
                )
            } else {
                standardTextView
            }
        }
        .fixedSize()
        .rotationEffect(.degrees(textElement.rotation))
        .position(x: textElement.x * scale, y: textElement.y * scale)
        .onAppear {
            if textElement.effect != "none" {
                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                    animationPhase = 1
                }
            }
        }
    }

    private var standardTextView: some View {
        let effect = TextEffect(rawValue: textElement.effect) ?? .none

        return Text(textElement.text)
            .font(.custom(textElement.fontName, size: textElement.fontSize * scale))
            .foregroundColor(Color(hex: textElement.fontColor))
            .multilineTextAlignment(textAlignment)
            .frame(width: textElement.width * scale)
            .modifier(TextEffectModifier(effect: effect, intensity: textElement.effectIntensity, phase: animationPhase))
    }

    private var textAlignment: TextAlignment {
        switch textElement.alignment {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }
}

// MARK: - Text Effect Modifier

struct TextEffectModifier: ViewModifier {
    let effect: TextEffect
    let intensity: Double
    let phase: CGFloat

    func body(content: Content) -> some View {
        switch effect {
        case .none:
            content
        case .shake:
            content
                .offset(
                    x: CGFloat(sin(Double(phase) * Double.pi * 4) * 3.0 * intensity),
                    y: CGFloat(cos(Double(phase) * Double.pi * 4) * 2.0 * intensity)
                )
        case .grow:
            content.scaleEffect(1.0 + Double(phase) * 0.15 * intensity)
        case .shrink:
            content.scaleEffect(1.0 - Double(phase) * 0.15 * intensity)
        case .glow:
            content
                .shadow(color: Color(hex: "#FFFF00").opacity(Double(phase) * 0.8), radius: CGFloat(10.0 * intensity))
                .shadow(color: Color(hex: "#FF6B35").opacity(Double(phase) * 0.4), radius: CGFloat(5.0 * intensity))
        case .shadow:
            content.shadow(color: .black.opacity(0.6), radius: 0, x: CGFloat(3.0 * intensity), y: CGFloat(3.0 * intensity))
        }
    }
}

// MARK: - Sound Effect Text View

struct SoundEffectTextView: View {
    let text: String
    let fontSize: Double
    let color: Color
    let effect: TextEffect
    let intensity: Double

    @State private var animationPhase: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.yellow, .orange, color],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
            .rotationEffect(.degrees(-8))
            .scaleEffect(x: 1.1, y: 0.95)
            .modifier(TextEffectModifier(effect: effect, intensity: intensity, phase: animationPhase))
            .onAppear {
                if effect != .none {
                    withAnimation(.linear(duration: 0.3).repeatForever(autoreverses: true)) {
                        animationPhase = 1
                    }
                }
            }
    }
}

// MARK: - Vertical Text View (Manga Style)

struct VerticalTextView: View {
    let text: String
    let fontSize: Double
    let fontName: String
    let color: Color
    let furigana: String?

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            // Main text (vertical)
            VStack(spacing: 1) {
                ForEach(Array(text.enumerated()), id: \.offset) { _, char in
                    Text(String(char))
                        .font(.custom(fontName, size: fontSize))
                        .foregroundColor(color)
                }
            }

            // Furigana (if provided)
            if let furigana = furigana, !furigana.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(furigana.enumerated()), id: \.offset) { _, char in
                        Text(String(char))
                            .font(.custom(fontName, size: fontSize * 0.4))
                            .foregroundColor(color.opacity(0.8))
                    }
                }
            }
        }
    }
}

// MARK: - Furigana Text View (Ruby Text)

struct FuriganaTextView: View {
    let mainText: String
    let rubyText: String
    let fontSize: Double
    let fontName: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(rubyText)
                .font(.custom(fontName, size: fontSize * 0.4))
                .foregroundColor(color.opacity(0.8))

            Text(mainText)
                .font(.custom(fontName, size: fontSize))
                .foregroundColor(color)
        }
    }
}

// MARK: - Stylized Sound Effect Presets

struct SoundEffectStyle {
    var fontSize: CGFloat
    var rotation: Double
    var scaleX: CGFloat
    var scaleY: CGFloat
    var colors: [Color]

    static let boom = SoundEffectStyle(
        fontSize: 48,
        rotation: -15,
        scaleX: 1.3,
        scaleY: 0.85,
        colors: [.red, .orange, .yellow]
    )

    static let pow = SoundEffectStyle(
        fontSize: 44,
        rotation: 10,
        scaleX: 1.2,
        scaleY: 0.9,
        colors: [.blue, .purple, .pink]
    )

    static let whoosh = SoundEffectStyle(
        fontSize: 36,
        rotation: -5,
        scaleX: 1.4,
        scaleY: 0.8,
        colors: [.cyan, .blue, .indigo]
    )

    static let crack = SoundEffectStyle(
        fontSize: 40,
        rotation: -20,
        scaleX: 1.1,
        scaleY: 1.1,
        colors: [.white, .gray, .black]
    )
}

struct StyledSoundEffectView: View {
    let text: String
    let style: SoundEffectStyle

    var body: some View {
        Text(text)
            .font(.system(size: style.fontSize, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: style.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            .rotationEffect(.degrees(style.rotation))
            .scaleEffect(x: style.scaleX, y: style.scaleY)
    }
}

// MARK: - Manga Emotion Text (e.g., "!?", "...")

struct EmotionTextView: View {
    enum EmotionType {
        case surprise  // !?
        case ellipsis  // ...
        case anger     // !!!
        case confusion // ???
        case love      // heart
    }

    let type: EmotionType
    let size: CGFloat
    let color: Color

    var body: some View {
        switch type {
        case .surprise:
            Text("!?")
                .font(.system(size: size, weight: .black))
                .foregroundColor(color)
                .rotationEffect(.degrees(-10))

        case .ellipsis:
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(color)
                        .frame(width: size * 0.15, height: size * 0.15)
                }
            }

        case .anger:
            Text("!!!")
                .font(.system(size: size, weight: .black))
                .foregroundStyle(
                    LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                )

        case .confusion:
            Text("???")
                .font(.system(size: size, weight: .bold))
                .foregroundColor(color)

        case .love:
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.8))
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .red], startPoint: .top, endPoint: .bottom)
                )
        }
    }
}

// MARK: - Previews

#Preview("Comic Text Effects") {
    VStack(spacing: 30) {
        ForEach(TextEffect.allCases) { effect in
            Text(effect.displayName)
                .font(.custom("AvenirNext-Bold", size: 24))
                .foregroundColor(.black)
        }
    }
    .padding()
}

#Preview("Sound Effects") {
    VStack(spacing: 20) {
        StyledSoundEffectView(text: "BOOM!", style: .boom)
        StyledSoundEffectView(text: "POW!", style: .pow)
        StyledSoundEffectView(text: "WHOOSH", style: .whoosh)
        StyledSoundEffectView(text: "CRACK!", style: .crack)
    }
    .padding()
}

#Preview("Vertical Text") {
    HStack(spacing: 40) {
        VerticalTextView(
            text: "こんにちは",
            fontSize: 24,
            fontName: "HiraginoSans-W6",
            color: .black,
            furigana: nil
        )

        VerticalTextView(
            text: "漢字",
            fontSize: 24,
            fontName: "HiraginoSans-W6",
            color: .black,
            furigana: "かんじ"
        )
    }
    .padding()
}
