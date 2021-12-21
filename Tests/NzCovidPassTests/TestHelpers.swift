//
// Copyright Gallagher Group Ltd 2021
//
import Foundation

extension Data {
    // from https://stackoverflow.com/a/46663290/234
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    func hexString() -> String {
        var output:String = ""
        output.reserveCapacity(self.count * 2)
        for byte in self {
            let s = String(byte, radix:16)
            if s.count == 1 {
                output += "0"
            }
            output += s
        }
        return output
    }
}

extension Date {
    init?(iso8601 string: String) {
        let formatter = ISO8601DateFormatter()
        if let parsed = formatter.date(from: string) {
            self = parsed
        } else {
            return nil
        }
    }
}
