import Foundation

public struct APIEnvironment: Equatable, Sendable {
    public let baseURL: URL

    public init(baseURL: URL, allowInsecureLocalhostForTests: Bool = false) throws {
        let scheme = baseURL.scheme?.lowercased()
        let isTestLocalhost = allowInsecureLocalhostForTests &&
            scheme == "http" &&
            ["localhost", "127.0.0.1", "::1"].contains(baseURL.host ?? "")
        guard scheme == "https" || isTestLocalhost else {
            throw CoreError.insecureTransport
        }
        self.baseURL = baseURL
    }
}

public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public final class URLSessionTransport: HTTPTransport, @unchecked Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: CoreError.invalidResponse)
                    return
                }
                continuation.resume(returning: (data, httpResponse))
            }.resume()
        }
    }
}

public struct SecureAPIClient: @unchecked Sendable {
    private let environment: APIEnvironment
    private let authenticator: RequestAuthenticator
    private let transport: any HTTPTransport
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        environment: APIEnvironment,
        authenticator: RequestAuthenticator,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.environment = environment
        self.authenticator = authenticator
        self.transport = transport

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func get<Response: Decodable & Sendable>(
        _ path: String,
        query: [URLQueryItem] = [],
        as type: Response.Type = Response.self
    ) async throws -> Response {
        try await send(path: path, method: "GET", query: query, body: nil, as: type)
    }

    public func post<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        body: Body,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        try await send(path: path, method: "POST", query: [], body: encoder.encode(body), as: type)
    }

    public func postWithoutResponse<Body: Encodable & Sendable>(_ path: String, body: Body) async throws {
        let _: EmptyResponse = try await post(path, body: body, as: EmptyResponse.self)
    }

    private func send<Response: Decodable & Sendable>(
        path: String,
        method: String,
        query: [URLQueryItem],
        body: Data?,
        as type: Response.Type
    ) async throws -> Response {
        guard var components = URLComponents(
            url: environment.baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))),
            resolvingAgainstBaseURL: false
        ) else {
            throw CoreError.invalidURL
        }
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else {
            throw CoreError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        request = try authenticator.authenticate(request)

        let (data, response) = try await transport.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 || response.statusCode == 403 {
                throw CoreError.unauthorized
            }
            throw CoreError.server(statusCode: response.statusCode)
        }
        if Response.self == EmptyResponse.self && data.isEmpty {
            guard let response = EmptyResponse() as? Response else {
                throw CoreError.invalidResponse
            }
            return response
        }
        return try decoder.decode(Response.self, from: data)
    }
}

public struct EmptyResponse: Codable, Sendable {
    public init() {}
}
