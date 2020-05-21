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

internal class Logger {
    
    // MARK: - Properties
    private var loggerQueue: DispatchQueue?
    private var fileName: String?
    
    // MARK: - Initializer
    init(fileName: String?) {
        self.fileName = fileName
        self.loggerQueue = DispatchQueue.init(label: "NetKit\(UUID())", qos: .background)
    }
    private lazy var fileHandle: FileHandle? = {
        var fileHandle: FileHandle?
        let fileManager = FileManager.default
        guard let fileName = self.fileName else {
            return nil
        }
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: filePath)
        if let fileFullURL = url.appendingPathComponent(fileName) {
            if !fileManager.fileExists(atPath: fileFullURL.path, isDirectory: nil) {
                fileManager.createFile(atPath: fileFullURL.path, contents: nil, attributes: nil)
            }
            fileHandle = try? FileHandle(forWritingTo: fileFullURL)
        } else {
            debugPrint("FILE PATH NOT AVAILABLE")
        }
        return fileHandle
    }()
    // MARK: - De-Initializer
    deinit {
        fileHandle?.closeFile()
        self.loggerQueue = nil
        self.fileName = nil
        self.fileHandle = nil
    }
    
    // MARK: - Logging
    func log(request: URLRequest?, response: URLResponse?, error: Error?, responseData: Any?) {
        self.loggerQueue?.async {
            //Write to file
            self.writeToFile(request: request, response: response, error: error, responseData: responseData)
            
            //Continue to print logs in console
            debugPrint("", terminator: "\n\n")
            debugPrint("--------------- Request Log Starts ---------------", terminator: "\n\n")
            debugPrint("--------------- Request Headers ---------------", terminator: "\n\n")
            if let request = request, let allHTTPHeaderFields = request.allHTTPHeaderFields {
                if let url = request.url {
                    debugPrint("Request URL - \(String(describing: url))", terminator: "\n")
                }
                for (headerKey, headerValue) in allHTTPHeaderFields {
                    debugPrint("\(headerKey) - \(headerValue)", terminator: "\n")
                }
            }
            debugPrint("", terminator: "\n\n")
            debugPrint("--------------- Response Headers ---------------", terminator: "\n\n")
            if let response = response as? HTTPURLResponse {
                if let url = response.url {
                    debugPrint("Response URL - \(String(describing: url))", terminator: "\n")
                }
                for (headerKey, headerValue) in response.allHeaderFields {
                    debugPrint("\(headerKey) - \(headerValue)", terminator: "\n")
                }
                debugPrint("Status Code - \(String(describing: response.statusCode))", terminator: "\n\n")
                if let downloadURL = responseData as? URL {
                    debugPrint("Downloaded file URL - \(String(describing: downloadURL))", terminator: "\n")
                } else if let data = responseData as? Data,
                    let jsonStr = data.printableJSON {
                    debugPrint("Response JSON -")
                    debugPrint(jsonStr)
                }
            }
            if let error = error, let errorFound = error as NSError? {
                debugPrint("--------------- Error ---------------", terminator: "\n\n")
                debugPrint("Error Code - \(errorFound.code)", terminator: "\n")
                debugPrint("Error Domain - \(errorFound.domain)", terminator: "\n")
                debugPrint("Error UserInfo - \(errorFound.userInfo)", terminator: "\n\n")
            }
            debugPrint("--------------- Request Log Ends ---------------", terminator: "\n\n")
        }
    }
    
    // MARK: - Write to file
    // swiftlint:disable cyclomatic_complexity
    private func writeToFile(request: URLRequest?, response: URLResponse?, error: Error?, responseData: Any?) {
        if self.fileName != nil {
            self.fileHandle?.seekToEndOfFile()
            var logStr: String = "\n\n"
            logStr += "--------------- Request Log Starts ---------------\n\n"
            logStr += "--------------- Request Headers ---------------\n\n"
            if let request = request, let allHTTPHeaderFields = request.allHTTPHeaderFields {
                if let url = request.url {
                    logStr += "Request URL - \(String(describing: url))\n"
                }
                for (headerKey, headerValue) in allHTTPHeaderFields {
                    logStr += "\(headerKey) - \(headerValue)\n"
                }
            }
            logStr += "\n\n--------------- Response Headers ---------------\n\n"
            if let response = response as? HTTPURLResponse {
                if let url = response.url {
                    logStr += "Response URL - \(String(describing: url))\n"
                }
                for (headerKey, headerValue) in response.allHeaderFields {
                    logStr += "\(headerKey) - \(headerValue)\n"
                }
                logStr += "Status Code - \(response.statusCode)\n"
                if let downloadURL = responseData as? URL {
                    logStr += "Downloaded file URL - \(String(describing: downloadURL))"
                } else if let data = responseData as? Data,
                    let jsonStr = data.printableJSON {
                    logStr += "Response JSON -"
                    logStr += jsonStr as String
                }
            }
            if let error = error, let errorFound = error as NSError? {
                logStr += "\n\n--------------- Error ---------------\n"
                logStr += "Error Code - \(errorFound.code)\n"
                logStr += "Error Domain - \(errorFound.domain)\n"
                logStr += "Error UserInfo - \(errorFound.userInfo)\n\n"
            }
            logStr += "\n\n--------------- Request Log Ends ---------------\n\n"
            if let logData = logStr.data(using: .utf8, allowLossyConversion: false) {
                fileHandle?.write(logData)
            }
        }
    }
}

extension Data {
    var printableJSON: NSString? {
        var jsonStr: NSString?
        if let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []) {
            if let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]) {
                jsonStr = NSString(data: data,
                encoding: String.Encoding.utf8.rawValue)
            }
        }
        return jsonStr
    }
}
