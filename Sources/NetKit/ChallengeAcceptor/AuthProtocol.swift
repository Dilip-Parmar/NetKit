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

/// Request Authentication Type
@available (iOS 12.0, OSX 10.14, *)
public enum AuthType {
    //All are credential based authentication
    case HTTPBasic
    case HTTPDigest
    case NTLM
    case negotiate
    case clientCertificate
    
    //Certificate based authentication
    case serverTrust
}

/// Protocol for Authentication
@available (iOS 12.0, OSX 10.14, *)
public protocol AuthProtocol {
    var authType: AuthType { get }
    var shouldValidateHost: Bool { get }
    var host: String? { get }
    var userCredential: URLCredential? { get }
    var sslCertFileNameWidExt: String? { get }
}
