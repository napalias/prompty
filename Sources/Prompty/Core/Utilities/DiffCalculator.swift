// DiffCalculator.swift
// Prompty
//
// Myers word-level diff algorithm (19R).
// Compares original and revised text at word granularity,
// producing an array of equal/insert/delete operations.

import Foundation

struct DiffCalculator: Sendable {

    // MARK: - Public Types

    /// A single diff operation: equal, insert, or delete.
    enum Change: Equatable, Sendable {
        case equal(String)
        case insert(String)
        case delete(String)
    }

    // MARK: - Public API

    /// Returns word-level Myers diff between two strings.
    static func diff(original: String, revised: String) -> [Change] {
        let origTokens = tokenize(original)
        let revTokens = tokenize(revised)
        return myersDiff(origTokens, revTokens)
    }

    // MARK: - Tokenization

    /// Splits text on whitespace boundaries, preserving whitespace as tokens.
    /// "Hello, world!" -> ["Hello,", " ", "world!"]
    static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        for char in text {
            if char.isWhitespace {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                tokens.append(String(char))
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    // MARK: - Myers Diff

    /// Standard Myers O(ND) algorithm.
    /// Reference: Myers 1986 "An O(ND) Difference Algorithm and Its Variations"
    private static func myersDiff(
        _ oldTokens: [String],
        _ newTokens: [String]
    ) -> [Change] {
        let oldCount = oldTokens.count
        let newCount = newTokens.count
        let maxD = oldCount + newCount

        guard maxD > 0 else { return [] }

        // V array indexed by k in -maxD..maxD; offset by maxD for array access
        let size = 2 * maxD + 1
        var trace: [[Int]] = []
        var currentV = Array(repeating: 0, count: size)

        outer: for dd in 0...maxD {
            trace.append(currentV)
            var nextV = currentV
            for kk in stride(from: -dd, through: dd, by: 2) {
                let kIndex = kk + maxD

                var xx: Int
                if kk == -dd || (kk != dd && currentV[kIndex - 1] < currentV[kIndex + 1]) {
                    xx = currentV[kIndex + 1]
                } else {
                    xx = currentV[kIndex - 1] + 1
                }
                var yy = xx - kk

                // Follow diagonal (equal tokens)
                while xx < oldCount && yy < newCount
                    && oldTokens[xx] == newTokens[yy] {
                    xx += 1
                    yy += 1
                }

                nextV[kIndex] = xx

                if xx >= oldCount && yy >= newCount {
                    trace.append(nextV)
                    return backtrack(trace: trace, oldTokens: oldTokens, newTokens: newTokens)
                }
            }
            currentV = nextV
        }

        return backtrack(trace: trace, oldTokens: oldTokens, newTokens: newTokens)
    }

    /// Backtracks through the trace to reconstruct the edit script.
    private static func backtrack(
        trace: [[Int]],
        oldTokens: [String],
        newTokens: [String]
    ) -> [Change] {
        var xx = oldTokens.count
        var yy = newTokens.count
        var changes: [Change] = []
        let maxD = oldTokens.count + newTokens.count

        for dd in stride(from: trace.count - 2, through: 0, by: -1) {
            let vv = trace[dd]
            let kk = xx - yy
            let kIndex = kk + maxD

            var prevK: Int
            if kk == -dd || (kk != dd && vv[kIndex - 1] < vv[kIndex + 1]) {
                prevK = kk + 1
            } else {
                prevK = kk - 1
            }

            let prevX = vv[prevK + maxD]
            let prevY = prevX - prevK

            // Diagonal moves (equal tokens)
            while xx > prevX && yy > prevY {
                xx -= 1
                yy -= 1
                changes.append(.equal(oldTokens[xx]))
            }

            if dd > 0 {
                if xx == prevX {
                    // Insert
                    yy -= 1
                    changes.append(.insert(newTokens[yy]))
                } else {
                    // Delete
                    xx -= 1
                    changes.append(.delete(oldTokens[xx]))
                }
            }
        }

        return changes.reversed()
    }
}
