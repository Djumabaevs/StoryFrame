import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    private var settings: AppSettings {
        settingsList.first ?? AppSettings()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Default Project Settings") {
                    Picker("Format", selection: Binding(
                        get: { ComicFormat(rawValue: settings.defaultFormat) ?? .usComic },
                        set: { settings.defaultFormat = $0.rawValue }
                    )) {
                        ForEach(ComicFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }

                    Picker("Reading Direction", selection: Binding(
                        get: { ReadingDirection(rawValue: settings.defaultReadingDirection) ?? .leftToRight },
                        set: { settings.defaultReadingDirection = $0.rawValue }
                    )) {
                        ForEach(ReadingDirection.allCases) { direction in
                            Text(direction.displayName).tag(direction)
                        }
                    }

                    HStack {
                        Text("Default Gutter Width")
                        Spacer()
                        Text("\(Int(settings.defaultGutterWidth)) pt")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Canvas") {
                    Toggle("Show Safe Area", isOn: Binding(
                        get: { settings.showSafeArea },
                        set: { settings.showSafeArea = $0 }
                    ))

                    Toggle("Show Bleed Area", isOn: Binding(
                        get: { settings.showBleedArea },
                        set: { settings.showBleedArea = $0 }
                    ))
                }

                Section("Bubble Defaults") {
                    Picker("Default Type", selection: Binding(
                        get: { BubbleType(rawValue: settings.defaultBubbleType) ?? .oval },
                        set: { settings.defaultBubbleType = $0.rawValue }
                    )) {
                        ForEach(BubbleType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }

                    HStack {
                        Text("Default Font Size")
                        Spacer()
                        Text("\(Int(settings.defaultFontSize)) pt")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("AI Features") {
                    Toggle("Face Detection", isOn: Binding(
                        get: { settings.enableFaceDetection },
                        set: { settings.enableFaceDetection = $0 }
                    ))

                    Toggle("3D Pose Reference", isOn: Binding(
                        get: { settings.enable3DPoseReference },
                        set: { settings.enable3DPoseReference = $0 }
                    ))

                    Toggle("LiDAR Perspective", isOn: Binding(
                        get: { settings.enableLiDARPerspective },
                        set: { settings.enableLiDARPerspective = $0 }
                    ))
                }

                Section("Apple Pencil") {
                    Picker("Double Tap Action", selection: Binding(
                        get: { settings.pencilDoubleTapAction },
                        set: { settings.pencilDoubleTapAction = $0 }
                    )) {
                        Text("Eraser").tag("eraser")
                        Text("Last Tool").tag("last_tool")
                        Text("Color Picker").tag("color_picker")
                        Text("Undo").tag("undo")
                    }
                }

                Section("Auto-Save") {
                    Picker("Interval", selection: Binding(
                        get: { settings.autoSaveInterval },
                        set: { settings.autoSaveInterval = $0 }
                    )) {
                        Text("15 seconds").tag(15)
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("2 minutes").tag(120)
                        Text("Manual only").tag(0)
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { settings.theme },
                        set: { settings.theme = $0 }
                    )) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://storyframe.app/help")!) {
                        HStack {
                            Text("Help & Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                ensureSettings()
            }
        }
    }

    private func ensureSettings() {
        if settingsList.isEmpty {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}
