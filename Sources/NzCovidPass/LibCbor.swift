//
// Copyright Gallagher Group Ltd 2021
//

// The intention is that this file will split out into it's own library, like MiniRxSwift or LibAsn.
// but for now single-file inline is OK. This contains just enough CBOR to validate NZ Covid Passes; it is not a complete CBOR implementation.

import Foundation

enum CborValue : Hashable, Equatable {
    /// CBOR encoded map (major type 5)
    case map([CborValue: CborValue])
    
    /// CBOR encoded array (major type 4)
    case array([CborValue])
    
    /// CBOR encoded integer (major types 0 and 1)
    case integer(Int)
    
    /// CBOR encoded text (major type 3)
    case textString(String)
    
    /// CBOR encoded text (major type 2)
    case byteString(Data)
    
    /// CBOR value with additional semantic tag (such as 32 for a URL)
    indirect case tagged(tag: Int, value: CborValue)
}

extension CborValue {
    
    // convenience initializers
    init(integer: Int) {
        self = .integer(integer)
    }
    
    init(string: String) {
        self = .textString(string)
    }
    
    init(array: [CborValue]) {
        self = .array(array)
    }
    
    init(map: [CborValue: CborValue]) {
        self = .map(map)
    }
    
    // convenience for getting values out rather than using guard case let
    
    func asInteger() -> Int? {
        if case let .integer(i) = self {
            return i
        }
        return nil
    }
    
    func asData() -> Data? {
        if case let .byteString(d) = self {
            return d
        }
        return nil
    }
    
    func asString() -> String? {
        if case let .textString(s) = self {
            return s
        }
        return nil
    }
    
    func asArray() -> [CborValue]? {
        if case let .array(a) = self {
            return a
        }
        return nil
    }
    
    func asDictionary() -> [CborValue: CborValue]? {
        if case let .map(m) = self {
            return m
        }
        return nil
    }
    
    // for diagnostics, no real logic should depend on this
    var type: CborMajorType {
        switch self {
        case .integer(let i): return i >= 0 ? .positiveInt : .negativeInt
        case .textString(_): return .textString
        case .byteString(_): return .byteString
        case .array(_): return .array
        case .map(_): return .map
        case .tagged(_, _): return .semanticTag
        }
    }
}



// helper for reading CBOR maps
extension Dictionary where Key == CborValue, Value == CborValue {
    subscript(key: String) -> CborValue? {
        self[CborValue.textString(key)]
    }
    
    subscript(key: Int) -> CborValue? {
        self[CborValue.integer(key)]
    }
}

enum CborMajorType : UInt8 {
    case positiveInt = 0 // 000 major type 0
    case negativeInt = 1 // 001 major type 1
    case byteString = 2 // 010 major type 2
    case textString = 3 // 011  major type 3
    case array = 4 // 100 major type 4
    case map = 5 // 101 major type 5
    case semanticTag = 6 // 110 major type 6
    case special = 7 // 111 major type 7 (special or float)
    
    static func identify(byte: UInt8) -> CborMajorType {
        // first 3 bits in a CBOR tag are the major type
        guard let result = CborMajorType(rawValue: (byte & 0xE0) >> 5) else {
            fatalError("UInt8 right-shifted by 5 cannot be greater than 7")
        }
        return result
    }
}

enum CborReadError : Error {
    case malformedInput
    case inputTooShort
    case invalidUtf8String
}

enum CborWriteError : Error {
    case nonUtf8textString
}

struct CborReader {
    let data: Data
    var pos: Data.Index
    
    init(data: Data) {
        self.data = data // COW should cause us to just reference the data as we don't modify it
        pos = data.startIndex
    }
    
    mutating func read() throws -> CborValue {
        switch CborMajorType.identify(byte: data[pos]) {
        case .positiveInt: return .integer(try readPositiveInt())
        case .negativeInt: return .integer(try readNegativeInt())
        case .byteString: return .byteString(try readByteString())
        case .textString: return .textString(try readTextString())
        case .array: return .array(try readArray())
        case .map: return .map(try readMap())
        case .semanticTag:
            let (tag, value) = try readTagged()
            return .tagged(tag: tag, value: value)
        case .special: fatalError("not implemented yet")
        }
    }
    
    // https://en.wikipedia.org/wiki/CBOR#Specification_of_the_CBOR_encoding
    mutating func readPositiveInt() throws -> Int {
        // strip off the major type bits
        let shortCount = data[pos] & 0x1F
        
        switch (shortCount) {
        case 0...23: // directly encoded in the single byte
            pos += 1
            return Int(shortCount)
            
        case 24: // the count is in a following 8-bit extended count field
            if(pos + 1 > data.endIndex) {
                throw CborReadError.inputTooShort
            }
            let value = Int(data[pos + 1])
            pos += 2
            return value
            
        case 25: // the count is in a following 16-bit extended count field
            if(pos + 2 > data.endIndex) {
                throw CborReadError.inputTooShort
            }
            let value = Int(data[pos + 1]) << 8 | Int(data[pos + 2])
            pos += 3
            return value
            
        case 26: // the count is in a following 32-bit extended count field
            if(pos + 4 > data.endIndex) {
                throw CborReadError.inputTooShort
            }
            // if we write this, then the swift typechecker blows up :-(
            // return Int(data[pos+1]) << 24 | Int(data[pos+2] << 16) | Int(data[pos+3]) << 8 | Int(data[pos+4])
            
            var accumulator = 0
            var shift = 24
            for _ in 0..<4 {
                pos += 1
                accumulator |= Int(data[pos]) << shift
                shift -= 8
            }
            pos += 1
            return accumulator
            
        case 27: // the count is in a following 64-bit extended count field
            if(pos + 8 > data.endIndex) {
                throw CborReadError.inputTooShort
            }
            var accumulator = 0
            var shift = 58
            for _ in 0..<8 {
                pos += 1
                accumulator |= Int(data[pos]) << shift
                shift -= 8
            }
            pos += 1
            return accumulator
            
        default:
            throw CborReadError.malformedInput // "Wikipedia: Values 28–30 are not assigned and must not be used."
        }
    }
    
    mutating func readNegativeInt() throws -> Int {
        return try (readPositiveInt() + 1) * -1
    }
    
    mutating func readByteString() throws -> Data {
        let len = try readPositiveInt()
        if(pos+len > data.endIndex) {
            throw CborReadError.inputTooShort
        }
        let result = data.subdata(in: pos..<(pos+len))
        pos += len
        return result
    }
    
    mutating func readTextString() throws -> String {
        let len = try readPositiveInt()
        if(pos+len > data.endIndex) {
            throw CborReadError.inputTooShort
        }
        
        guard let result = String(data: data[pos..<(pos+len)], encoding: .utf8) else {
            throw CborReadError.invalidUtf8String // CBOR only encodes utf8
        }
        pos += len
        return result
    }
    
    mutating func readArray() throws -> [CborValue] {
        let len = try readPositiveInt()
        var result = [CborValue]()
        result.reserveCapacity(len)
        for _ in 0..<len {
            result.append(try read())
        }
        return result
    }
    
    mutating func readMap() throws -> [CborValue: CborValue] {
        let len = try readPositiveInt()
        var result = [CborValue: CborValue]()
        result.reserveCapacity(len)
        for _ in 0..<len {
            let key = try read()
            let val = try read()
            result[key] = val
        }
        return result
    }
    
    mutating func readTagged() throws -> (Int, CborValue) {
        let tag = try readPositiveInt()
        let following = try read() // the following value
        return (tag, following)
    }
}

struct CborWriter {
    // this gets appended to as we write more and more data.
    // read .buffer to get the current stuff written so fr
    var buffer: Data = Data()
    
    mutating func write(_ value: CborValue) throws {
        try CborWriter.write(&buffer, value)
    }
    
    // just enough to verify a COSE signature, not a full CBOR writer
    private static func write(_ buffer: inout Data, _ value: CborValue) throws {
        switch value {
        case .integer(let i):
            writeInteger(&buffer, i)
        case .map(_):
            fatalError("not implemented")
            // writeMap(&buffer, m)
        case .array(let a):
            try writeArray(&buffer, a)
        case .textString(let s):
            try writeTextString(&buffer, s)
        case .byteString(let b):
            writeByteString(&buffer, b)
        case .tagged(tag: _, value: _):
            fatalError("not implemented")
            // writeCount(&buffer, tag)
        }
    }
    
    private static func writeInteger(_ buffer: inout Data, _ i: Int) {
        let countValue = (i < 0) ? (i * -1) - 1 : i
        writeHeader(&buffer, majorType: i >= 0 ? .positiveInt : .negativeInt, countValue: countValue)
    }
    
    private static func writeTextString(_ buffer: inout Data, _ s: String) throws {
        guard let utf8Bytes = s.data(using: .utf8) else {  // CBOR is always utf8
            throw CborWriteError.nonUtf8textString
        }
        writeHeader(&buffer, majorType: .textString, countValue: utf8Bytes.count)
        buffer.append(contentsOf: utf8Bytes)
    }
    
    private static func writeByteString(_ buffer: inout Data, _ d: Data) {
        writeHeader(&buffer, majorType: .byteString, countValue: d.count)
        buffer.append(contentsOf: d)
    }
    
    private static func writeArray(_ buffer: inout Data, _ array: [CborValue]) throws {
        writeHeader(&buffer, majorType: .array, countValue: array.count)
        for item in array {
            try write(&buffer, item)
        }
    }
    
    // returns the number of bytes that
    private static func writeHeader(_ buffer: inout Data, majorType: CborMajorType, countValue: Int) {
        let mtBits: UInt8 = majorType.rawValue << 5
        switch countValue {
        case 0..<24:
            // tiny encoding, the count goes inline and that's all
            buffer.append(mtBits | UInt8(countValue))
            
        case 24..<Int(UInt8.max):
            // 8-bit length follows in a single trailing byte
            buffer.append(mtBits | 24)
            buffer.append(UInt8(countValue))
                
        case Int(UInt8.max)..<Int(UInt16.max):
            // 16-bit length follows in two trailing bytes
            buffer.append(mtBits | 25)
            buffer.append(UInt8((countValue >> 8) & 0xff))
            buffer.append(UInt8(countValue & 0xff))
            
        case Int(UInt16.max)..<Int(UInt32.max):
            // 32-bit length follows in four trailing bytes
            buffer.append(mtBits | 26)
            buffer.append(UInt8((countValue >> 24) & 0xff))
            buffer.append(UInt8((countValue >> 16) & 0xff))
            buffer.append(UInt8((countValue >> 8) & 0xff))
            buffer.append(UInt8(countValue & 0xff))
            
        default:
            // 64-bit length follows in eight trailing bytes
            buffer.append(mtBits | 27)
            buffer.append(UInt8((countValue >> 32) & 0xff))
            buffer.append(UInt8((countValue >> 56) & 0xff))
            buffer.append(UInt8((countValue >> 48) & 0xff))
            buffer.append(UInt8((countValue >> 40) & 0xff))
            buffer.append(UInt8((countValue >> 32) & 0xff))
            buffer.append(UInt8((countValue >> 24) & 0xff))
            buffer.append(UInt8((countValue >> 16) & 0xff))
            buffer.append(UInt8((countValue >> 8) & 0xff))
            buffer.append(UInt8(countValue & 0xff))
        }
    }
}
