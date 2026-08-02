import XCTest
@testable import iWebITCore

final class LegacyAppleAPIClientTests: XCTestCase {
    func testSnapshotUsesScriptIOSFormContract() async throws {
        let transport = RecordingTransport(data: Data("ok".utf8))
        let client = try makeClient(transport: transport)
        try await client.synchronize(
            snapshot(),
            credentials: LegacyAppleCredentials(
                idSync: "APPLE-REVIEW",
                uniqueID: "device-review",
                idCompany: "42"
            ),
            pushToken: "a1b2c3"
        )

        let recordedRequest = await transport.lastRequest()
        let request = try XCTUnwrap(recordedRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://agent.iwebit.app/scripts/script_ios.php")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded; charset=utf-8"
        )
        let form = try formFields(request)
        let json = try XCTUnwrap(form["json"])
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        )
        XCTAssertEqual(object["IDSync"] as? String, "APPLE-REVIEW")
        XCTAssertEqual(object["UniqueID"] as? String, "device-review")
        XCTAssertEqual(object["IdCompany"] as? String, "42")
        XCTAssertEqual(object["AppleType"] as? Int, 2)
        XCTAssertEqual(object["IdDeviceType"] as? Int, 62)
        XCTAssertEqual(object["AgentVersion"] as? String, "2.0.0")
        XCTAssertEqual(object["AppBuild"] as? String, "204")
        XCTAssertEqual(object["ApplePushToken"] as? String, "a1b2c3")
    }

    func testCompanyLookupUsesLegacyAPIAndReturnsCompanyIdentifier() async throws {
        let response = Data(
            "{\"IDSync\":\"APPLE-REVIEW\",\"IdCompany\":\"42\",\"Company\":\"Example\",\"Active\":1}".utf8
        )
        let transport = RecordingTransport(data: response)
        let client = try makeClient(transport: transport)

        let company = try await client.company(idSync: "APPLE-REVIEW")

        XCTAssertEqual(company.idCompany, "42")
        let recordedRequest = await transport.lastRequest()
        let request = try XCTUnwrap(recordedRequest)
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://agent.iwebit.app/scripts/script_api.php?IdSync=APPLE-REVIEW"
        )
        XCTAssertEqual(request.httpMethod, "GET")
    }
    func testAcceptsLegacyNullBodyAfterCompanyValidation() async throws {
        let transport = RecordingTransport(data: Data("null".utf8))
        let client = try makeClient(transport: transport)
        try await client.synchronize(
            snapshot(),
            credentials: LegacyAppleCredentials(
                idSync: "APPLE-REVIEW",
                uniqueID: "device-review",
                idCompany: "42"
            )
        )
    }

    func testNormalizesLegacySupportAndPostsLegacyFields() async throws {
        let response = Data(
            "{\"Nome\":\"Utilizador\",\"DeviceSupport\":\"Ajuda\",\"DeviceSupportDate\":\"2026-08-02 10:00:00\"}".utf8
        )
        let transport = RecordingTransport(data: response)
        let client = try makeClient(transport: transport)
        let tickets = try await client.tickets(uniqueID: "device-review")
        XCTAssertEqual(tickets.count, 1)
        XCTAssertEqual(tickets[0].latestMessage, "Ajuda")

        _ = try await client.createTicket(
            uniqueID: "device-review",
            name: "Revisor",
            message: "Pedido de teste"
        )
        let requests = await transport.requests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(
            requests[1].url?.absoluteString,
            "https://agent.iwebit.app/scripts/script_api_support.php?UniqueID=device-review"
        )
        let fields = try formFields(requests[1])
        XCTAssertEqual(fields["Nome"], "Revisor")
        XCTAssertEqual(fields["DeviceSupport"], "Pedido de teste")
        XCTAssertNotNil(fields["DeviceSupportDate"])
    }

    private func makeClient(transport: RecordingTransport) throws -> LegacyAppleAPIClient {
        try LegacyAppleAPIClient(
            syncURL: URL(string: "https://agent.iwebit.app/scripts/script_ios.php")!,
            apiURL: URL(string: "https://agent.iwebit.app/scripts/script_api.php")!,
            supportURL: URL(string: "https://agent.iwebit.app/scripts/script_api_support.php")!,
            transport: transport
        )
    }

    private func snapshot() -> DeviceSnapshot {
        DeviceSnapshot(
            snapshotID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            collectedAt: Date(timeIntervalSince1970: 1_700_000_000),
            platform: .iPadOS,
            identity: DeviceIdentity(
                deviceID: "device-review",
                displayName: "iPad de revisão",
                model: "iPad",
                modelIdentifier: "iPad16,5"
            ),
            operatingSystem: OperatingSystemInfo(
                name: "iPadOS",
                version: "26.5",
                locale: "pt_PT",
                timeZone: "Europe/Lisbon"
            ),
            hardware: HardwareInfo(
                architecture: "arm64",
                processorCount: 8,
                activeProcessorCount: 8,
                physicalMemoryBytes: 8_000_000_000
            ),
            storage: StorageInfo(),
            battery: BatteryInfo(level: 0.75, state: "charging", isLowPowerModeEnabled: false),
            network: NetworkInfo(currentTransport: "wifi", isExpensive: false, isConstrained: false),
            security: SecurityInfo(),
            management: ManagementInfo(isManaged: false),
            agent: AgentInfo(
                version: "2.0.0",
                build: "204",
                bundleIdentifier: "app.iwebit.mobile",
                pushTokenAvailable: true
            ),
            location: nil
        )
    }

    private func formFields(_ request: URLRequest) throws -> [String: String] {
        let body = try XCTUnwrap(request.httpBody)
        let value = try XCTUnwrap(String(data: body, encoding: .utf8))
        var components = URLComponents()
        components.percentEncodedQuery = value
        return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map {
            ($0.name, $0.value ?? "")
        })
    }
}

private actor RecordingTransport: HTTPTransport {
    private let responseData: Data
    private var recorded: [URLRequest] = []

    init(data: Data) {
        responseData = data
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        recorded.append(request)
        return (
            responseData,
            HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        )
    }

    func lastRequest() -> URLRequest? {
        recorded.last
    }

    func requests() -> [URLRequest] {
        recorded
    }
}
