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
    func log(request: URLRequest?, response: URLResponse?, error: Error?) {
        self.loggerQueue?.async {
            //Write to file
            self.writeToFile(request: request, response: response, error: error)
            
            //Continue to print logs in console
            debugPrint("\n\n--------------- Request Log Starts ---------------\n")
            debugPrint("--------------- Request Headers ---------------\n")
            if let request = request, let allHTTPHeaderFields = request.allHTTPHeaderFields {
                for (headerKey, headerValue) in allHTTPHeaderFields {
                    debugPrint("\(headerKey) - \(headerValue)\n")
                }
            }
            debugPrint("--------------- Response Headers ---------------\n")
            if let response = response as? HTTPURLResponse {
                for (headerKey, headerValue) in response.allHeaderFields {
                    debugPrint("\(headerKey) - \(headerValue)\n")
                }
            }
            if let error = error, let errorFound = error as NSError? {
                debugPrint("--------------- Error ---------------\n")
                debugPrint("Error Code - \(errorFound.code)\n")
                debugPrint("Error Domain - \(errorFound.domain)\n")
                debugPrint("Error UserInfo - \(errorFound.userInfo)\n")
            }
            debugPrint("--------------- Request Log Ends ---------------\n")
        }
    }
    
    // MARK: - Write to file
    private func writeToFile(request: URLRequest?, response: URLResponse?, error: Error?) {
        if self.fileName != nil {
            self.fileHandle?.seekToEndOfFile()
            var logStr: String = "\n\n"
            logStr += "--------------- Request Log Starts ---------------\n"
            logStr += "--------------- Request Headers ---------------\n"
            if let request = request, let allHTTPHeaderFields = request.allHTTPHeaderFields {
                for (headerKey, headerValue) in allHTTPHeaderFields {
                    logStr += "\(headerKey) - \(headerValue)\n"
                }
            }
            logStr += "--------------- Response Headers ---------------\n"
            if let response = response as? HTTPURLResponse {
                for (headerKey, headerValue) in response.allHeaderFields {
                    logStr += "\(headerKey) - \(headerValue)\n"
                }
            }
            if let error = error, let errorFound = error as NSError? {
                logStr += "--------------- Error ---------------\n"
                logStr += "Error Code - \(errorFound.code)\n"
                logStr += "Error Domain - \(errorFound.domain)\n"
                logStr += "Error UserInfo - \(errorFound.userInfo)\n"
            }
            logStr += "--------------- Request Log Ends ---------------\n"
            if let logData = logStr.data(using: .utf8, allowLossyConversion: false) {
                fileHandle?.write(logData)
            }
        }
    }
}
