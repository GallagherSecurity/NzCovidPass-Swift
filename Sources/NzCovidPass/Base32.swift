//
// Copyright Gallagher Group Ltd 2021
//
import Foundation

// adds Data(base32encoded: String) and data.base32EncodedString(), mirroring the base64 methods that Foundation has
extension Data {
    init?(base32encoded str: String) {
        // https://stackoverflow.com/a/7135008
        // stackoverflow thinks this is the best algorithm, so let's port it to swift.
        // the other swift libraries I found on github are not great, they make big strings and split them up and stuff like that
        if str == "" {
            self = Data()
            return
        }
        
        let input = str.trimmingCharacters(in: CharacterSet(charactersIn: "=")) //remove padding characters
        let byteCount = input.count * 5 / 8; //this must be TRUNCATED
        self = Data(count: byteCount) // fills with zeroes
        
        var curByte:UInt8 = 0
        var bitsRemaining = 8
        var mask:UInt8 = 0
        var arrayIndex = 0

        for c in input {
            guard let cValue = charToValue(c) else {
                return nil
            }

            if bitsRemaining > 5 {
                mask = cValue << (bitsRemaining - 5)
                curByte = (curByte | mask)
                bitsRemaining -= 5
            }
            else {
                mask = cValue >> (5 - bitsRemaining)
                curByte = UInt8(curByte | mask)
                self[arrayIndex] = curByte
                arrayIndex += 1
                curByte = UInt8(cValue << (3 + bitsRemaining))
                bitsRemaining += 3
            }
        }

        //if we didn't end with a full byte
        if arrayIndex != byteCount {
            self[arrayIndex] = curByte
        }
    }
    
    func base32EncodedString() -> String {
        fatalError("not implemented") // covid pass verification only requires us to read base32, not generate it
    }
}


private func charToValue(_ c: Character) -> UInt8? {
    guard let value = c.asciiValue else {
        return nil
    }
    
    //65-90 == uppercase letters
    if value < 91 && value > 64 {
        return value - 65
    }
    //50-55 == numbers 2-7
    if (value < 56 && value > 49) {
        return value - 24
    }
    //97-122 == lowercase letters
    if (value < 123 && value > 96) {
        return value - 97
    }
    // else Character is not a Base32 character
    return nil
}
