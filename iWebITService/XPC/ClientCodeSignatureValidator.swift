import Foundation
import Security

struct ClientCodeSignatureValidator {
    let teamID: String
    let bundleIdentifiers: [String]

    var requirement: String {
        let identifiers = bundleIdentifiers
            .map { "identifier \"\($0)\"" }
            .joined(separator: " or ")
        return "anchor apple generic and certificate leaf[subject.OU] = \"\(teamID)\" and (\(identifiers))"
    }

    func prepare(_ connection: NSXPCConnection) -> Bool {
        if #available(macOS 13.0, *) {
            connection.setCodeSigningRequirement(requirement)
            return true
        }
        return validateLegacyPeer(connection)
    }

    private func validateLegacyPeer(_ connection: NSXPCConnection) -> Bool {
        let attributes = [
            kSecGuestAttributePid as String: NSNumber(value: connection.processIdentifier)
        ] as CFDictionary
        var guestCode: SecCode?
        guard SecCodeCopyGuestWithAttributes(nil, attributes, [], &guestCode) == errSecSuccess,
              let guestCode else {
            return false
        }

        var requirementObject: SecRequirement?
        guard SecRequirementCreateWithString(
            requirement as CFString,
            [],
            &requirementObject
        ) == errSecSuccess, let requirementObject else {
            return false
        }
        return SecCodeCheckValidity(guestCode, [], requirementObject) == errSecSuccess
    }
}
