//
// Copyright Gallagher Group Ltd 2021
//
import Foundation

/// NOTE: The default PassVerifierOptions only include the production issuer (did:web:nzcp.identity.health.nz)
/// If you would like to validate the test passes available on https://nzcp.covid19.health.nz/ then you need to adjust validIssuers to include that as a trusted source
public struct PassVerifierOptions {
    let prefix: String
    let version: Int
    let validIssuers: [String]
    let validAlgorithms: [String]
    // todo securityKeyCacheTime?
    
    init(
        prefix: String = Defaults.prefix,
        version: Int = Defaults.version,
        validIssuers: [String] = Defaults.validIssuers,
        validAlgorithms: [String] = Defaults.validAlgorithms)
    {
        self.prefix = prefix
        self.version = version
        self.validIssuers = validIssuers
        self.validAlgorithms = validAlgorithms
    }
    
    public struct Defaults {
        public static let prefix:String = "NZCP:"
        public static let version:Int = 1
        public static let validIssuers = [WellKnownIssuerNames.nzcp]
        public static let validAlgorithms = [SecurityAlgorithms.ecdsaSha256]
    }
}

public class PassVerifier {
    let options: PassVerifierOptions
    
    // utility so you don't have to create the options structure yourself
    public convenience init(
        prefix: String = PassVerifierOptions.Defaults.prefix,
        version: Int = PassVerifierOptions.Defaults.version,
        validIssuers: [String] = PassVerifierOptions.Defaults.validIssuers,
        validAlgorithms: [String] = PassVerifierOptions.Defaults.validAlgorithms) {
        self.init(options: .init(
            prefix: prefix,
            version: version,
            validIssuers: validIssuers,
            validAlgorithms: validAlgorithms))
    }
    
    public init(options: PassVerifierOptions) {
        self.options = options
    }
    
    // throws CwtSecurityTokenError on failure to parse, TokenValidationError on failure to validate, PassVerificationError on generic error
    public func verify(passPayload: String, referenceTime: Date? = nil) throws -> CwtSecurityToken {
        let passComponents = passPayload.components(separatedBy: "/")
        try validatePassComponents(passComponents)
        
        guard let payload = Data(base32encoded: passComponents[2]) else {
            throw PassVerificationError.invalidPayloadEncoding
        }
        
        // Decode the payload and read the CWT contained
        let token = try CwtSecurityToken(data: payload)
        
        // Validate token claims and signature
        let validator = CwtSecurityTokenValidator(options: self.options)
        try validator.validateToken(token, referenceTime: referenceTime)
        
        return token
    }
    
    // throws PassVerificationError
    func validatePassComponents(_ components: [String]) throws {
        guard components.count == 3 else {
            throw PassVerificationError.invalidPassComponents
        }
        
        let prefix = components[0]
        let version = components[1]
        let payload = components[2]
        
        if prefix != options.prefix {
            throw PassVerificationError.invalidPrefix
        }
        
        if version != "\(options.version)" { // don't need to parse the string, we're just checking it
            throw PassVerificationError.invalidVersion
        }
        
        if payload == "" {
            throw PassVerificationError.missingPayload
        }
    }
}

public enum PassVerificationError : Error {
    case invalidPassComponents // pass payload must be in the form <prefix>:/<version>/<base32-encoded-CWT>'
    case invalidPrefix
    case invalidVersion
    case missingPayload
    case invalidPayloadEncoding
    case missingCredentialSubject
}
