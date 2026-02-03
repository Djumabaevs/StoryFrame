import SwiftUI

struct ProjectCardView: View {
    let project: ComicProject

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage
            projectInfo
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var coverImage: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let coverData = project.coverImageData,
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: formatIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(formatLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            VStack {
                HStack {
                    Spacer()
                    if project.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                            .padding(8)
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    Text("\(project.pages.count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var projectInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            HStack {
                Text(project.modifiedAt.relativeFormat())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let genre = project.genre, !genre.isEmpty {
                    Text(genre)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#7B68EE").opacity(0.2))
                        .foregroundStyle(Color(hex: "#7B68EE"))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
    }

    private var gradientColors: [Color] {
        switch project.format {
        case "us_comic":
            return [Color(hex: "#FF6B35"), Color(hex: "#FF8C5A")]
        case "manga":
            return [Color(hex: "#7B68EE"), Color(hex: "#9D8DF1")]
        case "webtoon":
            return [Color(hex: "#4A90D9"), Color(hex: "#5AA3E8")]
        case "square":
            return [Color(hex: "#34C759"), Color(hex: "#30D158")]
        default:
            return [Color(.systemGray3), Color(.systemGray4)]
        }
    }

    private var formatIcon: String {
        switch project.format {
        case "us_comic": return "book.pages"
        case "manga": return "text.book.closed"
        case "webtoon": return "arrow.up.and.down.text.horizontal"
        case "square": return "square"
        default: return "doc.richtext"
        }
    }

    private var formatLabel: String {
        ComicFormat(rawValue: project.format)?.displayName ?? "Custom"
    }
}

#Preview {
    let project = ComicProject(
        title: "My First Comic",
        format: "us_comic",
        width: 477,
        height: 738
    )
    project.genre = "Action"

    return ProjectCardView(project: project)
        .frame(width: 180)
        .padding()
}
