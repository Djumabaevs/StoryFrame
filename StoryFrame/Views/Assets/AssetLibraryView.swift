import SwiftUI

struct AssetLibraryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: AssetCategory = .speedlines
    @State private var searchText = ""

    var onAssetSelected: ((BuiltInAsset) -> Void)?

    init(onAssetSelected: ((BuiltInAsset) -> Void)? = nil) {
        self.onAssetSelected = onAssetSelected
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPicker

                assetGrid
            }
            .navigationTitle("Asset Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search assets")
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AssetCategory.allCases) { category in
                    CategoryButton(
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

    private var assetGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)
            ], spacing: 12) {
                ForEach(assetsForCategory, id: \.name) { asset in
                    AssetCard(asset: asset) {
                        // Handle asset selection
                        HapticManager.shared.tap()
                        onAssetSelected?(asset)
                        dismiss()
                    }
                }
            }
            .padding()
        }
    }

    private var assetsForCategory: [BuiltInAsset] {
        BuiltInAssets.assets(for: selectedCategory)
            .filter { asset in
                searchText.isEmpty || asset.name.localizedCaseInsensitiveContains(searchText)
            }
    }
}

struct CategoryButton: View {
    let category: AssetCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.displayName)
                    .font(.caption2)
            }
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "#FF6B35") : Color(.systemGray5))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct AssetCard: View {
    let asset: BuiltInAsset
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))

                    asset.preview
                        .frame(width: 80, height: 80)
                }
                .frame(height: 100)

                Text(asset.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.spring(response: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Built-in Assets

struct BuiltInAsset {
    let name: String
    let category: AssetCategory
    let preview: AnyView

    init<V: View>(name: String, category: AssetCategory, @ViewBuilder preview: () -> V) {
        self.name = name
        self.category = category
        self.preview = AnyView(preview())
    }
}

struct BuiltInAssets {
    static func assets(for category: AssetCategory) -> [BuiltInAsset] {
        switch category {
        case .speedlines:
            return speedLineAssets
        case .effects:
            return effectAssets
        case .screentones:
            return screentoneAssets
        case .soundeffects:
            return soundEffectAssets
        case .emotions:
            return emotionAssets
        case .backgrounds:
            return backgroundAssets
        }
    }

    static let speedLineAssets: [BuiltInAsset] = [
        BuiltInAsset(name: "Radial Burst", category: .speedlines) {
            SpeedLinePreview(style: .radial)
        },
        BuiltInAsset(name: "Horizontal", category: .speedlines) {
            SpeedLinePreview(style: .horizontal)
        },
        BuiltInAsset(name: "Diagonal Left", category: .speedlines) {
            SpeedLinePreview(style: .diagonalLeft)
        },
        BuiltInAsset(name: "Diagonal Right", category: .speedlines) {
            SpeedLinePreview(style: .diagonalRight)
        },
        BuiltInAsset(name: "Converging", category: .speedlines) {
            SpeedLinePreview(style: .converging)
        },
        BuiltInAsset(name: "Impact", category: .speedlines) {
            SpeedLinePreview(style: .impact)
        }
    ]

    static let effectAssets: [BuiltInAsset] = [
        BuiltInAsset(name: "Starburst", category: .effects) {
            StarburstPreview()
        },
        BuiltInAsset(name: "Shockwave", category: .effects) {
            ShockwavePreview()
        },
        BuiltInAsset(name: "Sparkles", category: .effects) {
            SparklesPreview()
        },
        BuiltInAsset(name: "Flash", category: .effects) {
            FlashPreview()
        }
    ]

    static let screentoneAssets: [BuiltInAsset] = [
        BuiltInAsset(name: "Dots Light", category: .screentones) {
            ScreentonePreview(density: 0.3)
        },
        BuiltInAsset(name: "Dots Medium", category: .screentones) {
            ScreentonePreview(density: 0.5)
        },
        BuiltInAsset(name: "Dots Heavy", category: .screentones) {
            ScreentonePreview(density: 0.8)
        },
        BuiltInAsset(name: "Lines", category: .screentones) {
            LinePatternPreview()
        },
        BuiltInAsset(name: "Crosshatch", category: .screentones) {
            CrosshatchPreview()
        },
        BuiltInAsset(name: "Gradient", category: .screentones) {
            GradientTonePreview()
        }
    ]

    static let soundEffectAssets: [BuiltInAsset] = [
        BuiltInAsset(name: "BOOM!", category: .soundeffects) {
            SoundEffectPreview(text: "BOOM!", color: .red)
        },
        BuiltInAsset(name: "POW!", category: .soundeffects) {
            SoundEffectPreview(text: "POW!", color: .blue)
        },
        BuiltInAsset(name: "CRASH!", category: .soundeffects) {
            SoundEffectPreview(text: "CRASH!", color: .orange)
        },
        BuiltInAsset(name: "WHOOSH", category: .soundeffects) {
            SoundEffectPreview(text: "WHOOSH", color: .cyan)
        },
        BuiltInAsset(name: "BANG!", category: .soundeffects) {
            SoundEffectPreview(text: "BANG!", color: .purple)
        },
        BuiltInAsset(name: "ZAP!", category: .soundeffects) {
            SoundEffectPreview(text: "ZAP!", color: .yellow)
        }
    ]

    static let emotionAssets: [BuiltInAsset] = [
        BuiltInAsset(name: "Sweat Drop", category: .emotions) {
            EmotionSymbolPreview(type: .sweat)
        },
        BuiltInAsset(name: "Anger Veins", category: .emotions) {
            EmotionSymbolPreview(type: .anger)
        },
        BuiltInAsset(name: "Heart", category: .emotions) {
            EmotionSymbolPreview(type: .love)
        },
        BuiltInAsset(name: "Question", category: .emotions) {
            EmotionSymbolPreview(type: .confusion)
        },
        BuiltInAsset(name: "Exclamation", category: .emotions) {
            EmotionSymbolPreview(type: .surprise)
        },
        BuiltInAsset(name: "Zzz", category: .emotions) {
            EmotionSymbolPreview(type: .sleep)
        }
    ]

    static let backgroundAssets: [BuiltInAsset] = [
        BuiltInAsset(name: "Dramatic Lines", category: .backgrounds) {
            DramaticLinesPreview()
        },
        BuiltInAsset(name: "Focus Burst", category: .backgrounds) {
            FocusBurstPreview()
        },
        BuiltInAsset(name: "Dark Gradient", category: .backgrounds) {
            DarkGradientPreview()
        },
        BuiltInAsset(name: "Sparkle BG", category: .backgrounds) {
            SparkleBackgroundPreview()
        }
    ]
}

// MARK: - Asset Preview Views

struct SpeedLinePreview: View {
    enum Style { case radial, horizontal, diagonalLeft, diagonalRight, converging, impact }
    let style: Style

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            switch style {
            case .radial:
                for i in 0..<24 {
                    let angle = (CGFloat(i) / 24) * 2 * .pi
                    var path = Path()
                    path.move(to: CGPoint(x: center.x + cos(angle) * 10, y: center.y + sin(angle) * 10))
                    path.addLine(to: CGPoint(x: center.x + cos(angle) * 40, y: center.y + sin(angle) * 40))
                    context.stroke(path, with: .color(.black), lineWidth: 1)
                }
            case .horizontal:
                for i in stride(from: 10, to: size.height - 10, by: 6) {
                    var path = Path()
                    path.move(to: CGPoint(x: 5, y: CGFloat(i)))
                    path.addLine(to: CGPoint(x: size.width - 5, y: CGFloat(i)))
                    context.stroke(path, with: .color(.black), lineWidth: 0.5)
                }
            case .diagonalLeft:
                for i in stride(from: -40, to: 120, by: 8) {
                    var path = Path()
                    path.move(to: CGPoint(x: CGFloat(i), y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(i) + 80, y: 80))
                    context.stroke(path, with: .color(.black), lineWidth: 0.5)
                }
            case .diagonalRight:
                for i in stride(from: -40, to: 120, by: 8) {
                    var path = Path()
                    path.move(to: CGPoint(x: CGFloat(i), y: 80))
                    path.addLine(to: CGPoint(x: CGFloat(i) + 80, y: 0))
                    context.stroke(path, with: .color(.black), lineWidth: 0.5)
                }
            case .converging:
                let vp = CGPoint(x: size.width / 2, y: size.height / 2)
                for x in stride(from: 0, to: size.width, by: 10) {
                    var path = Path()
                    path.move(to: vp)
                    path.addLine(to: CGPoint(x: CGFloat(x), y: size.height))
                    context.stroke(path, with: .color(.black), lineWidth: 0.5)
                }
            case .impact:
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for i in 0..<16 {
                    let angle = (CGFloat(i) / 16) * 2 * .pi
                    var path = Path()
                    path.move(to: CGPoint(x: center.x + cos(angle) * 15, y: center.y + sin(angle) * 15))
                    path.addLine(to: CGPoint(x: center.x + cos(angle) * 35, y: center.y + sin(angle) * 35))
                    context.stroke(path, with: .color(.black), lineWidth: 2)
                }
            }
        }
    }
}

struct StarburstPreview: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let path = ImpactEffectGenerator.generateStarburst(center: center, size: 60, points: 8)
            context.fill(path, with: .color(.yellow))
            context.stroke(path, with: .color(.orange), lineWidth: 2)
        }
    }
}

struct ShockwavePreview: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 1...3 {
                let radius = CGFloat(i) * 15
                var path = Path()
                path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                context.stroke(path, with: .color(.blue.opacity(1.0 - Double(i) * 0.25)), lineWidth: 2)
            }
        }
    }
}

struct SparklesPreview: View {
    var body: some View {
        Canvas { context, size in
            let sparklePositions: [(CGFloat, CGFloat, CGFloat)] = [
                (0.3, 0.3, 8), (0.7, 0.2, 6), (0.5, 0.6, 10),
                (0.2, 0.7, 5), (0.8, 0.8, 7)
            ]
            for (x, y, s) in sparklePositions {
                let pos = CGPoint(x: x * size.width, y: y * size.height)
                var path = Path()
                // 4-point star
                path.move(to: CGPoint(x: pos.x, y: pos.y - s))
                path.addLine(to: CGPoint(x: pos.x + 2, y: pos.y - 2))
                path.addLine(to: CGPoint(x: pos.x + s, y: pos.y))
                path.addLine(to: CGPoint(x: pos.x + 2, y: pos.y + 2))
                path.addLine(to: CGPoint(x: pos.x, y: pos.y + s))
                path.addLine(to: CGPoint(x: pos.x - 2, y: pos.y + 2))
                path.addLine(to: CGPoint(x: pos.x - s, y: pos.y))
                path.addLine(to: CGPoint(x: pos.x - 2, y: pos.y - 2))
                path.closeSubpath()
                context.fill(path, with: .color(.yellow))
            }
        }
    }
}

struct FlashPreview: View {
    var body: some View {
        RadialGradient(
            colors: [.white, .white.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: 40
        )
    }
}

struct ScreentonePreview: View {
    let density: CGFloat

    var body: some View {
        Canvas { context, size in
            let spacing = 8 / density
            for y in stride(from: 0, to: size.height, by: spacing) {
                for x in stride(from: 0, to: size.width, by: spacing) {
                    let circle = Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2))
                    context.fill(circle, with: .color(.black))
                }
            }
        }
    }
}

struct LinePatternPreview: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 4) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.black), lineWidth: 0.5)
            }
        }
    }
}

struct CrosshatchPreview: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 6) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.black), lineWidth: 0.3)
            }
            for x in stride(from: 0, to: size.width, by: 6) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.black), lineWidth: 0.3)
            }
        }
    }
}

struct GradientTonePreview: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 4) {
                let progress = y / size.height
                for x in stride(from: 0, to: size.width, by: 4) {
                    if CGFloat.random(in: 0...1) < progress {
                        let circle = Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2))
                        context.fill(circle, with: .color(.black))
                    }
                }
            }
        }
    }
}

struct SoundEffectPreview: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .rotationEffect(.degrees(-10))
    }
}

struct EmotionSymbolPreview: View {
    enum EmotionType { case sweat, anger, love, confusion, surprise, sleep }
    let type: EmotionType

    var body: some View {
        Group {
            switch type {
            case .sweat:
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
            case .anger:
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.red)
            case .love:
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
            case .confusion:
                Text("?")
                    .font(.title.bold())
            case .surprise:
                Text("!")
                    .font(.title.bold())
            case .sleep:
                Text("Zzz")
                    .font(.caption.bold())
            }
        }
        .font(.title)
    }
}

struct DramaticLinesPreview: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: 0)
            for i in 0..<20 {
                let x = CGFloat(i) / 20 * size.width
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.black.opacity(0.5)), lineWidth: 1)
            }
        }
    }
}

struct FocusBurstPreview: View {
    var body: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(0.8)],
            center: .center,
            startRadius: 10,
            endRadius: 50
        )
    }
}

struct DarkGradientPreview: View {
    var body: some View {
        LinearGradient(
            colors: [.black, .gray, .black],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct SparkleBackgroundPreview: View {
    var body: some View {
        ZStack {
            Color.black
            SparklesPreview()
        }
    }
}

#Preview {
    AssetLibraryView()
}
