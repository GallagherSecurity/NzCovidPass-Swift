# NzCovidPass-Swift
Swift library for verification of the NZ Covid Vaccination Pass according to https://nzcp.covid19.health.nz/

Copyright (c) 2021 Gallagher Group Ltd

Licensed under the MIT License

## Notes:
Currently this does not dynamically download DID documents (public keys); rather the NZCP test key, and production key z12Kf7UQ are embedded in the source code. This has the advantage that it always works offline, there is no "first run" internet connection required, however it does mean if the ministry of health issues a new production keypair, then the library will need to be updated.

We expect to add dynamic downloading of DID documents in future.

## Acknowledgements:

This library was implemented using the .NET NZ Covid Pass verifier by Jed Simson https://github.com/JedS6391/NzCovidPass as a reference.

While this library shares some structure, it is not a direct port. It follows different patterns and practices to suit Swift and iOS.
Some parts needed to be added (CBOR and Base32), and some parts have been simplified, however credit must be given to Jed; his implementation helped us develop this library more quickly and to a higher degree of quality.
