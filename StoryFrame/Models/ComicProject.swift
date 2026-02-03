import SwiftData
import SwiftUI
import PencilKit

// MARK: - Comic Project
@Model
final class ComicProject {
    var id: UUID
    var title: String
    var createdAt: Date
    var modifiedAt: Date
    var format: String
    var pageWidth: Double
    var pageHeight: Double
    var readingDirection: String
    var coverImageData: Data?
    @Relationship(deleteRule: .cascade) var pages: [ComicPage]
    var genre: String?
    var isCompleted: Bool

    init(title: String, format: String, width: Double, height: Double, direction: String = "ltr") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.format = format
        self.pageWidth = width
        self.pageHeight = height
        self.readingDirection = direction
        self.pages = []
        self.isCompleted = false
    }

    var sortedPages: [ComicPage] {
        pages.sorted { $0.pageNumber < $1.pageNumber }
    }

    func addPage() -> ComicPage {
        let newPageNumber = (pages.map { $0.pageNumber }.max() ?? 0) + 1
        let page = ComicPage(pageNumber: newPageNumber)
        pages.append(page)
        modifiedAt = Date()
        return page
    }
}

// MARK: - Comic Page
@Model
final class ComicPage {
    var id: UUID
    var pageNumber: Int
    var thumbnailData: Data?
    @Relationship(deleteRule: .cascade) var panels: [Panel]
    @Relationship(deleteRule: .cascade) var layers: [DrawingLayer]
    var templateId: String?

    init(pageNumber: Int) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.panels = []
        self.layers = []
    }

    var sortedPanels: [Panel] {
        panels.sorted { $0.orderIndex < $1.orderIndex }
    }

    var sortedLayers: [DrawingLayer] {
        layers.sorted { $0.orderIndex < $1.orderIndex }
    }
}

// MARK: - Panel
@Model
final class Panel {
    var id: UUID
    var orderIndex: Int
    var framePointsData: Data
    var backgroundColor: String?
    var borderWidth: Double
    var borderColor: String
    @Relationship(deleteRule: .cascade) var bubbles: [SpeechBubble]
    @Relationship(deleteRule: .cascade) var textElements: [TextElement]

    init(orderIndex: Int, framePoints: [CGPoint]) {
        self.id = UUID()
        self.orderIndex = orderIndex
        self.framePointsData = (try? JSONEncoder().encode(framePoints.map { PointWrapper(point: $0) })) ?? Data()
        self.borderWidth = 2.0
        self.borderColor = "#000000"
        self.bubbles = []
        self.textElements = []
    }

    var framePoints: [CGPoint] {
        get {
            guard let wrappers = try? JSONDecoder().decode([PointWrapper].self, from: framePointsData) else {
                return []
            }
            return wrappers.map { $0.point }
        }
        set {
            framePointsData = (try? JSONEncoder().encode(newValue.map { PointWrapper(point: $0) })) ?? Data()
        }
    }

    var boundingRect: CGRect {
        guard !framePoints.isEmpty else { return .zero }
        let xs = framePoints.map { $0.x }
        let ys = framePoints.map { $0.y }
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Speech Bubble
@Model
final class SpeechBubble {
    var id: UUID
    var bubbleType: String
    var centerX: Double
    var centerY: Double
    var width: Double
    var height: Double
    var rotation: Double
    var text: String
    var fontName: String
    var fontSize: Double
    var fontColor: String
    var textAlignment: String
    var isVertical: Bool
    var tailX: Double
    var tailY: Double
    var tailStyle: String
    var borderWidth: Double
    var borderColor: String
    var fillColor: String
    var fillOpacity: Double
    var hasShadow: Bool
    var linkedBubbleId: UUID?
    var orderInChain: Int
    var customPathData: Data?

    init(type: String, center: CGPoint, size: CGSize) {
        self.id = UUID()
        self.bubbleType = type
        self.centerX = center.x
        self.centerY = center.y
        self.width = size.width
        self.height = size.height
        self.rotation = 0
        self.text = ""
        self.fontName = "AvenirNext-Bold"
        self.fontSize = 16
        self.fontColor = "#000000"
        self.textAlignment = "center"
        self.isVertical = false
        self.tailX = center.x
        self.tailY = center.y + size.height/2 + 20
        self.tailStyle = "curved"
        self.borderWidth = 2
        self.borderColor = "#000000"
        self.fillColor = "#FFFFFF"
        self.fillOpacity = 1.0
        self.hasShadow = false
        self.orderInChain = 0
    }

    var center: CGPoint {
        get { CGPoint(x: centerX, y: centerY) }
        set { centerX = newValue.x; centerY = newValue.y }
    }

    var size: CGSize {
        get { CGSize(width: width, height: height) }
        set { width = newValue.width; height = newValue.height }
    }

    var tailPoint: CGPoint {
        get { CGPoint(x: tailX, y: tailY) }
        set { tailX = newValue.x; tailY = newValue.y }
    }

    var frame: CGRect {
        CGRect(x: centerX - width/2, y: centerY - height/2, width: width, height: height)
    }
}

// MARK: - Text Element
@Model
final class TextElement {
    var id: UUID
    var text: String
    var x: Double
    var y: Double
    var width: Double
    var fontName: String
    var fontSize: Double
    var fontColor: String
    var alignment: String
    var isVertical: Bool
    var rotation: Double
    var effect: String
    var effectIntensity: Double
    var furiganaText: String?
    var isSoundEffect: Bool

    init(text: String, position: CGPoint) {
        self.id = UUID()
        self.text = text
        self.x = position.x
        self.y = position.y
        self.width = 200
        self.fontName = "AvenirNext-Bold"
        self.fontSize = 24
        self.fontColor = "#000000"
        self.alignment = "center"
        self.isVertical = false
        self.rotation = 0
        self.effect = "none"
        self.effectIntensity = 1.0
        self.isSoundEffect = false
    }

    var position: CGPoint {
        get { CGPoint(x: x, y: y) }
        set { x = newValue.x; y = newValue.y }
    }
}

// MARK: - Drawing Layer
@Model
final class DrawingLayer {
    var id: UUID
    var name: String
    var orderIndex: Int
    var isVisible: Bool
    var isLocked: Bool
    var opacity: Double
    var drawingData: Data?

    init(name: String, orderIndex: Int) {
        self.id = UUID()
        self.name = name
        self.orderIndex = orderIndex
        self.isVisible = true
        self.isLocked = false
        self.opacity = 1.0
    }

    var drawing: PKDrawing? {
        get {
            guard let data = drawingData else { return nil }
            return try? PKDrawing(data: data)
        }
        set {
            drawingData = newValue?.dataRepresentation()
        }
    }
}

// MARK: - Panel Template
@Model
final class PanelTemplate {
    var id: UUID
    var name: String
    var category: String
    var panelData: Data
    var isBuiltIn: Bool
    var previewImageData: Data?

    init(name: String, category: String, panels: [[[CGPoint]]], isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.category = category
        let wrappers = panels.map { $0.map { $0.map { PointWrapper(point: $0) } } }
        self.panelData = (try? JSONEncoder().encode(wrappers)) ?? Data()
        self.isBuiltIn = isBuiltIn
    }

    var panels: [[[CGPoint]]] {
        guard let wrappers = try? JSONDecoder().decode([[[PointWrapper]]].self, from: panelData) else {
            return []
        }
        return wrappers.map { $0.map { $0.map { $0.point } } }
    }
}

// MARK: - Asset Item
@Model
final class AssetItem {
    var id: UUID
    var name: String
    var category: String
    var imageData: Data
    var isBuiltIn: Bool
    var tags: String

    init(name: String, category: String, imageData: Data, isBuiltIn: Bool = true) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.imageData = imageData
        self.isBuiltIn = isBuiltIn
        self.tags = ""
    }
}

// MARK: - App Settings
@Model
final class AppSettings {
    var id: UUID
    var defaultFormat: String
    var defaultReadingDirection: String
    var defaultGutterWidth: Double
    var showSafeArea: Bool
    var showBleedArea: Bool
    var defaultBubbleType: String
    var defaultFontName: String
    var defaultFontSize: Double
    var autoSaveInterval: Int
    var pencilDoubleTapAction: String
    var enableFaceDetection: Bool
    var enable3DPoseReference: Bool
    var enableLiDARPerspective: Bool
    var theme: String

    init() {
        self.id = UUID()
        self.defaultFormat = "us_comic"
        self.defaultReadingDirection = "ltr"
        self.defaultGutterWidth = 10
        self.showSafeArea = true
        self.showBleedArea = true
        self.defaultBubbleType = "oval"
        self.defaultFontName = "AvenirNext-Bold"
        self.defaultFontSize = 16
        self.autoSaveInterval = 30
        self.pencilDoubleTapAction = "eraser"
        self.enableFaceDetection = true
        self.enable3DPoseReference = true
        self.enableLiDARPerspective = true
        self.theme = "system"
    }
}

// MARK: - Helper Types
struct PointWrapper: Codable {
    let x: Double
    let y: Double

    init(point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }

    var point: CGPoint {
        CGPoint(x: x, y: y)
    }
}

// MARK: - Enums
enum ComicFormat: String, CaseIterable, Identifiable {
    case usComic = "us_comic"
    case manga = "manga"
    case webtoon = "webtoon"
    case square = "square"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .usComic: return "US Comic"
        case .manga: return "Manga Tankōbon"
        case .webtoon: return "Webtoon"
        case .square: return "Square (Instagram)"
        case .custom: return "Custom"
        }
    }

    var dimensions: CGSize {
        switch self {
        case .usComic: return CGSize(width: 6.625 * 72, height: 10.25 * 72)
        case .manga: return CGSize(width: 5 * 72, height: 7.5 * 72)
        case .webtoon: return CGSize(width: 800, height: 1280)
        case .square: return CGSize(width: 1080, height: 1080)
        case .custom: return CGSize(width: 612, height: 792)
        }
    }

    var description: String {
        switch self {
        case .usComic: return "6.625\" × 10.25\""
        case .manga: return "5\" × 7.5\""
        case .webtoon: return "800px wide, scroll"
        case .square: return "1080 × 1080"
        case .custom: return "Custom size"
        }
    }
}

enum ReadingDirection: String, CaseIterable, Identifiable {
    case leftToRight = "ltr"
    case rightToLeft = "rtl"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .leftToRight: return "Left to Right (Western)"
        case .rightToLeft: return "Right to Left (Manga)"
        }
    }
}

enum BubbleType: String, CaseIterable, Identifiable {
    case oval = "oval"
    case rectangle = "rectangle"
    case cloud = "cloud"
    case burst = "burst"
    case whisper = "whisper"
    case electronic = "electronic"
    case drip = "drip"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oval: return "Speech"
        case .rectangle: return "Narration"
        case .cloud: return "Thought"
        case .burst: return "Shout"
        case .whisper: return "Whisper"
        case .electronic: return "Electronic"
        case .drip: return "Horror"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .oval: return "bubble.left"
        case .rectangle: return "rectangle"
        case .cloud: return "cloud"
        case .burst: return "star.fill"
        case .whisper: return "bubble.left.and.bubble.right"
        case .electronic: return "cpu"
        case .drip: return "drop.fill"
        case .custom: return "scribble"
        }
    }
}

enum TextEffect: String, CaseIterable, Identifiable {
    case none = "none"
    case shake = "shake"
    case grow = "grow"
    case shrink = "shrink"
    case glow = "glow"
    case shadow = "shadow"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .shake: return "Shake"
        case .grow: return "Growing"
        case .shrink: return "Shrinking"
        case .glow: return "Glow"
        case .shadow: return "Shadow"
        }
    }
}

enum TemplateCategory: String, CaseIterable, Identifiable {
    case action = "action"
    case conversation = "conversation"
    case establishing = "establishing"
    case montage = "montage"
    case splash = "splash"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .action: return "Action"
        case .conversation: return "Conversation"
        case .establishing: return "Establishing"
        case .montage: return "Montage"
        case .splash: return "Full Page"
        }
    }

    var description: String {
        switch self {
        case .action: return "Dynamic, diagonal panels"
        case .conversation: return "Even splits for dialogue"
        case .establishing: return "Large + small panels"
        case .montage: return "Many small panels"
        case .splash: return "Single full page"
        }
    }
}

enum AssetCategory: String, CaseIterable, Identifiable {
    case speedlines = "speedlines"
    case effects = "effects"
    case screentones = "screentones"
    case soundeffects = "soundeffects"
    case emotions = "emotions"
    case backgrounds = "backgrounds"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .speedlines: return "Speed Lines"
        case .effects: return "Impact Effects"
        case .screentones: return "Screentones"
        case .soundeffects: return "Sound Effects"
        case .emotions: return "Emotion Symbols"
        case .backgrounds: return "Backgrounds"
        }
    }

    var icon: String {
        switch self {
        case .speedlines: return "wind"
        case .effects: return "sparkles"
        case .screentones: return "circle.dotted"
        case .soundeffects: return "waveform"
        case .emotions: return "face.smiling"
        case .backgrounds: return "photo"
        }
    }
}

// MARK: - Tool Types
enum EditorTool: String, CaseIterable, Identifiable {
    case selection = "selection"
    case panel = "panel"
    case brush = "brush"
    case eraser = "eraser"
    case bubble = "bubble"
    case text = "text"
    case shape = "shape"
    case asset = "asset"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .selection: return "Select"
        case .panel: return "Panel"
        case .brush: return "Brush"
        case .eraser: return "Eraser"
        case .bubble: return "Bubble"
        case .text: return "Text"
        case .shape: return "Shape"
        case .asset: return "Asset"
        }
    }

    var icon: String {
        switch self {
        case .selection: return "arrow.up.left.and.arrow.down.right"
        case .panel: return "rectangle.split.3x3"
        case .brush: return "paintbrush.pointed"
        case .eraser: return "eraser"
        case .bubble: return "bubble.left"
        case .text: return "textformat"
        case .shape: return "square.on.circle"
        case .asset: return "photo.on.rectangle"
        }
    }
}

enum BrushType: String, CaseIterable, Identifiable {
    case brush = "brush"
    case pen = "pen"
    case pencil = "pencil"
    case marker = "marker"
    case gpen = "gpen"
    case marupen = "marupen"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brush: return "Brush"
        case .pen: return "Pen"
        case .pencil: return "Pencil"
        case .marker: return "Marker"
        case .gpen: return "G-Pen"
        case .marupen: return "Maru-Pen"
        }
    }

    var icon: String {
        switch self {
        case .brush: return "paintbrush"
        case .pen: return "pencil"
        case .pencil: return "pencil.line"
        case .marker: return "highlighter"
        case .gpen: return "pencil.tip"
        case .marupen: return "pencil.tip.crop.circle"
        }
    }
}
