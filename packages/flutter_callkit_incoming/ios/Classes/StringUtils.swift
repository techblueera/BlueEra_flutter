//
//  StringUtils.swift
//  flutter_callkit_incoming
//
//  Created by Hien Nguyen on 21/02/2022.
//

import Foundation
import CryptoSwift

extension String {
    
    func encrypt(encryptionKey: String = "xrBixqjjMhHifSDgSJ8O4QJYMZ1UHs45", iv: String = "lmYSgP3vixDAiBzW") -> String {
        if let aes = try? AES(key: encryptionKey, iv: iv),
           let encrypted = try? aes.encrypt(Array<UInt8>(self.utf8)) {
            return encrypted.toHexString()
        }
        return ""
    }
    
    func decrypt(encryptionKey: String = "xrBixqjjMhHifSDgSJ8O4QJYMZ1UHs45", iv: String = "lmYSgP3vixDAiBzW") -> String {
        if let aes = try? AES(key: encryptionKey, iv: iv),
           let decrypted = try? aes.decrypt(Array<UInt8>(hex: self)) {
            return String(data: Foundation.Data(decrypted), encoding: .utf8) ?? ""
        }
        return ""
    }
    
    func fromBase64() -> String {
        guard let data = Foundation.Data(base64Encoded: self) else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func toBase64() -> String {
        return Foundation.Data(self.utf8).base64EncodedString()
    }
    
    
    public func encryptHandle(encryptionKey: String = "xrBixqjjMhHifSDgSJ8O4QJYMZ1UHs45", iv: String = "lmYSgP3vixDAiBzW") -> String {
        return self.encrypt().toBase64()
    }
    
    public func decryptHandle(encryptionKey: String = "xrBixqjjMhHifSDgSJ8O4QJYMZ1UHs45", iv: String = "lmYSgP3vixDAiBzW") -> String {
        return self.fromBase64().decrypt()
    }
    
    public func getDecryptHandle() -> [String: Any] {
        if (!self.isBase64Encoded()) {
            var map: [String: Any] = [:]
            map["handle"] = self
            return map
        }
        if let data = self.decryptHandle().data(using: .utf8) {
            do {
                return try (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!
            } catch {
                print(error.localizedDescription)
            }
        }
        return [:]
    }
    
    public func getHandleType() -> String {
        if (!self.isBase64Encoded()) {
            if (!self.isPhoneNumber()) {
                return "email"
            } else {
                return "number"
            }
        }
        return "generic"
    }
    
    public func isBase64Encoded() -> Bool {
        let value = self.fromBase64()
        return !value.isEmpty
    }
    
    func isPhoneNumber() -> Bool {
        let cleanedValue = self
            .replacingOccurrences(of: "[+-]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[ ]", with: "", options: .regularExpression)
            
    
        let decimalCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: cleanedValue)
        return decimalCharacters.isSuperset(of: characterSet)
    }

    /// CallKit requires a valid RFC-4122 UUID per call, but the app keys calls
    /// by the backend `call_id` — a MongoDB ObjectId (24-char hex), NOT a UUID.
    /// `UUID(uuidString:)` returns nil for it; the plugin force-unwrapped that and
    /// CRASHED inside the PushKit handler → no CallKit ring + iOS throttling.
    /// This maps any id deterministically: a valid UUID is returned unchanged;
    /// anything else is hashed (MD5 → 128 bits) into a stable v3 UUID, so the same
    /// call_id always yields the same CallKit UUID across show / accept / end.
    public var callkitUUIDString: String {
        if UUID(uuidString: self) != nil { return self }
        var bytes = Array(self.utf8).md5() // CryptoSwift → 16 bytes
        bytes[6] = (bytes[6] & 0x0F) | 0x30 // version 3 (name-based, MD5)
        bytes[8] = (bytes[8] & 0x3F) | 0x80 // RFC-4122 variant
        let hex = bytes.map { String(format: "%02hhx", $0) }.joined()
        func part(_ a: Int, _ b: Int) -> String {
            let lo = hex.index(hex.startIndex, offsetBy: a)
            let hi = hex.index(hex.startIndex, offsetBy: b)
            return String(hex[lo..<hi])
        }
        return "\(part(0,8))-\(part(8,12))-\(part(12,16))-\(part(16,20))-\(part(20,32))"
    }

    /// Deterministic UUID form of `callkitUUIDString`.
    public var callkitUUID: UUID {
        return UUID(uuidString: self.callkitUUIDString) ?? UUID()
    }

}
