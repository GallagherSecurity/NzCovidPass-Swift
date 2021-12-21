//
// Copyright Gallagher Group Ltd 2021
//
import Foundation

// Contains claims about the subject(s) of a VerifiableCredential
public protocol CredentialSubject {
    var context: String { get }
    var type: String { get }
}

public struct PublicCovidPass : CredentialSubject, Decodable {
    public let givenName: String // required
    public let familyName: String? // optional
    public let dateOfBirth: String // required // contains a simplified string like "1960-04-27"
    
    // see https://nzcp.covid19.health.nz/#verifiable-credential-claim-structure
    public var context: String { "https://nzcp.covid19.health.nz/contexts/v1" }
    
    // see https://nzcp.covid19.health.nz/#publiccovidpass
    public var type: String { "PublicCovidPass" }
}

public struct VerifiableCredential : Decodable {
    /// The JSON-LD context property value associated with the base verifiable credential structure.
    /// see https://www.w3.org/TR/vc-data-model/#contexts"
    public static let baseContext = "https://www.w3.org/2018/credentials/v1"
    
    /// The type property value associated with the base verifiable credential type.
    /// see https://www.w3.org/TR/vc-data-model/#types
    public static let baseCredentialType = "VerifiableCredential"
    
    public let version: String
    public let context: [String]
    public let type: [String]
    public let credentialSubject: PublicCovidPass // C# has VerifiableCredential<T> but in practice we only ever have PublicCovidPass so we can strip the generics
    
    private enum CodingKeys: String, CodingKey {
        case version, type, credentialSubject
        case context = "@context"
    }
}
