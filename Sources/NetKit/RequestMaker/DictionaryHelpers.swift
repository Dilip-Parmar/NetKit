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

@available (iOS 12.0, OSX 10.14, *)
extension Dictionary where Key == String, Value == String {
    /// To encode Query parameters as URLEncoded
    func urlEncodedQueryParams() -> String {
        let pairs = reduce([]) { current, keyValPair -> [String] in
            if let encodedVal = "\(keyValPair.value)".addingPercentEncoding(withAllowedCharacters: .nmURLQueryAllowed) {
                return current + ["\(keyValPair.key)=\(encodedVal)"]
            }
            return current
        }
        return pairs.joined(separator: "&")
    }
}

@available (iOS 12.0, OSX 10.14, *)
extension Dictionary where Key == String, Value == Any {
    /// To encode request body as URLEncoded
    func urlEncodedBody() throws -> Data {
        var bodyStr = [String]()
        for(key, value) in self {
            bodyStr.append(key + "=\(value)")
        }
        let output = bodyStr.map { String($0) }.joined(separator: "&")
        if let bodyData = output.data(using: .utf8) {
            return bodyData
        } else {
            throw RequestError.clientError
        }
    }
}
