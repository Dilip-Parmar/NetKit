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
/// RequestError type
public enum RequestError: String, Error {
    case redirection, clientError, serverError
    case timedOut
    case cannotConnectToHost
    case resourceUnavailable
    case notConnectedToInternet
    case internationalRoamingOff
    case callIsActive
    case dataNotAllowed
    case userCancelled
    case canNotResumeDownload //-1000
    case unknown
}

@available (iOS 12.0, OSX 10.14, *)
public extension RequestError {
    /// To get error from given response code
    /// - Parameter code: error code
    @available (iOS 12.0, OSX 10.14, *)
    static func errorFrom(code: Int) -> RequestError {
        var error = RequestError.unknown
        switch code {
        case 300..<400:
            return RequestError.redirection
        case 400..<500:
            return RequestError.clientError
        case 500..<600:
            return RequestError.serverError
        default:
            error = otherErrorFrom(code: code)
        }
        return error
    }
    
    private static func otherErrorFrom(code: Int) -> RequestError {
        var error = RequestError.unknown
        switch code {
        case -999:
            error = RequestError.userCancelled
        case -1000:
            error = RequestError.canNotResumeDownload
        case -1001:
            error = RequestError.timedOut
        case -1004:
            error = RequestError.cannotConnectToHost
        case -1008:
            error = RequestError.resourceUnavailable
        case -1009:
            error = RequestError.notConnectedToInternet
        case -1018:
            error = RequestError.internationalRoamingOff
        case -1019:
            error = RequestError.callIsActive
        case -1020:
            error = RequestError.dataNotAllowed
        default:
            return RequestError.unknown
        }
        return error
    }
    
    /// To get user message based on given request
    @available (iOS 12.0, OSX 10.14, *)
    func getUserMessage() -> String {
        //Customize your message as per need
        var userMessage = ""
        switch self {
        case .redirection:
            userMessage = "Request doesn't seem to be proper."
        case .clientError:
            userMessage = "Request doesn't seem to be proper."
        case .serverError:
            userMessage = "Server seems to be down."
        case .unknown:
            userMessage = "System Error"
        default:
            userMessage = self.getOtherErrorMessage()
        }
        return userMessage
    }
    
    private func getOtherErrorMessage() -> String {
        var userMessage = ""
        switch self {
        case .timedOut:
            userMessage = "Request timed out."
        case .cannotConnectToHost:
            userMessage = "Server is unreachable."
        case .notConnectedToInternet:
            userMessage = "Internet is unavailable."
        case .resourceUnavailable:
            userMessage = "Resource unavailable"
        case .internationalRoamingOff:
            userMessage = "Data is not enabled while your are roaming."
        case .callIsActive:
            userMessage = "You are on call"
        case .dataNotAllowed:
            userMessage = "Your seem to be offline as data is not allowed in this device."
        case .userCancelled:
            userMessage = "User cancelled request"
        case .canNotResumeDownload:
            userMessage = "Download resume failed"
        default:
            break
        }
        return userMessage
    }
}
