//MIT License
//
//Copyright (c) 2019 Dilip-Parmar
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
import Foundation
import CommonCrypto

@available (iOS 12.0, OSX 10.14, *)
/// AES256 Encryption class
public struct AES256 {
    // MARK: Private
    //256 bit AES key size.
    private let key: Data
    //Initial Vector
    //AES block size (currently, only 128-bit blocks are supported).
    private let initialVector: Data
    // MARK: - Initializer
    /// Initialize AES256 Encryptor
    ///
    /// - Parameters:
    ///   - key: 256 bit AES key size.
    ///   - iv: AES block size (currently, only 128-bit blocks are supported).
    /// - Throws: throws when key size less then 256 bits and iv less than 128 bits
    public init?(key: String, initialVector: String) throws {
        guard key.count == kCCKeySizeAES256, let keyData = key.data(using: .utf8) else {
            throw RequestError.clientError
        }
        guard initialVector.count == kCCBlockSizeAES128, let ivData = initialVector.data(using: .utf8) else {
            throw RequestError.clientError
        }
        self.key = keyData
        self.initialVector  = ivData
    }
    // MARK: Public
    public func encrypt(messageData: Data) -> Data? {
        return crypt(data: messageData, option: CCOperation(kCCEncrypt))
    }
    /// To decrypt request body
    /// - Parameter data: request body
    public func decrypt(data: Data?) -> Data? {
        guard let decryptedData = crypt(data: data, option: CCOperation(kCCDecrypt)) else { return nil }
        return decryptedData
    }
    /// To encrypt/decrypt request body
    /// - Parameter data: request body
    /// - Parameter option: kCCEncrypt/kCCDecrypt type
    func crypt(data: Data?, option: CCOperation) -> Data? {
        guard let data = data else { return nil }
        switch Int(option) {
        case kCCEncrypt:
            let outputLength = data.count + kCCBlockSizeAES128
            var outputBuffer = [UInt8](repeating: 0, count: outputLength)
            var numBytesEncrypted = 0
            let status = CCCrypt(option,
                                 CCAlgorithm(kCCAlgorithmAES),
                                 CCOptions(kCCOptionPKCS7Padding),
                                 Array(key),
                                 kCCKeySizeAES256,
                                 Array(initialVector),
                                 Array(data),
                                 data.count,
                                 &outputBuffer, outputLength, &numBytesEncrypted)
            guard status == kCCSuccess else { return nil }
            let outputBytes = initialVector + outputBuffer.prefix(numBytesEncrypted)
            return Data(outputBytes)
            
        case kCCDecrypt:
            let initialVector = data.prefix(kCCBlockSizeAES128)
            let cipherTextBytes = data.suffix(from: kCCBlockSizeAES128)
            let cipherTextLength = cipherTextBytes.count
            var outputBuffer = [UInt8](repeating: 0,
                                       count: cipherTextLength)
            var numBytesDecrypted = 0
            let status = CCCrypt(CCOperation(kCCDecrypt),
                                 CCAlgorithm(kCCAlgorithmAES),
                                 CCOptions(kCCOptionPKCS7Padding),
                                 Array(key),
                                 kCCKeySizeAES256,
                                 Array(initialVector),
                                 Array(cipherTextBytes),
                                 cipherTextLength,
                                 &outputBuffer,
                                 cipherTextLength, &numBytesDecrypted)
            guard status == kCCSuccess else { return nil }
            let outputBytes = outputBuffer.prefix(numBytesDecrypted)
            return Data(outputBytes)
        default:
            return nil
        }
    }
}
