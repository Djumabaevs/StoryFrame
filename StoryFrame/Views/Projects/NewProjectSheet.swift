import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var projectName = ""
    @State private var selectedFormat: ComicFormat = .usComic
    @State private var readingDirection: ReadingDirection = .leftToRight
    @State private var initialPages = 1
    @State private var customWidth: Double = 612
    @State private var customHeight: Double = 792

    let onCreate: (ComicProject) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $projectName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                }

                Section {
                    ForEach(ComicFormat.allCases) { format in
                        FormatRow(
                            format: format,
                            isSelected: selectedFormat == format
                        ) {
                            selectedFormat = format
                            HapticManager.shared.toolSelected()
                        }
                    }

                    if selectedFormat == .custom {
                        HStack {
                            Text("Width")
                            Spacer()
                            TextField("Width", value: $customWidth, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("pt")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("Height", value: $customHeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("pt")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Format")
                } footer: {
                    Text("Choose a format that matches your target platform or publication.")
                }

                Section {
                    ForEach(ReadingDirection.allCases) { direction in
                        DirectionRow(
                            direction: direction,
                            isSelected: readingDirection == direction
                        ) {
                            readingDirection = direction
                            HapticManager.shared.toolSelected()
                        }
                    }
                } header: {
                    Text("Reading Direction")
                } footer: {
                    Text("Manga typically reads right-to-left. Western comics read left-to-right.")
                }

                Section {
                    Stepper("Initial Pages: \(initialPages)", value: $initialPages, in: 1...20)
                } header: {
                    Text("Pages")
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .fontWeight(.semibold)
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createProject() {
        let dimensions: CGSize
        if selectedFormat == .custom {
            dimensions = CGSize(width: customWidth, height: customHeight)
        } else {
            dimensions = selectedFormat.dimensions
        }

        let project = ComicProject(
            title: projectName.trimmingCharacters(in: .whitespaces),
            format: selectedFormat.rawValue,
            width: dimensions.width,
            height: dimensions.height,
            direction: readingDirection.rawValue
        )

        for i in 1...initialPages {
            let page = ComicPage(pageNumber: i)
            project.pages.append(page)
        }

        HapticManager.shared.success()
        onCreate(project)
        dismiss()
    }
}

struct FormatRow: View {
    let format: ComicFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(format.displayName)
                        .foregroundStyle(.primary)

                    Text(format.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#FF6B35"))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct DirectionRow: View {
    let direction: ReadingDirection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: direction == .leftToRight ? "arrow.right" : "arrow.left")
                    .font(.title3)
                    .frame(width: 30)

                Text(direction.displayName)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#FF6B35"))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NewProjectSheet { project in
        print("Created: \(project.title)")
    }
}
