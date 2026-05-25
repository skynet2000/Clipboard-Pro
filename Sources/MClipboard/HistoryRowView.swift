import SwiftUI

struct HistoryRowView: View {
    @ObservedObject var item: ClipboardItemEntity

    let isSelected: Bool
    let onSelect: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            thumbnailView

            VStack(alignment: .leading, spacing: 3) {
                Text(item.type == "image" ? "🖼 Image" : previewText)
                    .font(.system(size: 12.5))
                    .foregroundColor(
                        item.isPinned
                            ? Color(red: 0.15, green: 0.25, blue: 0.45)
                            : .primary
                    )
                    .lineLimit(2)
                    .truncationMode(.tail)

                HStack(spacing: 4) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                    }
                    Text(formatTimestamp(item.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .contextMenu {
            Button {
                onPin()
            } label: {
                if item.isPinned {
                    Label("Unpin", systemImage: "pin.slash")
                } else {
                    Label("Pin to Top", systemImage: "pin")
                }
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Thumbnail

    private var thumbnailView: some View {
        Group {
            if item.type == "image", let data = item.imageData,
               let nsImage = NSImage(data: data)
            {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.08))
                        .frame(width: 72, height: 72)
                    Image(systemName: "doc.text")
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0.4, green: 0.65, blue: 0.9))
                }
            }
        }
    }

    // MARK: - Helpers

    private var previewText: String {
        let text = item.textContent ?? ""
        let single = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        return String(single.prefix(200))
    }

    private func formatTimestamp(_ date: Date) -> String {
        let diff = Calendar.current.dateComponents(
            [.minute, .hour, .day], from: date, to: Date()
        )

        if let d = diff.day, d > 0 {
            if d == 1 { return "Yesterday" }
            if d < 7 { return "\(d)d ago" }
            let fmt = DateFormatter(); fmt.dateFormat = "MM/dd/yy"
            return fmt.string(from: date)
        }
        if let h = diff.hour, h > 0 { return "\(h)h ago" }
        if let m = diff.minute, m > 0 { return "\(m)m ago" }
        return "Just now"
    }
}
