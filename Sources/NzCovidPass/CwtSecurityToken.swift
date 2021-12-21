//
// Copyright Gallagher Group Ltd 2021
//
import Foundation

public class CwtSecurityToken {
    public let header: CwtHeader
    public let payload: CwtPayload
    public let signature: Data
    
    init(data: Data) throws {
        var cborReader = CborReader(data: data)
        let outer = try cborReader.read()
        guard case let .tagged(tag: tag, value: inner) = outer, tag == 18 else {
            throw CwtSecurityTokenError.notCoseSingleSignerObject
        }
        guard let coseStructure = inner.asArray(), coseStructure.count == 4 else {
            throw CwtSecurityTokenError.coseSingleSignerObjectInvalidPayload
        }
        
        // pick up actual contents
        guard let headerBytes = coseStructure[0].asData(),
              let payloadBytes = coseStructure[2].asData(),
              let signatureBytes = coseStructure[3].asData() else {
            throw CwtSecurityTokenError.coseSingleSignerObjectInvalidPayload
        }
        
        // A CBOR Map is binary encoded, then written into a byte-string in a CBOR wrapper. COSE and CWT are ridiculous
        var headerReader = CborReader(data: headerBytes)
        let headerMap = try headerReader.readMap()
        
        var payloadReader = CborReader(data: payloadBytes)
        let payloadMap = try payloadReader.readMap()
        
        self.header = .init(claims: headerMap, data: headerBytes) // do we need to carry the raw bytes around?
        self.payload = .init(claims: payloadMap, data: payloadBytes) // do we need to carry the raw bytes around?
        self.signature = signatureBytes
    }
}

public enum CwtSecurityTokenError : Error {
    // the root CBOR structure must be a taggged COSE Single Signer value
    case notCoseSingleSignerObject
    case coseSingleSignerObjectInvalidPayload
}

// wrapper which helps us unpack the CBOR Cwt Header structure
// we don't pre-parse anything though for some reason (copied from .NET impl)
public struct CwtHeader {
    private let _claims: [CborValue: CborValue]
    // preserve the original data so we can verify the signature exactly
    let data: Data
    
    init(claims: [CborValue: CborValue], data: Data) {
        _claims = claims
        self.data = data
    }
    
    var keyId: String? {
        guard let data = _claims[ClaimIds.Header.keyId]?.asData(),
              let keyIdStr = String(data: data, encoding: .utf8) else {
            return nil
        }
        return keyIdStr
    }
    
    var algorithm: String? {
        guard let i = _claims[ClaimIds.Header.algorithm]?.asInteger() else {
            return nil
        }
        return ClaimIds.Header.algorithmMap[i]
    }
}

// wrapper which helps us unpack the CBOR Cwt Payload structure
public struct CwtPayload {
    private let _claims: [CborValue: CborValue]
    let data: Data
    
    init(claims: [CborValue: CborValue], data: Data) {
        _claims = claims
        self.data = data
    }
    
    public var jti: String? {
        guard let uuid = cti else {
            return nil
        }
        return "urn:uuid:\(uuid)" // TODO C# uses the :D formatter on the UUID which does what?
    }
    
    public var cti: UUID? {
        guard let data = _claims[ClaimIds.Payload.Cti]?.asData(), data.count == 16 else {
            return nil
        }
        
        let u: uuid_t = (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15])
        return UUID(uuid: u)
    }
    
    
    public var issuer: String? {
        _claims[ClaimIds.Payload.Iss]?.asString()
    }
    
    public var expiry: Date? {
        guard let l = _claims[ClaimIds.Payload.Exp]?.asInteger() else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(l)) // unix timestamp
    }
    
    public var notBefore: Date? {
        guard let l = _claims[ClaimIds.Payload.Nbf]?.asInteger() else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(l)) // unix timestamp
    }
    
    public var credential: VerifiableCredential? {
        guard let verifiableCredential = _claims[ClaimIds.Payload.Vc]?.asDictionary() else {
              return nil
        }
        // the C# one converts the CBOR into JSON and then uses Newtonsoft to parse the JSON back out again. I don't know why it does this
        
        guard let version = verifiableCredential["version"]?.asString() else {
            return nil // credential needs a version
        }
        guard let contexts = verifiableCredential["@context"]?.asArray() else {
            return nil // credential needs some contexts
        }
        let contextValues:[String] = contexts.compactMap { $0.asString() }
        
        guard let types = verifiableCredential["type"]?.asArray() else {
            return nil // credential needs some types
        }
        let typeValues:[String] = types.compactMap { $0.asString() }
        
        // now the nested PublicCovidPass
        guard let subject = verifiableCredential["credentialSubject"]?.asDictionary() else {
            return nil // we need a credentialSubject
        }
                
        guard let givenName = subject["givenName"]?.asString() else {
            return nil
        }
        let familyName: String? = subject["familyName"]?.asString()
            
        guard let dateOfBirth = subject["dob"]?.asString() else {
            return nil
        }
        
        let pass = PublicCovidPass(givenName: givenName, familyName: familyName, dateOfBirth: dateOfBirth)
        
        return VerifiableCredential(version: version, context: contextValues, type: typeValues, credentialSubject: pass)
    }
}

struct ClaimIds {
    struct Header {
        static let algorithm = 1
        static let keyId = 4

        // https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/blob/dev/src/Microsoft.IdentityModel.Tokens/SecurityAlgorithms.cs
        static let algorithmMap:[Int: String] = [
            -7: SecurityAlgorithms.ecdsaSha256,
            -16: SecurityAlgorithms.sha256,
            -44: SecurityAlgorithms.sha512]
    }

    struct Payload {
        static let Iss = 1
        static let Exp = 4
        static let Nbf = 5
        static let Cti = 7
        static let Vc = "vc"
    }
}
