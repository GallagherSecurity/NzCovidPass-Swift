//
// Copyright Gallagher Group Ltd 2021
//
import Foundation
import XCTest
@testable import NzCovidPass

class CwtSecurityTokenReaderTests: XCTestCase {
    
    func testReadTokenSuccessful() throws {
        // this one is from nzcp.covid19.health.nz, also used by the C# project
        let payload = Data(base32encoded: "2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVAYFE6VGU4MCDGK7DHLLYWHVPUS2YIDJOA6Y524TD3AZRM263WTY2BE4DPKIF27WKF3UDNNVSVWRDYIYVJ65IRJJJ6Z25M2DO4YZLBHWFQGVQR5ZLIWEQJOZTS3IQ7JTNCFDX")!

        let token = try CwtSecurityToken(data: payload)
        XCTAssertEqual("key-1", token.header.keyId)
        XCTAssertEqual("ES256", token.header.algorithm)
        
        XCTAssertEqual(UUID(uuidString: "60A4F54D-4E30-4332-BE33-AD78B1EAFA4B"), token.payload.cti)
        XCTAssertEqual("did:web:nzcp.covid19.health.nz", token.payload.issuer)
        XCTAssertEqual(Date(iso8601: "2031-11-02T20:05:30+0000")!, token.payload.expiry)
        XCTAssertEqual(Date(iso8601: "2021-11-02T20:05:30+0000")!, token.payload.notBefore)
        
        guard let credential = token.payload.credential else {
            XCTFail("no credential")
            return
        }
        XCTAssertEqual("1.0.0", credential.version)
        XCTAssertEqual(["VerifiableCredential", "PublicCovidPass"], credential.type)
        XCTAssertEqual(["https://www.w3.org/2018/credentials/v1", "https://nzcp.covid19.health.nz/contexts/v1"], credential.context)
        XCTAssertEqual("Jack", credential.credentialSubject.givenName)
        XCTAssertEqual("Sparrow", credential.credentialSubject.familyName)
        XCTAssertEqual("1960-04-16", credential.credentialSubject.dateOfBirth)
    }
    
    func testReadExpiredPass() throws {
        let payload = Data(base32encoded: "2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUX5AM2FQIGTBPBPYWYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVA56TNJCCUN2NVK5NGAYOZ6VIWACYIBM3QXW7SLCMD2WTJ3GSEI5JH7RXAEURGATOHAHXC2O6BEJKBSVI25ICTBR5SFYUDSVLB2F6SJ63LWJ6Z3FWNHOXF6A2QLJNUFRQNTRU")!
        
        let token = try CwtSecurityToken(data: payload)
        XCTAssertEqual("key-1", token.header.keyId)
        XCTAssertEqual("ES256", token.header.algorithm)
        
        XCTAssertEqual(UUID(uuidString: "77D36A44-2A37-4DAA-BAD3-030ECFAA8B00"), token.payload.cti)
        XCTAssertEqual("did:web:nzcp.covid19.health.nz", token.payload.issuer)
        XCTAssertEqual(Date(iso8601: "2021-10-26T20:05:31+0000")!, token.payload.expiry)
        XCTAssertEqual(Date(iso8601: "2020-11-02T20:05:31+0000")!, token.payload.notBefore)
        
        guard let credential = token.payload.credential else {
            XCTFail("no credential")
            return
        }
        XCTAssertEqual("1.0.0", credential.version)
        XCTAssertEqual(["VerifiableCredential", "PublicCovidPass"], credential.type)
        XCTAssertEqual(["https://www.w3.org/2018/credentials/v1", "https://nzcp.covid19.health.nz/contexts/v1"], credential.context)
        XCTAssertEqual("Jack", credential.credentialSubject.givenName)
        XCTAssertEqual("Sparrow", credential.credentialSubject.familyName)
        XCTAssertEqual("1960-04-16", credential.credentialSubject.dateOfBirth)
    }
}
