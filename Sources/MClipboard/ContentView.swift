import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var selectedIndex: Int = 0
    @State private var translationStates: [UUID: TranslationState] = [:]
    @State private var translationAvailable: Bool? = nil
    @FocusState private var isListFocused: Bool

    private var window: NSWindow? { NSApp.keyWindow }

    var body: some View {
        // Capture filtered once at body level (observation scoping)
        let filtered = clipboardManager.filteredItems

        VStack(spacing: 0) {
            headerView

            Divider().background(Color.blue.opacity(0.15))

            if filtered.isEmpty {
                emptyStateView
            } else {
                itemListView(items: filtered)
            }

            Divider().background(Color.blue.opacity(0.15))

            footerView
        }
        .frame(minWidth: 320, minHeight: 320)
        .background(Color(red: 0.91, green: 0.95, blue: 0.99))
        .onAppear {
            clipboardManager.loadItems()
            selectedIndex = clipboardManager.filteredItems.isEmpty ? -1 : 0
            if #available(macOS 15.0, *) {
                Task {
                    let status = await Translator.shared.checkAvailability()
                    translationAvailable = (status == .installed)
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard.fill")
                .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.95))
                .font(.system(size: 16))

            Text("MClipboard")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))

            Spacer()

            Text("\(clipboardManager.items.count)/\(ClipboardManager.maxItems)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(Color.blue.opacity(0.1)))

            Button {
                clipboardManager.clearUnpinned()
                selectedIndex = -1
                translationStates.removeAll()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Clear unpinned history")
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    // MARK: - Search Bar

    private var searchBarView: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(red: 0.5, green: 0.7, blue: 0.9))
                .font(.system(size: 12))

            TextField("Search history...", text: $clipboardManager.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onKeyPress(.downArrow) { isListFocused = true; return .handled }
                .onKeyPress(.upArrow)   { isListFocused = true; return .handled }
                .onSubmit { isListFocused = true }

            if !clipboardManager.searchText.isEmpty {
                Button {
                    clipboardManager.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    // MARK: - Item List

    private func itemListView(items: [ClipboardItemEntity]) -> some View {
        VStack(spacing: 0) {
            searchBarView

            ScrollViewReader { proxy in
                List {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let itemId = item.id
                        let state = translationStates[itemId]

                        HistoryRowView(
                            item: item,
                            isSelected: index == selectedIndex,
                            onSelect: {
                                selectedIndex = index
                                clipboardManager.copyItem(item)
                            },
                            onPin: { clipboardManager.togglePin(item) },
                            onDelete: {
                                clipboardManager.deleteItem(item)
                                translationStates.removeValue(forKey: itemId)
                                let count = clipboardManager.filteredItems.count
                                if selectedIndex >= count {
                                    selectedIndex = max(0, count - 1)
                                }
                            },
                            onTranslate: {
                                startTranslation(for: itemId, text: item.textContent ?? "")
                            },
                            translationState: state
                        )
                        .id(index)
                        .listRowBackground(
                            index == selectedIndex
                                ? Color.blue.opacity(0.12)
                                : Color.clear
                        )
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .focusable()
                .focused($isListFocused)
                .onKeyPress(.return)    { handleEnter();    return .handled }
                .onKeyPress(.downArrow) { handleDownArrow(); return .handled }
                .onKeyPress(.upArrow)   { handleUpArrow();  return .handled }
                .onKeyPress(.escape)    { closeWindow();    return .handled }
                .onAppear { isListFocused = true }
                .onChange(of: selectedIndex) { _, new in
                    withAnimation { proxy.scrollTo(new, anchor: .center) }
                }
            }
        }
    }

    // MARK: - Translation

    private func startTranslation(for itemId: UUID, text: String) {
        guard !text.isEmpty else { return }

        Task {
            // Check language availability
            if #available(macOS 15.0, *) {
                if translationAvailable == nil {
                    let status = await Translator.shared.checkAvailability()
                    translationAvailable = (status == .installed)
                }
                guard translationAvailable == true else {
                    translationStates[itemId] = .error(
                        "Language packs not installed. Tap to open System Settings."
                    )
                    return
                }
            }

            translationStates[itemId] = .loading

            do {
                let result = try await Translator.shared.translate(text)
                translationStates[itemId] = .done(result)
            } catch {
                let message = error.localizedDescription
                translationStates[itemId] = .error(
                    message.count > 80 ? "Translation failed" : message
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clipboard")
                .font(.system(size: 40))
                .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.95))

            if clipboardManager.searchText.isEmpty {
                Text("No clipboard history yet")
                    .font(.system(size: 13)).foregroundColor(.secondary)
                Text("Copy something and it will appear here")
                    .font(.system(size: 11)).foregroundColor(.secondary.opacity(0.7))
            } else {
                Text("No results for \"\(clipboardManager.searchText)\"")
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "pin.fill")
                .font(.system(size: 9)).foregroundColor(.orange.opacity(0.6))
            Text("\(clipboardManager.pinnedItems.count) pinned")
                .font(.system(size: 10)).foregroundColor(.secondary)
            Spacer()
            Text("⌘⇧V to toggle")
                .font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
    }

    // MARK: - Keyboard

    private func handleEnter() {
        let filtered = clipboardManager.filteredItems
        guard selectedIndex >= 0, selectedIndex < filtered.count else { return }
        clipboardManager.copyItem(filtered[selectedIndex])
    }

    private func handleDownArrow() {
        let count = clipboardManager.filteredItems.count
        guard count > 0, selectedIndex < count - 1 else { return }
        selectedIndex += 1
    }

    private func handleUpArrow() {
        guard selectedIndex > 0 else { return }
        selectedIndex -= 1
    }

    private func closeWindow() {
        window?.close()
    }
}