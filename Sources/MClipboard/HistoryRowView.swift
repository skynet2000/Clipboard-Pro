import SwiftUI

struct HistoryRowView: View {
    @ObservedObject var item: ClipboardItemEntity

    let isSelected: Bool
    let onSelect: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onTranslate: () -> Void
    let translationState: TranslationState?

    var body: some View {
        // Capture values once at body level — avoid N registrations in ForEach
        let pinned = item.isPinned
        let ts = safeTimestamp
        let isText = item.type == "text"
        let hasTranslation: Bool = {
            if case .done = translationState { return true }
            return false
        }()
        let isLoading: Bool = {
            if case .loading = translationState { return true }
            return false
        }()

        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 10) {
                thumbnailView

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.type == "image" ? "🖼 Image" : previewText)
                        .font(.system(size: 12.5))
                        .foregroundColor(
                            pinned
                                ? Color(red: 0.15, green: 0.25, blue: 0.45)
                                : .primary
                        )
                        .lineLimit(2)
                        .truncationMode(.tail)

                    HStack(spacing: 4) {
                        if pinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                        }
                        if let ts {
                            Text(formatTimestamp(ts))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture { onSelect() }
            .contextMenu {
                if isText {
                    Button { onTranslate() } label: {
                        if isLoading {
                            Label("Translating...", systemImage: "hourglass")
                        } else if hasTranslation {
                            Label("Retranslate", systemImage: "arrow.triangle.2.circlepath")
                        } else {
                            Label("Translate", systemImage: "globe")
                        }
                    }
                    .disabled(isLoading)
                    Divider()
                }
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

            // Inline translation block
            if let state = translationState {
                translationBlock(state)
            }
        }
    }

    // MARK: - Translation Block

    @ViewBuilder
    private func translationBlock(_ state: TranslationState) -> some View {
        Divider()
            .padding(.horizontal, 14)

        HStack(alignment: .top, spacing: 0) {
            // Left accent bar
            Rectangle()
                .fill(Color.blue.opacity(0.35))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                switch state {
                case .loading:
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.55)
                            .frame(width: 12, height: 12)
                        Text("Translating...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                case .done(let result):
                    HStack(spacing: 4) {
                        Text(result.translatedText)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .lineLimit(8)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button {
                            copyTranslation(result.translatedText)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Copy translation")
                    }
                    Text(result.direction.rawValue + " · Apple Translation")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.7))

                case .error(let message):
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text(message)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        if message.contains("Language packs") {
                            Button("Open System Settings →") {
                                Translator.openLanguageSettings()
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 8)
        }
        .background(Color.blue.opacity(0.04))
    }

    private func copyTranslation(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
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

    private var safeTimestamp: Date? {
        guard !item.isDeleted, item.managedObjectContext != nil else { return nil }
        return item.timestamp
    }

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