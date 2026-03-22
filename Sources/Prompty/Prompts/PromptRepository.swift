// PromptRepository.swift
// Prompty
//
// JSON file-based prompt persistence in Application Support/Prompty/prompts.json.
// Loads built-in prompts on first launch. Handles copy-on-edit for built-ins (21A).
// Atomic writes (20G). Template injection prevention (20H).

import Foundation
import os

/// Protocol abstracting file system operations for testability.
protocol FileManagerProtocol: Sendable {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool
    ) throws
    func contentsOfFile(at url: URL) throws -> Data
    func writeAtomically(data: Data, to url: URL) throws
}

/// Default file manager implementation using Foundation.
struct RealFileManager: FileManagerProtocol {
    func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool
    ) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: createIntermediates
        )
    }

    func contentsOfFile(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func writeAtomically(data: Data, to url: URL) throws {
        // Atomic write: write to temp file, then rename (20G).
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString).tmp")
        try data.write(to: tempURL, options: .atomic)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
    }
}

/// JSON file-based prompt repository.
/// Thread-safe via NSLock for concurrent access.
final class PromptRepository: PromptRepositoryProtocol, @unchecked Sendable {
    private let fileManager: FileManagerProtocol
    private let storageURL: URL
    private var prompts: [Prompt]
    private let lock = NSLock()

    init(
        fileManager: FileManagerProtocol = RealFileManager(),
        storageDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager

        let directory: URL
        if let provided = storageDirectoryURL {
            directory = provided
        } else {
            // swiftlint:disable:next force_unwrapping
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            directory = appSupport.appendingPathComponent("Prompty")
        }

        self.storageURL = directory.appendingPathComponent("prompts.json")
        self.prompts = []

        // Ensure directory exists.
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }

        // Load from disk or seed with built-ins.
        self.prompts = loadFromDisk()
    }

    // MARK: - PromptRepositoryProtocol

    func all() -> [Prompt] {
        lock.lock()
        defer { lock.unlock() }
        return prompts
            .filter { !$0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func allIncludingHidden() -> [Prompt] {
        lock.lock()
        defer { lock.unlock() }
        return prompts.sorted { $0.sortOrder < $1.sortOrder }
    }

    func get(id: UUID) -> Prompt? {
        lock.lock()
        defer { lock.unlock() }
        return prompts.first { $0.id == id }
    }

    func save(_ prompt: Prompt) throws {
        lock.lock()
        defer { lock.unlock() }

        var sanitized = prompt
        sanitized.template = Self.sanitizeTemplate(prompt.template)
        sanitized.modifiedAt = Date()

        if let index = prompts.firstIndex(where: { $0.id == sanitized.id }) {
            // Update existing prompt.
            prompts[index] = sanitized
        } else {
            // Insert new prompt.
            prompts.append(sanitized)
        }
        try persist()
    }

    func delete(id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let index = prompts.firstIndex(where: { $0.id == id }) else {
            throw PromptRepositoryError.promptNotFound(id: id)
        }
        if prompts[index].isBuiltIn {
            throw PromptRepositoryError.cannotDeleteBuiltIn
        }
        prompts.remove(at: index)
        try persist()
    }

    func hide(id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let index = prompts.firstIndex(where: { $0.id == id }) else {
            throw PromptRepositoryError.promptNotFound(id: id)
        }
        prompts[index].isHidden = true
        prompts[index].modifiedAt = Date()
        try persist()
    }

    func unhide(id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let index = prompts.firstIndex(where: { $0.id == id }) else {
            throw PromptRepositoryError.promptNotFound(id: id)
        }
        prompts[index].isHidden = false
        prompts[index].modifiedAt = Date()
        try persist()
    }

    func reorder(ids: [UUID]) throws {
        lock.lock()
        defer { lock.unlock() }

        for (order, promptID) in ids.enumerated() {
            if let index = prompts.firstIndex(where: { $0.id == promptID }) {
                prompts[index].sortOrder = order
                prompts[index].modifiedAt = Date()
            }
        }
        try persist()
    }

    func search(query: String) -> [Prompt] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all() }
        return all().filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func recentlyUsed(limit: Int) -> [Prompt] {
        lock.lock()
        defer { lock.unlock() }
        return prompts
            .filter { !$0.isHidden && $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Private Helpers

    private func loadFromDisk() -> [Prompt] {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            // First launch: seed with built-in prompts and persist.
            let builtIns = BuiltInPrompts.all
            self.prompts = builtIns
            try? persist()
            return builtIns
        }

        do {
            let data = try fileManager.contentsOfFile(at: storageURL)
            let decoded = try JSONDecoder().decode([Prompt].self, from: data)
            return decoded
        } catch {
            // JSON decode resilience (21F): log error, return built-ins.
            Logger.settings.error(
                "Failed to decode prompts.json: \(error.localizedDescription). Using built-in defaults."
            )
            return BuiltInPrompts.all
        }
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(prompts)
        try fileManager.writeAtomically(data: data, to: storageURL)
    }

    /// Sanitizes template to prevent injection (20H).
    /// Strips null bytes and control characters except newlines and tabs.
    static func sanitizeTemplate(_ template: String) -> String {
        var result = ""
        result.reserveCapacity(min(template.count, 2000))
        for char in template {
            if char == "\n" || char == "\t" || char == "\r" {
                result.append(char)
            } else if let ascii = char.asciiValue {
                if ascii >= 32 {
                    result.append(char)
                } else {
                    result.append(" ")
                }
            } else {
                // Non-ASCII Unicode characters are fine.
                result.append(char)
            }
            if result.count >= 2000 {
                break
            }
        }
        return result
    }
}

/// Errors specific to prompt repository operations.
enum PromptRepositoryError: LocalizedError, Equatable {
    case cannotDeleteBuiltIn
    case promptNotFound(id: UUID)

    var errorDescription: String? {
        switch self {
        case .cannotDeleteBuiltIn:
            return "Built-in prompts cannot be deleted"
        case .promptNotFound(let id):
            return "Prompt not found: \(id)"
        }
    }
}
