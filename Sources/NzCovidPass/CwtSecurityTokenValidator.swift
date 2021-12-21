//
// Copyright Gallagher Group Ltd 2021
//
import Foundation
import CommonCrypto

public enum CwtSecurityTokenValidationError : Error {
    /// The key Id field is missing from the header
    case invalidKeyId
    
    /// The algorithm isn't in our approved list
    case unsupportedAlgorithm
    
    /// The JTI field is missing from the payload
    case invalidTokenId
    
    /// The issuer isn't in our approved list
    case invalidIssuer
    
    /// The "notBefore" time is after the "expiry" which indicates a malformed pass
    case invalidDateRange
    
    /// The "notBefore" time hasn't arrived yet.
    case notYetValid
    
    /// The "expiry" time is in the past.
    case expired
    
    /// The token does not contain a verifiable credential
    case missingCredential
    
    /// The credential's context is not in the approved list
    case invalidCredentialContext
    
    /// The credential's type is not in the approved list
    case invalidCredentialType
    
    /// The issuer JWK was not of a type that we know how to verify
    case unsupportedVerificationKeyType
    
    /// The issuer JWK key x and y values were missing or malformed
    case invalidKeyParameters
    
    /// The signature was not verifiable; either the data has been tampered with or it was signed with a different key
    case invalidSignature
}

class CwtSecurityTokenValidator {
    let options: PassVerifierOptions
    
    init(options: PassVerifierOptions) {
        self.options = options
    }
    
    // throws if the token isn't valid. Returns if it is
    func validateToken(_ token: CwtSecurityToken, referenceTime: Date? = nil) throws {
        // validate the header
        guard let keyId = token.header.keyId, !keyId.isEmpty else {
            throw CwtSecurityTokenValidationError.invalidKeyId
        }
        guard let alg = token.header.algorithm, options.validAlgorithms.contains(alg) else {
            throw CwtSecurityTokenValidationError.unsupportedAlgorithm
        }
        
        // validate the payload
        guard let jti = token.payload.jti, !jti.isEmpty else {
            throw CwtSecurityTokenValidationError.invalidTokenId
        }
        guard let issuer = token.payload.issuer, options.validIssuers.contains(issuer) else {
            throw CwtSecurityTokenValidationError.invalidIssuer
        }
        let nbf = token.payload.notBefore ?? Date.distantPast
        let exp = token.payload.expiry ?? Date.distantFuture
        
        if nbf > exp {
            throw CwtSecurityTokenValidationError.invalidDateRange
        }
        let now = referenceTime ?? Date() // swift Dates don't carry timezone, they just represent a fixed interval since the epoch, so we can just compare them.
                
        if nbf > now {
            throw CwtSecurityTokenValidationError.notYetValid
        }
        if exp < now {
            throw CwtSecurityTokenValidationError.expired
        }
        
        // validate the signature
        try validateSignature(token: token, algorithm: alg)
        
        // validate the credential
        guard let cred = token.payload.credential else {
            throw CwtSecurityTokenValidationError.missingCredential
        }
        if !cred.context.contains(VerifiableCredential.baseContext) ||
            !cred.context.contains(cred.credentialSubject.context) {
            throw CwtSecurityTokenValidationError.invalidCredentialContext
        }
        
        if !cred.type.contains(VerifiableCredential.baseCredentialType) ||
            !cred.type.contains(cred.credentialSubject.type) {
            throw CwtSecurityTokenValidationError.invalidCredentialType
        }
    }
    
    func validateSignature(token: CwtSecurityToken, algorithm: String) throws {
        // future extension: fetch the DID from the internet and cache it rather than hardcoding
        // Note: before we get here we have already checked the token issuer against
        // options.validIssuers, so it isn't a security problem if "WellKnownIssuers" contains test keys
        let issuer = token.payload.issuer ?? ""
        let keyId = token.header.keyId ?? ""
        guard let did = try WellKnownIssuers.find(issuer: issuer, keyId: keyId) else {
            throw CwtSecurityTokenValidationError.invalidIssuer
        }
        
        guard let verificationMethod = did.verificationMethods.first(where: { vf in
            vf.id == "\(issuer)#\(keyId)" && vf.publicKeyJwk.crv == "P-256" && vf.publicKeyJwk.kty == "EC"
        }) else {
            throw CwtSecurityTokenValidationError.unsupportedVerificationKeyType
        }

        let jwk = verificationMethod.publicKeyJwk
        guard let xStr = jwk.x, let yStr = jwk.y, let x = Data(base64urlEncoded: xStr), let y = Data(base64urlEncoded: yStr) else {
            throw CwtSecurityTokenValidationError.invalidKeyParameters
        }
        
        // EC public key on iOS is header byte + x + y
        var keyData = Data([0x04])
        keyData.append(contentsOf: x)
        keyData.append(contentsOf: y)
        let publicKey: SecKey
        do {
            publicKey = try parsePublicKeyBytes(data: keyData)
        } catch /*let err*/ {
            // TODO possibly log the underlying CommonCrypto error
            throw CwtSecurityTokenValidationError.invalidKeyParameters
        }
        
        // the signature is generated not directly over the input, but over this derived structure
        // https://datatracker.ietf.org/doc/html/rfc8152#section-4.4
        // Note this process assumes a COSE_Sign1 structure, which NZ Covid passes should be.
        var cborWriter = CborWriter()
        
        try cborWriter.write(CborValue(array: [
            // context
            .textString("Signature1"),
            
            // body_protected
            .byteString(token.header.data),
            
            // external_aad
            .byteString(Data()),
            
            // payload
            .byteString(token.payload.data)
        ]))
                
        
        if !verifyECDSASignature(rawSignatureBuffer: token.signature, dataBuffer: cborWriter.buffer, publicKey: publicKey) {
            throw CwtSecurityTokenValidationError.invalidSignature
        }
    }
    
    func verifyECDSASignature(rawSignatureBuffer: Data, dataBuffer: Data, publicKey: SecKey) -> Bool {
        let hashBuffer = sha256(data: dataBuffer)
        
        // iOS wants EC signatures in ASN1 encoded format, not raw.
        let asnSignatureBuffer = convertRawSignatureIntoAsn1(rawSignatureBuffer)
        
        let status = hashBuffer.withUnsafeBytes { pHash in
            asnSignatureBuffer.withUnsafeBytes { pSignature in
                SecKeyRawVerify(
                    publicKey,
                    .PKCS1,
                    pHash.bindMemory(to: UInt8.self).baseAddress!,
                    hashBuffer.count,
                    pSignature.bindMemory(to: UInt8.self).baseAddress!,
                    asnSignatureBuffer.count)
            }
        }
        
        return status == errSecSuccess
    }
    
    // we could pull in all of LibAsn but we just need this tiny bit.
    func convertRawSignatureIntoAsn1(_ data: Data, _ digestLengthInBytes: Int = 32) -> Data {
        guard data.count >= digestLengthInBytes else {
            return Data()
        }
        let sigR = encodeIntegerToAsn1(data.prefix(data.count - digestLengthInBytes))
        let sigS = encodeIntegerToAsn1(data.suffix(digestLengthInBytes))
        return Data([0x30, UInt8(sigR.count + sigS.count)]) + sigR + sigS
    }

    private func encodeIntegerToAsn1(_ data: Data) -> Data {
        guard let firstByte = data.first else {
            return Data() // nothing encodes to nothing
        }

        if firstByte & 0x80 == 0x80 { // high bit is set which asn1 interprets as negative, so we need a leading 0 pad
            return Data([0x02, UInt8(data.count + 1), 0x00]) + data
        } else if (firstByte == 0x00) { // has an artificial leading zero, trim it
            return encodeIntegerToAsn1(data.dropFirst())
        } else {
            return Data([0x02, UInt8(data.count)]) + data
        }
    }
    
    func parsePublicKeyBytes(data: Data) throws -> SecKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 256
        ]
        var error : Unmanaged<CFError>?
        
        guard let key : SecKey = SecKeyCreateWithData(data as NSData, attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue()
        }
        
        return key
    }
    
    func sha256(data input: Data) -> Data {
        var sha = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        sha.withUnsafeMutableBytes { shaBuffer in
            input.withUnsafeBytes { buffer in
                _ = CC_SHA256(
                    buffer.baseAddress!,
                    CC_LONG(buffer.count),
                    shaBuffer.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        return sha
    }
}

// ref https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/blob/dev/src/Microsoft.IdentityModel.Tokens/SecurityAlgorithms.cs
struct SecurityAlgorithms {
    static let ecdsaSha256 = "ES256"
    static let sha256 = "SHA256"
    static let sha512 = "SHA512"
}

extension Data {
    init?(base64urlEncoded input: String) {
        var base64 = input
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        self.init(base64Encoded: base64)
    }

    func base64urlEncodedString() -> String {
        var result = self.base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
}
