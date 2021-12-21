//
// Copyright Gallagher Group Ltd 2021
//
import Foundation
import XCTest
@testable import NzCovidPass

// ref https://github.com/cbor/test-vectors/blob/master/appendix_a.json
class CborReadTests: XCTestCase {

    func readSingleBase64(_ str: String) throws -> CborValue {
        var reader = CborReader(data: Data(base64Encoded: str)!)
        return try reader.read()
    }
    
    func readSingleHex(_ str: String) throws -> CborValue {
        var reader = CborReader(data: Data(hexString: str)!)
        return try reader.read()
    }
    
    func testReadZero() throws {
        let result = try readSingleBase64("AA==")
        if case let .integer(value) = result {
            XCTAssertEqual(0, value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadOne() throws {
        let pos = try readSingleBase64("AQ==")
        if case let .integer(value) = pos {
            XCTAssertEqual(1, value)
        } else {
            XCTFail("invalid CborValue type")
        }
        
        let neg = try readSingleBase64("IA==")
        if case let .integer(value) = neg {
            XCTAssertEqual(-1, value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadTen() throws {
        let pos = try readSingleBase64("Cg==")
        if case let .integer(value) = pos {
            XCTAssertEqual(10, value)
        } else {
            XCTFail("invalid CborValue type")
        }
        
        let neg = try readSingleBase64("KQ==")
        if case let .integer(value) = neg {
            XCTAssertEqual(-10, value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testRead100() throws {
        let pos = try readSingleBase64("GGQ=")
        if case let .integer(value) = pos {
            XCTAssertEqual(100, value)
        } else {
            XCTFail("invalid CborValue type")
        }
        
        let neg = try readSingleBase64("OGM=")
        if case let .integer(value) = neg {
            XCTAssertEqual(-100, value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testRead1000000() throws {
        let result = try readSingleBase64("GgAPQkA=")
        if case let .integer(value) = result {
            XCTAssertEqual(1000000, value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadEmptyString() throws {
        let result = try readSingleBase64("YA==")
        if case let .textString(value) = result {
            XCTAssertEqual("", value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadString_a() throws {
        let result = try readSingleBase64("YWE=")
        if case let .textString(value) = result {
            XCTAssertEqual("a", value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadString_IETF() throws {
        let result = try readSingleBase64("ZElFVEY=")
        if case let .textString(value) = result {
            XCTAssertEqual("IETF", value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadString_umlaut() throws {
        let result = try readSingleBase64("YsO8")
        if case let .textString(value) = result {
            XCTAssertEqual("ü", value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadString_asian() throws {
        let result = try readSingleBase64("Y+awtA==")
        if case let .textString(value) = result {
            XCTAssertEqual("水", value)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadString() throws {
        let result = try readSingleHex("76687474703a2f2f7777772e6578616d706c652e636f6d")
        if case let .textString(str) = result {
            XCTAssertEqual("http://www.example.com", str)
        } else {
            XCTFail("invalid CborValue value type")
        }
    }
    
    func testReadTaggedString32() throws {
        let result = try readSingleHex("D820" + "76687474703a2f2f7777772e6578616d706c652e636f6d")
        if case let .tagged(tag: tag, value: value) = result {
            XCTAssertEqual(32, tag)
            if case let .textString(str) = value {
                XCTAssertEqual("http://www.example.com", str)
            } else {
                XCTFail("invalid tagged value type")
            }
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadEmptyArray() throws {
        let result = try readSingleBase64("gA==")
        if case let .array(values) = result {
            XCTAssertEqual([], values)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadNumberArray() throws {
        let result = try readSingleBase64("gwECAw==")
        if case let .array(values) = result {
            XCTAssertEqual([CborValue(integer: 1), CborValue(integer: 2), CborValue(integer: 3)], values)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadNestedNumberArray() throws {
        let result = try readSingleBase64("gwGCAgOCBAU=")
        if case let .array(values) = result {
            XCTAssertEqual([
                CborValue(integer: 1),
                CborValue(array: [.integer(2), .integer(3)]),
                CborValue(array: [.integer(4), .integer(5)]),
            ], values)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadNumberMap() throws {
        let result = try readSingleBase64("ogECAwQ=")
        if case let .map(values) = result {
            XCTAssertEqual([
                .integer(1): .integer(2),
                .integer(3): .integer(4)
            ], values)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadArrayStringMap() throws {
        let result = try readSingleBase64("omFhAWFiggID")
        if case let .map(values) = result {
            XCTAssertEqual([
                .textString("a"): .integer(1),
                .textString("b"): .array([.integer(2), .integer(3)])
            ], values)
        } else {
            XCTFail("invalid CborValue type")
        }
    }
    
    func testReadCoseCovidPass() throws {
        let result = try readSingleHex("d2844aa204456b65792d310126a059011fa501781e6469643a7765623a6e7a63702e636f76696431392e6865616c74682e6e7a051a61819a0a041a7450400a627663a46840636f6e7465787482782668747470733a2f2f7777772e77332e6f72672f323031382f63726564656e7469616c732f7631782a68747470733a2f2f6e7a63702e636f76696431392e6865616c74682e6e7a2f636f6e74657874732f76316776657273696f6e65312e302e306474797065827456657269666961626c6543726564656e7469616c6f5075626c6963436f766964506173737163726564656e7469616c5375626a656374a369676976656e4e616d65644a61636b6a66616d696c794e616d656753706172726f7763646f626a313936302d30342d3136075060a4f54d4e304332be33ad78b1eafa4b5840d2e07b1dd7263d833166bdbb4f1a093837a905d7eca2ee836b6b2ada23c23154fba88a529f675d6686ee632b09ec581ab08f72b458904bb3396d10fa66d11477")
        
        if case let .tagged(tag: tag, value: value) = result {
            XCTAssertEqual(18, tag) // COSE single sign data
            if case let .array(ary) = value {
                XCTAssertEqual(4, ary.count)
                XCTAssertEqual(.byteString, ary[0].type)
                XCTAssertEqual(.map, ary[1].type)
                XCTAssertEqual(.byteString, ary[2].type)
                XCTAssertEqual(.byteString, ary[3].type)
                
            } else {
                XCTFail("expected array at level 1")
            }
        } else {
            XCTFail("expected tagged(18) at root")
        }
    }
    
    func testReadCoseCovidPassExpired() throws {
        let result = try readSingleHex("d2844aa204456b65792d310126a059011fa501781e6469643a7765623a6e7a63702e636f76696431392e6865616c74682e6e7a051a5fa0668b041a61785f8b627663a46840636f6e7465787482782668747470733a2f2f7777772e77332e6f72672f323031382f63726564656e7469616c732f7631782a68747470733a2f2f6e7a63702e636f76696431392e6865616c74682e6e7a2f636f6e74657874732f76316776657273696f6e65312e302e306474797065827456657269666961626c6543726564656e7469616c6f5075626c6963436f766964506173737163726564656e7469616c5375626a656374a369676976656e4e616d65644a61636b6a66616d696c794e616d656753706172726f7763646f626a313936302d30342d3136075077d36a442a374daabad3030ecfaa8b00584059b85edf92c4c1ead34ecd2223a93fe37012913026e380f7169de0912a0caa8d75029863d917141caab0e8be927db5d93ececb669dd72f81a82d2da16306ce34")
        
        if case let .tagged(tag: tag, value: value) = result {
            XCTAssertEqual(18, tag) // COSE single sign data
            if case let .array(ary) = value {
                XCTAssertEqual(4, ary.count)
                XCTAssertEqual(.byteString, ary[0].type)
                XCTAssertEqual(.map, ary[1].type)
                XCTAssertEqual(.byteString, ary[2].type)
                XCTAssertEqual(.byteString, ary[3].type)
                
            } else {
                XCTFail("expected array at level 1")
            }
        } else {
            XCTFail("expected tagged(18) at root")
        }
    }
}

class CborWriteTests: XCTestCase {
    
    func writeSingleBase64(_ value: CborValue) throws -> String {
        var writer = CborWriter()
        try writer.write(value)
        return writer.buffer.base64EncodedString()
    }

    func writeSingleHex(_ value: CborValue) throws -> String {
        var writer = CborWriter()
        try writer.write(value)
        return writer.buffer.hexString()
    }
    
    func testWriteZero() throws {
        let result = try writeSingleBase64(.integer(0))
        XCTAssertEqual("AA==", result)
    }
    
    func testWriteOne() throws {
        let pos = try writeSingleBase64(.integer(1))
        XCTAssertEqual("AQ==", pos)
        
        let neg = try writeSingleBase64(.integer(-1))
        XCTAssertEqual("IA==", neg)
    }
    
    func testWriteTen() throws {
        let pos = try writeSingleBase64(.integer(10))
        XCTAssertEqual("Cg==", pos)
        
        let neg = try writeSingleBase64(.integer(-10))
        XCTAssertEqual("KQ==", neg)
    }
    
    func testWrite100() throws {
        let pos = try writeSingleBase64(.integer(100))
        XCTAssertEqual("GGQ=", pos)
        
        let neg = try writeSingleBase64(.integer(-100))
        XCTAssertEqual("OGM=", neg)
    }
    
    func testWrite1000000() throws {
        let pos = try writeSingleBase64(.integer(1000000))
        XCTAssertEqual("GgAPQkA=", pos)
    }
    
    func testWriteEmptyString() throws {
        let pos = try writeSingleBase64(.textString(""))
        XCTAssertEqual("YA==", pos)
    }
    
    func testWriteString_a() throws {
        let pos = try writeSingleBase64(.textString("a"))
        XCTAssertEqual("YWE=", pos)
    }
    
    func testWriteString_IETF() throws {
        let str = try writeSingleBase64(.textString("IETF"))
        XCTAssertEqual("ZElFVEY=", str)
    }
    
    func testWriteString_umlaut() throws {
        let str = try writeSingleBase64(.textString("ü"))
        XCTAssertEqual("YsO8", str)
    }
    
    func testWriteString_asian() throws {
        let str = try writeSingleBase64(.textString("水"))
        XCTAssertEqual("Y+awtA==", str)
    }
    
    func testWriteString() throws {
        let str = try writeSingleHex(.textString("http://www.example.com"))
        XCTAssertEqual("76687474703a2f2f7777772e6578616d706c652e636f6d", str)
    }
    
    // writer can't do tagged values yet
    
    func testWriteEmptyArray() throws {
        let str = try writeSingleBase64(.array([]))
        XCTAssertEqual("gA==", str)
    }
    
    func testWriteNumberArray() throws {
        let str = try writeSingleBase64(.array([.integer(1), .integer(2), .integer(3)]))
        XCTAssertEqual("gwECAw==", str)
    }
    
    func testWriteNestedNumberArray() throws {
        let str = try writeSingleBase64(
            .array([
                .integer(1),
                .array([.integer(2), .integer(3)]),
                .array([.integer(4), .integer(5)]),
            ]))
        XCTAssertEqual("gwGCAgOCBAU=", str)
    }
    
    // writer can't do maps yet
}
