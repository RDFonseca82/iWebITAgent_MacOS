import Darwin
import Foundation

struct IPAddressSnapshot: Sendable {
    let localAddresses: [String]
    let publicAddress: String?
    let publicLookupError: String?
}

struct IPAddressResolver: Sendable {
    private struct PublicAddressResponse: Decodable {
        let ip: String
    }

    func resolve() async -> IPAddressSnapshot {
        let local = localAddresses()
        do {
            let publicAddress = try await fetchPublicAddress()
            await AgentLogger.shared.log(
                category: "diagnostics",
                action: "public-ip",
                message: "Endereço público consultado com sucesso."
            )
            return IPAddressSnapshot(
                localAddresses: local,
                publicAddress: publicAddress,
                publicLookupError: nil
            )
        } catch {
            await AgentLogger.shared.log(
                .warning,
                category: "diagnostics",
                action: "public-ip",
                message: "Não foi possível consultar o endereço público."
            )
            return IPAddressSnapshot(
                localAddresses: local,
                publicAddress: nil,
                publicLookupError: "Não foi possível consultar o IP público."
            )
        }
    }

    private func fetchPublicAddress() async throws -> String {
        let configured = Bundle.main.object(
            forInfoDictionaryKey: "IWebITPublicIPAddressURL"
        ) as? String
        guard let url = URL(string: configured ?? "https://api64.ipify.org?format=json"),
              url.scheme?.lowercased() == "https" else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let value = try JSONDecoder().decode(PublicAddressResponse.self, from: data).ip
        guard isIPAddress(value) else { throw URLError(.cannotParseResponse) }
        return value
    }

    private func localAddresses() -> [String] {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0, let first = pointer else { return [] }
        defer { freeifaddrs(pointer) }

        var results: [String] = []
        var current: UnsafeMutablePointer<ifaddrs>? = first
        while let interface = current {
            let item = interface.pointee
            current = item.ifa_next
            guard let address = item.ifa_addr else { continue }
            let family = Int32(address.pointee.sa_family)
            guard family == AF_INET || family == AF_INET6 else { continue }

            let flags = Int32(item.ifa_flags)
            guard (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 else { continue }
            let name = String(cString: item.ifa_name)
            guard name == "en0" || name == "en1" || name.hasPrefix("pdp_ip") else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let length: socklen_t = family == AF_INET
                ? socklen_t(MemoryLayout<sockaddr_in>.size)
                : socklen_t(MemoryLayout<sockaddr_in6>.size)
            guard getnameinfo(
                address,
                length,
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            ) == 0 else {
                continue
            }
            let value = String(cString: host).components(separatedBy: "%").first ?? ""
            if isIPAddress(value), !results.contains(value) {
                results.append(value)
            }
        }
        return results
    }

    private func isIPAddress(_ value: String) -> Bool {
        var ipv4 = in_addr()
        var ipv6 = in6_addr()
        return value.withCString {
            inet_pton(AF_INET, $0, &ipv4) == 1 || inet_pton(AF_INET6, $0, &ipv6) == 1
        }
    }
}
