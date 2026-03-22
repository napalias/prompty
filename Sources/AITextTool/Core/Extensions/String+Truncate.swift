// String+Truncate.swift
// AITextTool

import Foundation

extension String {
    /// Truncates the string to the given length, appending an ellipsis if truncated.
    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength)) + "..."
    }
}
