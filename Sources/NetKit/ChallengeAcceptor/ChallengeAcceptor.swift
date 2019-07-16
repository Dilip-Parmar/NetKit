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
final class ChallengeAcceptor {
    
    /// To handle delegate event of authentication for given task
    /// - Parameter challenge: Authentication challenge
    /// - Parameter completion: An instance of ChallengeCompletion
    /// - Parameter requestContainer: An instance of RequestContainer
    @available (iOS 12.0, OSX 10.14, *)
    func handleAuthChallenge(requestContainer: RequestContainer?,
                             challenge: URLAuthenticationChallenge,
                             completion: @escaping ChallengeCompletion) {
        guard let authDetail = requestContainer?.authDetail else {
            completion(.performDefaultHandling, nil)
            return
        }
        let authTypeTuple = (authDetail.authType, challenge.protectionSpace.authenticationMethod)
        switch authTypeTuple {
        case (.HTTPBasic, NSURLAuthenticationMethodHTTPBasic):
            self.handleAuth(didReceive: challenge,
                            authDetail: authDetail,
                            completion: completion)
        case (.HTTPDigest, NSURLAuthenticationMethodHTTPDigest):
            self.handleAuth(didReceive: challenge,
                            authDetail: authDetail,
                            completion: completion)
        case (.serverTrust, NSURLAuthenticationMethodServerTrust):
            self.handleServerTrust(didReceive: challenge,
                                   authDetail: authDetail,
                                   completionHandler: completion)
        default:
            completion(.cancelAuthenticationChallenge, nil)
        }
    }
    /// To handle authentication challenge based on user input
    /// - Parameter challenge: Authentication challenge
    /// - Parameter authDetail: User provided authentication details
    /// - Parameter completion: An instance of ChallengeCompletion
    @available (iOS 12.0, OSX 10.14, *)
    func handleAuth(didReceive challenge: URLAuthenticationChallenge,
                    authDetail: AuthDetail?,
                    completion: @escaping ChallengeCompletion) {
        if let authDetail = authDetail,
            authDetail.shouldValidateHost,
            challenge.protectionSpace.host != authDetail.host {
            completion(.cancelAuthenticationChallenge, nil)
        }
        if challenge.previousFailureCount < 3 {
            completion(.useCredential, authDetail?.userCredential)
        } else {
            completion(.cancelAuthenticationChallenge, nil)
        }
    }
    /// To handle server-trust authentication challenge
    /// - Parameter challenge: Authentication challenge
    /// - Parameter authDetail: User provided authentication details
    /// - Parameter completionHandler: An instance of ChallengeCompletion
    @available (iOS 12.0, OSX 10.14, *)
    func handleServerTrust(didReceive challenge: URLAuthenticationChallenge,
                           authDetail: AuthDetail?,
                           completionHandler: @escaping ChallengeCompletion) {
        if let authDetail = authDetail,
            authDetail.shouldValidateHost,
            challenge.protectionSpace.host != authDetail.host {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
        if let serverTrust = challenge.protectionSpace.serverTrust {
            //By default, It should be invalid
            var resultType = SecTrustResultType.invalid
            let evaluationStatus = SecTrustEvaluate(serverTrust, &resultType)
            // Evaluate server certificate. If found invalid, Exit
            if errSecSuccess == evaluationStatus {
                //Index 0  ontains the server's SSL certificate data.
                if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                    let serverCertificateData = SecCertificateCopyData(serverCertificate)
                    let serverCertificateBytes = CFDataGetBytePtr(serverCertificateData)
                    let serverCertificateDataSize = CFDataGetLength(serverCertificateData)
                    let serverCertificate = NSData(bytes: serverCertificateBytes, length: serverCertificateDataSize)
                    let certificateFileName = Bundle.main.path(forResource: authDetail?.certificateFileName,
                                                               ofType: "cer")
                    if let certificateFileName = certificateFileName {
                        if let clientCertificate = NSData(contentsOfFile: certificateFileName) {
                            // The pinnning check
                            if serverCertificate.isEqual(to: clientCertificate as Data) {
                                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                                return
                            }
                        }
                    }
                }
            }
        }
        // Pinning failed
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
