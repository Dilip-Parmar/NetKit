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
/// HTTP Method
///
/// - GET: GET method
/// - HEAD: HEAD method
/// - POST: POST method
/// - PUT: PUT method
/// - DELETE: DELETE method
/// - CONNECT: CONNECT method
/// - OPTIONS: OPTIONS method
/// - PATCH: PATCH method
@available (iOS 12.0, OSX 10.14, *)
public enum HTTPMethod: String {
    ///The GET method requests a representation of the specified resource. Requests using GET should only retrieve data.
    case GET
    ///The HEAD method asks for a response identical to that of a GET request, but without the response body.
    case HEAD
    ///The POST method is used to submit an entity to the specified resource,
    ///often causing a change in state or side effects on the server.
    ///Used to modify and update a resource.
    case POST
    ///The PUT method replaces all current representations of the target resource with the request payload.
    ///Used to create a resource, or overwrite it available at the given URL.
    case PUT
    ///The DELETE method deletes the specified resource.
    case DELETE
    ///The CONNECT method establishes a tunnel to the server identified by the target resource.
    ///A CONNECT request urges your proxy to establish an HTTP tunnel to the remote end-point.
    ///With SSL(HTTPS), only the two remote end-points understand the requests, and
    ///the proxy cannot decipher them. Hence, all it does is open that tunnel using CONNECT,
    ///and lets the two end-points (webserver and client) talk to each other directly.
    case CONNECT
    ///The OPTIONS method is used to describe the communication options for the target resource.
    ///This method allows the client to determine the options and/or requirements
    ///associated with a resource, or the capabilities of a server,
    ///without implying a resource action or initiating a resource retrieval.
    case OPTIONS
    ///The PATCH method is used to apply partial modifications to a resource.
    ///The PATCH HTTP methods can be used to update partial resources.
    ///For instance, when you only need to update one field of the resource.
    case PATCH
}

@available (iOS 12.0, OSX 10.14, *)
public enum URLEncoding: String {
    //Generally for these methods - GET, HEAD, DELETE, CONNECT, OPTIONS
    case `default`
    case percentEncoded
    //Always for POST/PUT METHOD
    case xWWWFormURLEncoded = "application/x-www-form-urlencoded"
}
@available (iOS 12.0, OSX 10.14, *)
public enum BodyEncoding: String {
    case JSON
    case xWWWFormURLEncoded = "application/x-www-form-urlencoded"
}

@available (iOS 12.0, OSX 10.14, *)
public enum BodyEncryption {
    //Encryption/Decryption Algorithm
    case AES256 (key: String, initialVector: String)
}

@available (iOS 12.0, OSX 10.14, *)
extension CharacterSet {
    public static let nkURLQueryAllowed: CharacterSet = {
        //https://en.wikipedia.org/wiki/Percent-encoding
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()
}

@available (iOS 12.0, OSX 10.14, *)
/// HTTPRequest requirement
public protocol RequestProtocol {
    var baseURL: String { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var requestHeaders: [String: String]? { get }
    var queryParams: [String: String]? { get }
    var queryParamsEncoding: URLEncoding? { get }
    var bodyEncoding: BodyEncoding? { get }
    var requestBody: [String: Any]? { get }
    var cachePolicy: URLRequest.CachePolicy? { get }
    var timeoutInterval: TimeInterval? { get }
    var networkServiceType: URLRequest.NetworkServiceType { get }
    var encryption: BodyEncryption? { get }
}

@available (iOS 12.0, OSX 10.14, *)
public extension RequestProtocol {
    
    @available (iOS 12.0, OSX 10.14, *)
    func prepare() -> URLRequest? {
        guard let url = URL.init(string: self.baseURL + self.path) else { return nil }
        //prepare a url request
        var urlRequest = URLRequest(url: url)
        //set method for request
        urlRequest.httpMethod = self.method.rawValue
        //set requestHeaders for request
        urlRequest.allHTTPHeaderFields = self.requestHeaders
        //set query parameters for request
        if let queryParams = self.queryParams, queryParams.count > 0,
            let queryParamsEncoding = self.queryParamsEncoding {
            self.setQueryTo(urlRequest: &urlRequest,
                            urlEncoding: queryParamsEncoding,
                            queryParams: queryParams)
        }
        //set body for request
        if let requestBody = self.requestBody {
            ///Encoding
            if let bodyEncoding = self.bodyEncoding {
                urlRequest.httpBody = self.encodedBody(bodyEncoding: bodyEncoding,
                                                       requestBody: requestBody)
            } else {
                urlRequest.httpBody = self.encodedBody(bodyEncoding: .JSON,
                                                       requestBody: requestBody)
            }
            ///Encryption
            if let encryption = self.encryption {
                if let requestBody = urlRequest.httpBody {
                    urlRequest.httpBody = self.encryptedBody(encryption: encryption,
                                                             requestBody: requestBody)
                }
            }
        }
        urlRequest.cachePolicy = self.cachePolicy ?? URLRequest.CachePolicy.useProtocolCachePolicy
        urlRequest.timeoutInterval = self.timeoutInterval ?? 60
        urlRequest.networkServiceType = self.networkServiceType
        return urlRequest
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    private func setQueryTo(urlRequest: inout URLRequest,
                            urlEncoding: URLEncoding,
                            queryParams: [String: String]) {
        guard let url = urlRequest.url else {
            return
        }
        var urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: false)
        switch urlEncoding {
        case .default:
            urlComponents?.queryItems = [URLQueryItem]()
            for (name, value) in queryParams {
                urlComponents?.queryItems?.append(URLQueryItem.init(name: name, value: value))
            }
            urlRequest.url = urlComponents?.url
        case .percentEncoded:
            urlComponents?.percentEncodedQueryItems = [URLQueryItem]()
            for (name, value) in queryParams {
                let encodedName = name.addingPercentEncoding(withAllowedCharacters: .nkURLQueryAllowed) ?? name
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .nkURLQueryAllowed) ?? value
                let queryItem = URLQueryItem.init(name: encodedName, value: encodedValue)
                urlComponents?.percentEncodedQueryItems?.append(queryItem)
            }
            urlRequest.url = urlComponents?.url
            ///Applicable for PUT and POST method.
            ///When queryParamsEncoding is xWWWFormURLEncoded,
        ///All query parameters are sent inside body.
        case .xWWWFormURLEncoded:
            if let queryParamsData = self.queryParams?.urlEncodedQueryParams().data(using: .utf8) {
                urlRequest.httpBody = queryParamsData
                urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
        }
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    private func encodedBody(bodyEncoding: BodyEncoding,
                             requestBody: [String: Any]) -> Data? {
        switch bodyEncoding {
        case .JSON:
            do {
                return try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                return nil
            }
        case .xWWWFormURLEncoded:
            do {
                return try requestBody.urlEncodedBody()
            } catch {
                return nil
            }
        }
    }

    @available (iOS 12.0, OSX 10.14, *)
    private func encryptedBody(encryption: BodyEncryption,
                               requestBody: Data) -> Data? {
        switch encryption {
        case .AES256(let key, let initialVector):
            do {
                let aes256 = try AES256.init(key: key, initialVector: initialVector)
                return aes256?.encrypt(messageData: requestBody)
            } catch {
                return nil
            }
        }
    }
}
