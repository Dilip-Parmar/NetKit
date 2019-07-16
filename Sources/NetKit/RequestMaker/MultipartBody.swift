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
private struct Delimiter {
    static let CRLF = "\r\n"
}

@available (iOS 12.0, OSX 10.14, *)
internal extension NetKit {
    /// To prepare request body to send as multipart
    /// - Parameter fileName: filename to be encoded as multipart
    /// - Parameter mimeType: mime type of given type
    /// - Parameter rawData: given file raw data
    @available (iOS 12.0, OSX 10.14, *)
    static func prepareBody(fileName: String,
                            mimeType: String,
                            rawData: Data) -> (requestBodyData: Data, contentType: String, contentDisposition: String) {
        let splitName = fileName.split(separator: ".")
        let name = String(describing: splitName.first)
        let boundry = "\(NSUUID().uuidString)"
        let contentType = "multipart/form-data; boundary=" + boundry
        let boundaryStart = "--\(boundry)\(Delimiter.CRLF)"
        var cntntDispostion = "Content-Disposition: form-data; name=\"\(name)\";"
        cntntDispostion += "filename=\"\(fileName)\"\(Delimiter.CRLF)"
        let contentTypeString = "Content-Type: \(mimeType)\(Delimiter.CRLF)\(Delimiter.CRLF)"
        let boundaryEnd = "\(Delimiter.CRLF)--\(boundry)--\(Delimiter.CRLF)"
        var requestBodyData = Data()
        if let data = boundaryStart.data(using: .utf8) {
            requestBodyData.append(data)
        }
        if let data = cntntDispostion.data(using: .utf8) {
            requestBodyData.append(data)
        }
        if let data = contentTypeString.data(using: .utf8) {
            requestBodyData.append(data)
        }
        requestBodyData.append(rawData)
        if let data = boundaryEnd.data(using: .utf8) {
            requestBodyData.append(data)
        }
        return (requestBodyData, contentType, cntntDispostion)
    }
}
