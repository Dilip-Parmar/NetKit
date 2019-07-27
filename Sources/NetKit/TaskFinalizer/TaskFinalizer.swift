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
    
    init(dispatcher: TaskDispatcher?) {
        self.dispatcher = dispatcher
        self.logger = Logger.init(fileName: "NetKitLogs.txt")
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
                self.handleDataTask(task: task, error: error, requestContainer: requestContainer)
                self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
                
            case (task as? URLSessionDownloadTask, .download):
                self.handleDownloadTask(task: task, error: error, requestContainer: requestContainer)
                
            case (task as? URLSessionUploadTask, .upload):
                self.handleUploadTask(task: task, error: error, requestContainer: requestContainer)
                self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
            
            default:
                break
            }
            self.logger?.log(request: task.currentRequest, response: task.response, error: error)
        }
    }
    
    private func handleDataTask(task: URLSessionTask, error: Error?, requestContainer: RequestContainer) {
        switch requestContainer.currentState {
        case .finished:
            if let response = task.response as? HTTPURLResponse {
                if 200...299 ~= response.statusCode {
                    let successBlock = DataSuccess.block(requestContainer.receivedData, response)
                    requestContainer.dataCompletion?(.success(successBlock))
                } else {
                    let requestError = RequestError.errorFrom(code: response.statusCode)
                    requestContainer.dataCompletion?(.failure(requestError))
                }
            }
        case .failed:
            if let error = error as NSError? {
                let requestError = RequestError.errorFrom(code: error.code)
                requestContainer.dataCompletion?(.failure(requestError))
            }
        default:
            requestContainer.dataCompletion?(.failure(.clientError))
        }
    }
    
    private func handleDownloadTask(task: URLSessionTask, error: Error?, requestContainer: RequestContainer) {
        switch requestContainer.currentState {
        case .finished:
            if let response = task.response as? HTTPURLResponse {
                if 200...299 ~= response.statusCode {
                    let successBlock = DownloadSuccess.block(requestContainer.downloadFileURL, response)
                    requestContainer.downloadCompletion?(.success(successBlock))
                } else {
                    let requestError = RequestError.errorFrom(code: response.statusCode)
                    requestContainer.downloadCompletion?(.failure(requestError))
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
                    requestContainer.downloadCompletion?(.failure(requestError))
                    self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
                }
            }
        default:
            requestContainer.downloadCompletion?(.failure(.clientError))
            self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
        }
    }
    
    private func handleUploadTask(task: URLSessionTask, error: Error?, requestContainer: RequestContainer) {
        switch requestContainer.currentState {
        case .finished:
            if let response = task.response as? HTTPURLResponse {
                if 200...299 ~= response.statusCode {
                    let successBlock = UploadSuccess.block(requestContainer.receivedData, response)
                    requestContainer.uploadCompletion?(.success(successBlock))
                } else {
                    let requestError = RequestError.errorFrom(code: response.statusCode)
                    requestContainer.uploadCompletion?(.failure(requestError))
                }
            }
        case .failed:
            if let error = error as NSError? {
                let requestError = RequestError.errorFrom(code: error.code)
                requestContainer.uploadCompletion?(.failure(requestError))
            }
        default:
            requestContainer.uploadCompletion?(.failure(.clientError))
        }
    }
    
    func finalizePausedTask(error: NSError, requestContainer: RequestContainer?) {
        if let requestContainer = requestContainer {
            let requestError = RequestError.errorFrom(code: error.code)
            switch requestContainer.requestType {
            case .download:
                requestContainer.downloadCompletion?(.failure(requestError))
            case .upload:
                requestContainer.uploadCompletion?(.failure(requestError))
            default:
                break
            }
            self.dispatcher?.removeFromRequestPool(requestId: requestContainer.requestId)
        }
    }
}
