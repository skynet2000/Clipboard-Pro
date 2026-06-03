import AppKit
import Foundation
import Translation

// MARK: - Translation Result

struct TranslationResult: Sendable {
    let sourceText: String
    let translatedText: String
    let direction: TranslationDirection

    enum TranslationDirection: String, Sendable {
        case chineseToEnglish = "中 → 英"
        case englishToChinese = "英 → 中"
    }
}

// MARK: - Translation State

enum TranslationState: Sendable {
    case loading
    case done(TranslationResult)
    case error(String)
}

// MARK: - Translator Service

@MainActor
final class Translator {
    static let shared = Translator()

    private init() {}

    /// Open System Settings → Translation Languages to download packs.
    static func openLanguageSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension")!
        NSWorkspace.shared.open(url)
    }

    /// Auto-detect language and translate between Chinese and English.
    /// Relies on TranslationSession to detect missing packs at call time — no LanguageAvailability pre-check.
    func translate(_ text: String) async throws -> TranslationResult {
        guard #available(macOS 26.0, *) else {
            throw TranslatorError.unsupportedOS
        }

#if compiler(>=6.2)
        let source: Locale.Language
        let target: Locale.Language
        let direction: TranslationResult.TranslationDirection

        if isPrimarilyChinese(text) {
            source = Locale.Language(identifier: "zh-Hans")
            target = Locale.Language(identifier: "en")
            direction = .chineseToEnglish
        } else {
            source = Locale.Language(identifier: "en")
            target = Locale.Language(identifier: "zh-Hans")
            direction = .englishToChinese
        }

        let session = TranslationSession(installedSource: source, target: target)

        do {
            let response = try await session.translate(text)
            return TranslationResult(
                sourceText: text,
                translatedText: response.targetText,
                direction: direction
            )
        } catch let error as TranslationError {
            // Only TranslationError.notInstalled means packs missing
            switch error {
            case .notInstalled:
                throw TranslatorError.languageNotInstalled
            default:
                throw error
            }
        } catch {
            throw error
        }
#else
        // CI fallback: macOS 15 SDK lacks TranslationSession macOS-26.0 symbols
        throw TranslatorError.unsupportedOS
#endif
    }

    // MARK: - Language Detection

    private func isPrimarilyChinese(_ text: String) -> Bool {
        let scalars = Array(text.unicodeScalars)
        guard !scalars.isEmpty else { return false }

        let cjkCount = scalars.filter { isCJKScalar($0) }.count
        return Double(cjkCount) / Double(scalars.count) > 0.3
    }

    private func isCJKScalar(_ scalar: Unicode.Scalar) -> Bool {
        let v = scalar.value
        return (0x4E00...0x9FFF).contains(v)   // CJK Unified
            || (0x3400...0x4DBF).contains(v)   // CJK Extension A
            || (0xF900...0xFAFF).contains(v)   // CJK Compatibility
            || (0x3040...0x309F).contains(v)   // Hiragana
            || (0x30A0...0x30FF).contains(v)   // Katakana
    }
}

// MARK: - Errors

enum TranslatorError: LocalizedError {
    case unsupportedOS
    case languageNotInstalled

    var errorDescription: String? {
        switch self {
        case .unsupportedOS:
            "Translation requires macOS 26 or newer"
        case .languageNotInstalled:
            "Language packs not installed"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unsupportedOS:
            "Update macOS to use built-in translation"
        case .languageNotInstalled:
            "Download Chinese & English packs in System Settings → Translation Languages"
        }
    }
}