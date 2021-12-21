//
// Copyright Gallagher Group Ltd 2021
//
import Foundation
import XCTest
@testable import NzCovidPass

// ref https://github.com/cbor/test-vectors/blob/master/appendix_a.json
class Base32Tests: XCTestCase {
    func testDecodeEmptyString() {
        if let d = Data(base32encoded: "") {
            XCTAssertEqual(0, d.count)
            return
        } else {
            XCTFail("Can't decode")
        }
    }
    
    func testDecodeString() {
        if let d = Data(base32encoded: "IRXWO===") {
            XCTAssertEqual("Dog".data(using: .ascii), d)
            return
        } else {
            XCTFail("Can't decode")
        }
    }
    
    func testDecodeBinary() {
        // 1px transparent PNG file image from https://png-pixel.com/
        let referenceData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==")
        
        // converted to base32 by https://cryptii.com/pipes/ (text->decodeBase64->encodeBase32->text)
        if let d = Data(base32encoded: "RFIE4RYNBINAUAAAAAGUSSCEKIAAAAABAAAAAAIIAYAAAAA7CXCISAAAAAGUSRCBKR4NUY7476P2CHQAA6BAE7Z5ZBEO6AAAAAAESRKOISXEEYEC") {
            XCTAssertEqual(referenceData, d)
            return
        } else {
            XCTFail("Can't decode")
        }
    }
}
