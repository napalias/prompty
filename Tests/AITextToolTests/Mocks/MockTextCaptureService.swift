// MockTextCaptureService.swift
// AITextToolTests

@testable import AITextTool

final class MockTextCaptureService: TextCaptureServiceProtocol {
    var mockText: String?
    var mockError: AppError?
    var isAccessibilityGranted: Bool = true

    func capture() async throws -> String {
        if let error = mockError { throw error }
        return mockText ?? ""
    }
}
