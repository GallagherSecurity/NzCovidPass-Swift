//
// Copyright Gallagher Group Ltd 2021
//
import Foundation
import XCTest
@testable import NzCovidPass

// All pass data is from the technical specification at https://nzcp.covid19.health.nz/
class PassVerifierTests : XCTestCase {
    
    static let validPassPayload =  "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVAYFE6VGU4MCDGK7DHLLYWHVPUS2YIDJOA6Y524TD3AZRM263WTY2BE4DPKIF27WKF3UDNNVSVWRDYIYVJ65IRJJJ6Z25M2DO4YZLBHWFQGVQR5ZLIWEQJOZTS3IQ7JTNCFDX"
    
    let verifier = PassVerifier(validIssuers: [WellKnownIssuerNames.nzcpTest])
    // tests run against a fixed "now" time to stop them failing when run in the future
    let referenceTime = Date(timeIntervalSince1970: 1639345844)
    
    // SUCCESS test
    func testValidatesTrustedIssuer() throws {
        _ = try verifier.verify(passPayload: PassVerifierTests.validPassPayload, referenceTime: referenceTime)
    }
    
    func testRejectsIncorrectPayload() throws {
        // some other thing that might be in a QR code
        let payload = "https://www.example.com"
        XCTAssertThrowsError(
            try verifier.verify(passPayload: payload, referenceTime: referenceTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? PassVerificationError, PassVerificationError.invalidPrefix) })
    }
    
    func testRejectsIncorrectVersion() throws {
        // some other thing that might be in a QR code
        let payload = "NZCP:/2/sdfdsfd"
        XCTAssertThrowsError(
            try verifier.verify(passPayload: payload, referenceTime: referenceTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? PassVerificationError, PassVerificationError.invalidVersion) })
    }
    
    func testRejectsBadPublicKey() throws {
        let payload = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVAY73U6TCQ3KF5KFML5LRCS5D3PCYIB2D3EOIIZRPXPUA2OR3NIYCBMGYRZUMBNBDMIA5BUOZKVOMSVFS246AMU7ADZXWBYP7N4QSKNQ4TETIF4VIRGLHOXWYMR4HGQ7KYHHU"
                
        XCTAssertThrowsError(
            try verifier.verify(passPayload: payload, referenceTime: referenceTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? CwtSecurityTokenValidationError, CwtSecurityTokenValidationError.invalidSignature) })
    }
    
    func testRejectsPublicKeyNotFound() throws {
        let payload = "NZCP:/1/2KCEVIQEIVVWK6JNGIASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVBMP3LEDMB4CLBS2I7IOYJZW46U2YIBCSOFZMQADVQGM3JKJBLCY7ATASDTUYWIP4RX3SH3IFBJ3QWPQ7FJE6RNT5MU3JHCCGKJISOLIMY3OWH5H5JFUEZKBF27OMB37H5AHF"
                
        XCTAssertThrowsError(
            try verifier.verify(passPayload: payload, referenceTime: referenceTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? CwtSecurityTokenValidationError, CwtSecurityTokenValidationError.invalidIssuer) })
    }
    
    func testRejectsModifiedSignature() throws {
        let payload = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVAYFE6VGU4MCDGK7DHLLYWHVPUS2YIAAAAAAAAAAAAAAAAC63WTY2BE4DPKIF27WKF3UDNNVSVWRDYIYVJ65IRJJJ6Z25M2DO4YZLBHWFQGVQR5ZLIWEQJOZTS3IQ7JTNCFDX"
                
        XCTAssertThrowsError(
            try verifier.verify(passPayload: payload, referenceTime: referenceTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? CwtSecurityTokenValidationError, CwtSecurityTokenValidationError.invalidSignature) })
    }
    
    func testRejectsModifiedPayload() throws {
        let payload = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEOKKALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUYMBTIFAIGTUKBAAUYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWKU3UMV3GK2TGMFWWS3DZJZQW2ZLDIRXWKY3EN5RGUMJZGYYC2MBUFUYTMB2QMCSPKTKOGBBTFPRTVV4LD2X2JNMEAAAAAAAAAAAAAAAABPN3J4NASOBXVEC5P3FC52BWW2ZK3IR4EMKU7OUIUUU7M5OWNBXOMMVQT3CYDKYI64VULCIEXMZZNUIPUZWRCR3Q"
                
        XCTAssertThrowsError(
            try verifier.verify(passPayload: payload, referenceTime: referenceTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? CwtSecurityTokenValidationError, CwtSecurityTokenValidationError.invalidSignature) })
    }
    
    func testRejectsExpiredPass() throws {
        let payload = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRUX5AM2FQIGTBPBPYWYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVA56TNJCCUN2NVK5NGAYOZ6VIWACYIBM3QXW7SLCMD2WTJ3GSEI5JH7RXAEURGATOHAHXC2O6BEJKBSVI25ICTBR5SFYUDSVLB2F6SJ63LWJ6Z3FWNHOXF6A2QLJNUFRQNTRU"
                
        XCTAssertThrowsError(
            try verifier.verify(passPayload: payload, referenceTime: referenceTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? CwtSecurityTokenValidationError, CwtSecurityTokenValidationError.expired) })
    }
    
    func testRejectsNotYetActivePass() throws {
        let payload = "NZCP:/1/2KCEVIQEIVVWK6JNGEASNICZAEP2KALYDZSGSZB2O5SWEOTOPJRXALTDN53GSZBRHEXGQZLBNR2GQLTOPICRU2XI5UFQIGTMZIQIWYTWMOSGQQDDN5XHIZLYOSBHQJTIOR2HA4Z2F4XXO53XFZ3TGLTPOJTS6MRQGE4C6Y3SMVSGK3TUNFQWY4ZPOYYXQKTIOR2HA4Z2F4XW46TDOAXGG33WNFSDCOJONBSWC3DUNAXG46RPMNXW45DFPB2HGL3WGFTXMZLSONUW63TFGEXDALRQMR2HS4DFQJ2FMZLSNFTGSYLCNRSUG4TFMRSW45DJMFWG6UDVMJWGSY2DN53GSZCQMFZXG4LDOJSWIZLOORUWC3CTOVRGUZLDOSRWSZ3JOZSW4TTBNVSWISTBMNVWUZTBNVUWY6KOMFWWKZ2TOBQXE4TPO5RWI33CNIYTSNRQFUYDILJRGYDVA27NR3GFF4CCGWF66QGMJSJIF3KYID3KTKCBUOIKIC6VZ3SEGTGM3N2JTWKGDBAPLSG76Q3MXIDJRMNLETOKAUTSBOPVQEQAX25MF77RV6QVTTSCV2ZY2VMN7FATRGO3JATR"
                
        XCTAssertThrowsError(
            try verifier.verify(passPayload: payload, referenceTime: referenceTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? CwtSecurityTokenValidationError, CwtSecurityTokenValidationError.notYetValid) })
    }
    
    // these ones I've added, they're not strictly from the nzcp website
    
    func testRejectsValidPassAsExpired_FutureReferenceDate() throws {
        let yearSeconds: TimeInterval = 31540000
        let futureTime = referenceTime.addingTimeInterval(yearSeconds * 10) // sample pass expires in 2031, move past that date
        
        XCTAssertThrowsError(
            try verifier.verify(passPayload: PassVerifierTests.validPassPayload, referenceTime: futureTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? CwtSecurityTokenValidationError, CwtSecurityTokenValidationError.expired) })
    }
    
    func testRejectsValidPassAsNotActive_PastReferenceDate() throws {
        let yearSeconds: TimeInterval = 31540000
        let futureTime = referenceTime.addingTimeInterval(-yearSeconds) // sample pass expires in 2031, move past that date
        
        XCTAssertThrowsError(
            try verifier.verify(passPayload: PassVerifierTests.validPassPayload, referenceTime: futureTime),
            "TokenValidationError should have been thrown",
            { error in XCTAssertEqual(error as? CwtSecurityTokenValidationError, CwtSecurityTokenValidationError.notYetValid) })
    }

}
