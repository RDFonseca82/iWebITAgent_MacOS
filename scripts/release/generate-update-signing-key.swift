import CryptoKit
import Foundation

let privateKey = Curve25519.Signing.PrivateKey()
let privateValue = privateKey.rawRepresentation.base64EncodedString()
let publicValue = privateKey.publicKey.rawRepresentation.base64EncodedString()

FileHandle.standardError.write(Data("""
Store the private value only in the protected GitHub Environment and an encrypted offline backup.
Do not commit either generated value to the repository.

""".utf8))

print("IWEBIT_UPDATE_PRIVATE_KEY_BASE64=\(privateValue)")
print("IWEBIT_UPDATE_PUBLIC_KEY_BASE64=\(publicValue)")
