import SwiftUI
import SwiftData

@main
struct StoryFrameApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ComicProject.self,
            ComicPage.self,
            Panel.self,
            SpeechBubble.self,
            TextElement.self,
            DrawingLayer.self,
            PanelTemplate.self,
            AssetItem.self,
            AppSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @State private var selectedProject: ComicProject?

    var body: some View {
        NavigationStack {
            ProjectsLibraryView(selectedProject: $selectedProject)
                .navigationDestination(item: $selectedProject) { project in
                    PageEditorView(project: project)
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            ComicProject.self,
            ComicPage.self,
            Panel.self,
            SpeechBubble.self,
            TextElement.self,
            DrawingLayer.self,
            PanelTemplate.self,
            AssetItem.self,
            AppSettings.self
        ], inMemory: true)
}
