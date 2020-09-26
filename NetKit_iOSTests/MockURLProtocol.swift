//
//  MockURLProtocol.swift
//  PersonalProtectionTests
//
//  Created by dparmar on 7/30/20.
//  Copyright © 2020 McAfee. All rights reserved.
//

import Foundation
import XCTest
import NetKit_iOS

enum ImageExt: String {
    case png
    case jpeg
    case jpg
}

enum ResponseType {
    case json
    case image
    case boolean
}

enum ResponseCode: Int {
    case success = 200
    case redirectionError = 300
    case clientError = 400
    case serverError = 500
}

open class MockDataProvider {
    
    static var responseType: ResponseType = .json
    static var filename: String = ""
    static var statusCode: ResponseCode = .success
    static var pathParams: String = ""
    static var httpVersion = "HTTP/2.0"
    static var responseHeaders = [String: String]()
    static var imageResponseExt: ImageExt = .jpeg
    
    static func getDataFromFile() -> Data? {
        if statusCode == ResponseCode.success && filename == "" && responseType != .boolean {
            return nil
        }
        let bundle = Bundle.init(for: self)
        
        var ext = ""
        switch MockDataProvider.responseType {
        case .image:
            ext = MockDataProvider.imageResponseExt.rawValue
        case .json:
            ext = "json"
        case .boolean:
            return Data.init()
        }
        
        if let url = bundle.url(forResource: MockDataProvider.filename, withExtension: ext) {
            return try? Data(contentsOf: url)
        }
        return nil
    }
}

enum MockDataError: Error {
    case incorrectPath
    case incorrectResponseDataFound
    case responseFileNotFound
    case responseHeadersNotFound
    case unknownError
}

class MockURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        // To check if this protocol can handle the given request.
        return true
    }
     
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Here you return the canonical version of the request but most of the time you pass the orignal one.
        return request
    }
    
    override func startLoading() {
        
        if 200...299 ~= MockDataProvider.statusCode.rawValue {
            if MockDataProvider.statusCode == ResponseCode.success && MockDataProvider.filename == "" && MockDataProvider.responseType != .boolean {
                client?.urlProtocol(self, didFailWithError: MockDataError.responseFileNotFound)
            }
            guard let data = MockDataProvider.getDataFromFile() else {
                client?.urlProtocol(self, didFailWithError: MockDataError.responseFileNotFound)
                return
            }
            if MockDataProvider.pathParams == "" {
                client?.urlProtocol(self, didFailWithError: MockDataError.incorrectPath)
                return
            }
            
            guard let requestURL = self.request.url else {
                client?.urlProtocol(self, didFailWithError: MockDataError.incorrectPath)
                return
            }
            var joinedPath = requestURL.pathComponents.joined(separator: "/").lowercased()
            joinedPath.removeFirst(); joinedPath.removeFirst()
            if joinedPath != MockDataProvider.pathParams.lowercased() {
               client?.urlProtocol(self, didFailWithError: MockDataError.incorrectPath)
                return
            }
            guard MockDataProvider.responseHeaders.isEmpty == false else {
                client?.urlProtocol(self, didFailWithError: MockDataError.responseHeadersNotFound)
                return
            }
            if let response = HTTPURLResponse(url: request.url!, statusCode: Int(MockDataProvider.statusCode.rawValue), httpVersion: MockDataProvider.httpVersion, headerFields: MockDataProvider.responseHeaders) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } else {
                client?.urlProtocol(self, didFailWithError: MockDataError.unknownError)
            }
        } else {
            client?.urlProtocol(self, didFailWithError: RequestError.errorFrom(code: MockDataProvider.statusCode.rawValue))
        }
    }
    
    override func stopLoading() {
        // This is called if the request gets canceled or completed.
    }
}
