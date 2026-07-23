import XCTest
@testable import iWebITCore

/// Read-only live tests. They are skipped unless dedicated test-device
/// environment variables are present. Never point these at a real employee
/// device or a production company credential.
final class LiveBackendContractTests: XCTestCase {
    private var environment: [String: String] { ProcessInfo.processInfo.environment }

    func testLiveCompanyResponseStillMatchesLegacyContract() async throws {
        let scriptURL = try requiredHTTPSURL("IWEBIT_CONTRACT_SCRIPT_API_URL")
        let idSync = try requiredValue("IWEBIT_CONTRACT_TEST_IDSYNC")
        let data = try await get(scriptURL, query: [URLQueryItem(name: "IdSync", value: idSync)])
        _ = try JSONDecoder().decode(LegacyCompanyResponse.self, from: data)
    }

    func testLiveDeviceResponseStillMatchesLegacyContract() async throws {
        let scriptURL = try requiredHTTPSURL("IWEBIT_CONTRACT_SCRIPT_API_URL")
        let uniqueID = try requiredValue("IWEBIT_CONTRACT_TEST_UNIQUE_ID")
        let data = try await get(scriptURL, query: [URLQueryItem(name: "UniqueID", value: uniqueID)])
        _ = try JSONDecoder().decode(LegacyDeviceResponse.self, from: data)
    }

    func testLiveSupportResponseCanBeNormalized() async throws {
        let scriptURL = try requiredHTTPSURL("IWEBIT_CONTRACT_SCRIPT_API_URL")
        let uniqueID = try requiredValue("IWEBIT_CONTRACT_TEST_UNIQUE_ID")
        let data = try await get(
            scriptURL,
            query: [
                URLQueryItem(name: "Support", value: "1"),
                URLQueryItem(name: "UniqueID", value: uniqueID)
            ]
        )
        let normalized = try LegacyResponseNormalizer.supportArrayData(from: data)
        _ = try JSONDecoder().decode([LegacySupportResponse].self, from: normalized)
    }

    private func requiredHTTPSURL(_ name: String) throws -> URL {
        let value = try requiredValue(name)
        guard let url = URL(string: value), url.scheme?.lowercased() == "https" else {
            throw XCTSkip("\(name) must be an HTTPS URL")
        }
        return url
    }

    private func requiredValue(_ name: String) throws -> String {
        guard let value = environment[name], !value.isEmpty else {
            throw XCTSkip("\(name) is not configured")
        }
        return value
    }

    private func get(_ url: URL, query: [URLQueryItem]) async throws -> Data {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = query
        guard let requestURL = components?.url else {
            throw CoreError.invalidURL
        }
        var request = URLRequest(url: requestURL)
        request.timeoutInterval = 15
        let (data, response) = try await URLSessionTransport().data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw CoreError.invalidResponse
        }
        return data
    }
}
