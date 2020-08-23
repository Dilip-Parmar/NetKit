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
class TaskFinalizer: TaskExecutorToFinalizer {
    
    private weak var dispatcher: TaskDispatcher?
    private var logger: Logger?
    private var statusCodesForRetry: [Int]?
    
    init(dispatcher: TaskDispatcher?, statusCodesForRetry: [Int]?) {
        self.dispatcher = dispatcher
        self.logger = Logger.init(fileName: "NetKitLogs.txt")
        self.statusCodesForRetry = statusCodesForRetry
    }
    deinit {
        self.dispatcher = nil
        self.logger = nil
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func finalizeTask(task: URLSessionTask, error: Error?, requestContainer: RequestContainer?) {
        
        if let requestContainer = requestContainer {
            let tuple = (task, requestContainer.requestType)
            switch tuple {
            case (task as? URLSessionDataTask, .data):
                if self.shouldHandleFailedTask(task: task,
                                               requestContainer: requestContainer,
                                               error: error as NSError?) {
                    self.handleFailedTask(requestContainer: requestContainer)
                } else {
                    self.handleDataTask(task: task, error: error, requestContainer: requestContainer)
                    self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
                    self.logger?.log(request: requestContainer.request,
                                     response: task.response,
                                     error: error,
                                     responseData: requestContainer.receivedData)
                }
            case (task as? URLSessionDownloadTask, .download):
                if self.shouldHandleFailedTask(task: task,
                                               requestContainer: requestContainer,
                                               error: error as NSError?) {
                    self.handleFailedTask(requestContainer: requestContainer)
                } else {
                    self.handleDownloadTask(task: task, error: error, requestContainer: requestContainer)
                    self.logger?.log(request: requestContainer.request,
                                     response: task.response,
                                     error: error,
                                     responseData: requestContainer.downloadFileURL)
                }
            case (task as? URLSessionUploadTask, .upload):
                if self.shouldHandleFailedTask(task: task,
                                               requestContainer: requestContainer,
                                               error: error as NSError?) {
                    self.handleFailedTask(requestContainer: requestContainer)
                } else {
                    self.handleUploadTask(task: task, error: error, requestContainer: requestContainer)
                    self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
                    self.logger?.log(request: requestContainer.request,
                                     response: task.response,
                                     error: error,
                                     responseData: requestContainer.receivedData)
                }
            default:
                break
            }
        }
    }
    
    func shouldHandleFailedTask(task: URLSessionTask, requestContainer: RequestContainer, error: NSError?) -> Bool {
        var shouldRetry: Bool = false
        //Give us HTTP status codes to rety otherwise maxRetry parameter will be ignored
        if let statusCodesForRetry = self.statusCodesForRetry, statusCodesForRetry.count > 0 {
            if let error = error, statusCodesForRetry.contains(error.code) {
                shouldRetry = true
            } else if let response = task.response as? HTTPURLResponse,
                statusCodesForRetry.contains(response.statusCode) {
                shouldRetry = true
            }
        }
        //Let's check, are we left with more retry ?
        return shouldRetry && requestContainer.maxRetry > 0
    }
    
    private func handleDataTask(task: URLSessionTask, error: Error?, requestContainer: RequestContainer) {
        switch requestContainer.currentState {
        case .finished:
            if let response = task.response as? HTTPURLResponse {
                if 200...299 ~= response.statusCode {
                    requestContainer.dataCompletion?(response, .success(requestContainer.receivedData))
                } else {
                    let requestError = RequestError.errorFrom(code: response.statusCode)
                    requestContainer.dataCompletion?(response, .failure(requestError))
                }
            }
        case .failed:
            if let error = error as NSError? {
                let requestError = RequestError.errorFrom(code: error.code)
                requestContainer.dataCompletion?(task.response as? HTTPURLResponse, .failure(requestError))
            }
        default:
            requestContainer.dataCompletion?(task.response as? HTTPURLResponse, .failure(.clientError))
        }
    }
    
    private func handleDownloadTask(task: URLSessionTask, error: Error?, requestContainer: RequestContainer) {
        switch requestContainer.currentState {
        case .finished:
            if let response = task.response as? HTTPURLResponse {
                if 200...299 ~= response.statusCode {
                    requestContainer.downloadCompletion?(response, .success(requestContainer.downloadFileURL))
                } else {
                    let requestError = RequestError.errorFrom(code: response.statusCode)
                    requestContainer.downloadCompletion?(response, .failure(requestError))
                }
                self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
            }
        case .failed:
            var requestError = RequestError.unknown
            if let error = error as NSError? {
                if error.code == -999,
                    let resumeData = error.userInfo["NSURLSessionDownloadTaskResumeData"] as? Data {
                    requestContainer.resumeData = resumeData
                    requestContainer.currentState = .paused
                } else {
                    requestError = RequestError.errorFrom(code: error.code)
                    requestContainer.downloadCompletion?(task.response as? HTTPURLResponse, .failure(requestError))
                    self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
                }
            }
        default:
            requestContainer.downloadCompletion?(task.response as? HTTPURLResponse, .failure(.clientError))
            self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
        }
    }
    
    private func handleUploadTask(task: URLSessionTask, error: Error?, requestContainer: RequestContainer) {
        switch requestContainer.currentState {
        case .finished:
            if let response = task.response as? HTTPURLResponse {
                if 200...299 ~= response.statusCode {
                    requestContainer.uploadCompletion?(response, .success(requestContainer.receivedData))
                } else {
                    let requestError = RequestError.errorFrom(code: response.statusCode)
                    requestContainer.uploadCompletion?(response, .failure(requestError))
                }
            }
        case .failed:
            if let error = error as NSError? {
                let requestError = RequestError.errorFrom(code: error.code)
                requestContainer.uploadCompletion?(task.response as? HTTPURLResponse, .failure(requestError))
            }
        default:
            requestContainer.uploadCompletion?(task.response as? HTTPURLResponse, .failure(.clientError))
        }
    }
    
    func finalizePausedTask(error: NSError, requestContainer: RequestContainer?) {
        if let requestContainer = requestContainer {
            let requestError = RequestError.errorFrom(code: error.code)
            switch requestContainer.requestType {
            case .download:
                requestContainer.downloadCompletion?(nil, .failure(requestError))
            case .upload:
                requestContainer.uploadCompletion?(nil, .failure(requestError))
            default:
                break
            }
            self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
        }
    }
    
    func handleFailedTask(requestContainer: RequestContainer?) {
        if let requestContainer = requestContainer {
            //Let's reset common properties
            requestContainer.maxRetry -= 1
            requestContainer.currentState = .submitted
            requestContainer.receivedData = nil
            requestContainer.receivedData = Data()
            requestContainer.downloadFileURL = nil
            self.dispatcher?.dispatchFailedTask(requestContainer: requestContainer)
            requestContainer.retryInSeconds += 2.0 //Let's increment by 2 seconds
            print("Next retry in seconds \(requestContainer.retryInSeconds)")
        }
    }
}
