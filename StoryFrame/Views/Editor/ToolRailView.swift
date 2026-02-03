import SwiftUI

struct ToolRailView: View {
    @Binding var selectedTool: EditorTool
    let onAssetTapped: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(EditorTool.allCases) { tool in
                ToolRailButton(
                    tool: tool,
                    isSelected: selectedTool == tool
                ) {
                    selectedTool = tool
                    HapticManager.shared.toolSelected()
                }
            }

            Spacer()

            Divider()
                .padding(.horizontal, 8)

            Button {
                onAssetTapped()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "folder")
                        .font(.title3)
                    Text("Assets")
                        .font(.system(size: 9))
                }
                .frame(width: 44, height: 50)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .frame(width: 56)
        .background(Color(.systemBackground))
    }
}

struct ToolRailButton: View {
    let tool: EditorTool
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tool.icon)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                Text(tool.displayName)
                    .font(.system(size: 9))
            }
            .frame(width: 44, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#FF6B35").opacity(0.15) : Color.clear)
            )
            .foregroundStyle(isSelected ? Color(hex: "#FF6B35") : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#FF6B35") : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : (isSelected ? 1.05 : 1))
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
        .animation(.spring(response: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Tool Submenu (for brush types, etc.)

struct ToolSubmenu<Content: View>: View {
    let isPresented: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isPresented {
            VStack(spacing: 4) {
                content()
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 2, y: 2)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8, anchor: .leading).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
}

#Preview {
    ToolRailView(
        selectedTool: .constant(.brush),
        onAssetTapped: {}
    )
}
