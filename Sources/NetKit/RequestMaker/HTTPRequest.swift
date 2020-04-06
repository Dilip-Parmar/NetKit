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
open class HTTPRequest: RequestProtocol {

    public var baseURL: String
    public var method: HTTPMethod
    public var path: String
    public var queryParamsEncoding: URLEncoding?
    public var requestBody: [String: Any]?
    public var bodyEncoding: BodyEncoding?
    public var requestHeaders: [String: String]?
    public var queryParams: [String: String]?
    public var cachePolicy: URLRequest.CachePolicy?
    public var timeoutInterval: TimeInterval?
    public var networkServiceType: URLRequest.NetworkServiceType
    public var encryption: BodyEncryption?
    
    public init(baseURL: String,
                path: String,
                method: HTTPMethod,
                requestBody: [String: Any]?,
                bodyEncoding: BodyEncoding?,
                requestHeaders: [String: String]?,
                queryParams: [String: String]?,
                queryParamsEncoding: URLEncoding?,
                cachePolicy: URLRequest.CachePolicy?,
                timeoutInterval: TimeInterval?,
                networkServiceType: URLRequest.NetworkServiceType,
                bodyEncryption: BodyEncryption?) {
        
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.requestBody = requestBody
        self.requestHeaders = requestHeaders
        self.queryParams = queryParams
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.queryParamsEncoding = queryParamsEncoding
        self.networkServiceType = networkServiceType
        self.bodyEncoding = bodyEncoding
        self.encryption = bodyEncryption
    }
}
