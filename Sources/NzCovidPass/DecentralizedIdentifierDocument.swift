//
// Copyright Gallagher Group Ltd 2021
//
import Foundation

struct JsonWebKey: Decodable {
    let kty: String?
    let crv: String?
    let x: String? // base64Url encoded data
    let y: String? // base64Url encoded data
    
    // JsonWebKey can have many more fields, but these are the only ones the covid pass uses
}

struct VerificationMethod : Decodable {
    let id: String
    let controller: String
    let type: String
    let publicKeyJwk: JsonWebKey
}

// Represents a Decentralized Identifier (DID) document, as described by https://www.w3.org/TR/did-core/#did-documents
struct DecentralizedIdentifierDocument : Decodable {
    let id: String
    let contexts: [String]
    let verificationMethods: [VerificationMethod]
    let assertionMethods: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case contexts = "@context"
        case verificationMethods = "verificationMethod"
        case assertionMethods = "assertionMethod"
    }
    
    // "@context" can either be a single string or an array, so we must add custom deserialization logic
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        
        do {
            self.contexts = try container.decode([String].self, forKey: .contexts)
        } catch {
            let singleContext = try container.decode(String.self, forKey: .contexts)
            self.contexts = [singleContext]
        }
        
        self.verificationMethods = try container.decode([VerificationMethod].self, forKey: .verificationMethods)
        self.assertionMethods = try container.decode([String].self, forKey: .assertionMethods)
    }
}

public struct WellKnownIssuerNames {
    public static let nzcpTest = "did:web:nzcp.covid19.health.nz"
    public static let nzcp = "did:web:nzcp.identity.health.nz"
}

// normally we would resolve DID web keys by going to https://<base>/.well-known/did.json
// however we don't need to do that until the ministry of health rotates their keys, so we
// can build the defaults in for now
struct WellKnownIssuers {
    // test keys
    private static let nzcpCovid19HealthNzKey1_raw = #"""
{
  "@context": "https://w3.org/ns/did/v1",
  "id": "did:web:nzcp.covid19.health.nz",
  "verificationMethod": [
    {
      "id": "did:web:nzcp.covid19.health.nz#key-1",
      "controller": "did:web:nzcp.covid19.health.nz",
      "type": "JsonWebKey2020",
      "publicKeyJwk": {
        "kty": "EC",
        "crv": "P-256",
        "x": "zRR-XGsCp12Vvbgui4DD6O6cqmhfPuXMhi1OxPl8760",
        "y": "Iv5SU6FuW-TRYh5_GOrJlcV_gpF_GpFQhCOD8LSk3T0"
      }
    }
  ],
  "assertionMethod": [
    "did:web:nzcp.covid19.health.nz#key-1"
  ]
}
"""#
    
    // This is a real key used to validate real covid passes
    private static let nzcpIdentityHealthNzKey_z12Kf_raw = #"""
{
    "id": "did:web:nzcp.identity.health.nz",
    "@context": [
        "https://w3.org/ns/did/v1",
        "https://w3id.org/security/suites/jws-2020/v1"
    ],
    "verificationMethod": [
        {
            "id": "did:web:nzcp.identity.health.nz#z12Kf7UQ",
            "controller": "did:web:nzcp.identity.health.nz",
            "type": "JsonWebKey2020",
            "publicKeyJwk": {
                "kty": "EC",
                "crv": "P-256",
                "x": "DQCKJusqMsT0u7CjpmhjVGkHln3A3fS-ayeH4Nu52tc",
                "y": "lxgWzsLtVI8fqZmTPPo9nZ-kzGs7w7XO8-rUU68OxmI"
            }
        }
    ],
    "assertionMethod": [
        "did:web:nzcp.identity.health.nz#z12Kf7UQ"
    ]
}
"""#
    
    private static var _issuers: [DecentralizedIdentifierDocument] = []
    
    public static func find(issuer: String, keyId: String) throws -> DecentralizedIdentifierDocument? {
        // load issuers if need be.
        // TODO this is where we would go off to the internet and fetch the issuer, should we need to
        if _issuers.isEmpty {
            let decoder = JSONDecoder()
            _issuers = try [nzcpIdentityHealthNzKey_z12Kf_raw, nzcpCovid19HealthNzKey1_raw].map { str in
                // technically unnecessary as our keys are currently static/hardcoded, but
                // in future when we go fetching things from the internet this will be needed
                guard let didData = str.data(using: .utf8) else {
                    throw DecentralizedIdentifierDocumentError.malformedInput
                }
                return try decoder.decode(DecentralizedIdentifierDocument.self, from: didData)
            }
        }
        
        return _issuers.first { did in
            did.id == issuer && did.assertionMethods.contains("\(issuer)#\(keyId)")
        }
    }
}

enum DecentralizedIdentifierDocumentError : Error {
    case malformedInput
}
