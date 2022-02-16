# NzCovidPass-Swift
Swift library for verification of the NZ Covid Vaccination Pass according to https://nzcp.covid19.health.nz/

This library provides the Gallagher NZ Vaccine pass integration as used by the Gallagher Command Centre mobile application for iOS:

* [Press Release](https://security.gallagher.com/en/News-and-Awards/News/Gallagher-empowers-customers-to-manage-vaccine-mandates-with-enhancement-to-Command-Centre-Mobile)
* [Command Centre Mobile application](https://products.security.gallagher.com/security/global/en/products/software/command-centre-licenses/command-centre-mobile-app/p/2A8559)

Gallagher Security makes this library available for others to freely use under the MIT License, to encourage and simplify New Zealand vaccine pass verification.

Copyright (c) 2022 Gallagher Group Ltd

## Overview:

This is a self-contained implementation of a verifier for the NZ COVID Pass format, written entirely in swift.
It does not rely on any external servers, API's or other things, and can function purely offline.

### Using the library:

You should be able to import the library directly using Swift Package Manager, by referencing this GitHub repository.
Alternatively, you can clone it and reference the xcodeproj from your existing Xcode application project or workspace.

### Example:

```swift
import NzCovidPass

let passPayload = "NZCP:/1/...." // get this from scanning a QR code
let verifier = PassVerifier()
do {
    let passContents = try verifier.verify(passPayload: passPayload)
    let givenName = passContents.payload.credential?.credentialSubject.givenName ?? ""
    let familyNameCandidate = passContents.payload.credential?.credentialSubject.familyName
    let dateOfBirth = passContents.payload.credential?.credentialSubject.dateOfBirth ?? ""
            
    let fullName: String
    if let familyName = familyNameCandidate {
        fullName = "\(givenName) \(familyName)"
    } else {
        fullName = givenName
    }
    
    let expiry = passContents.payload.expiry ?? Date.distantPast
} catch let err {
    switch error {
    case PassVerificationError.invalidPrefix, PassVerificationError.invalidPassComponents:
        print("This is not an NZ Covid Pass QR Code.")
    case CwtSecurityTokenValidationError.expired:
        print("Pass Expired.")
    case CwtSecurityTokenValidationError.notYetValid:
        print("Pass Not Active.")
    default:
        // any kind of structural or signature error just results in "not issued by the ministry of health"
        print("This pass was not issued by the Ministry of Health.")
    }
}
```

## Notes:
Currently this does not dynamically download DID documents (public keys); rather the NZCP test key, and production key z12Kf7UQ are embedded in the source code. This has the advantage that it always works offline, there is no "first run" internet connection required, however it does mean if the ministry of health issues a new production keypair, then the library will need to be updated.

We expect to add dynamic downloading of DID documents in future.

## Acknowledgements:

This library was implemented using the .NET NZ Covid Pass verifier by Jed Simson https://github.com/JedS6391/NzCovidPass as a reference.

While this library shares some structure, it is not a direct port. It follows different patterns and practices to suit Swift and iOS.
Some parts needed to be added (CBOR and Base32), and some parts have been simplified, however credit must be given to Jed; his implementation helped us develop this library more quickly and to a higher degree of quality.
