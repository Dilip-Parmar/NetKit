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
class RequestMaker: ServiceToRequestMaker {
    
    private weak var dispatcher: TaskDispatcher?
    
    init(dispatcher: TaskDispatcher?) {
        self.dispatcher = dispatcher
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func prepareRequest(httpRequest: HTTPRequest,
                        authDetail: AuthDetail?,
                        dataCompletion: @escaping DataCompletion) -> RequestContainer? {
        guard let request = httpRequest.prepare() else {
            dataCompletion(.failure(RequestError.clientError))
            return nil
        }
        let requestContainer = RequestContainer.init(httpRequest: request,
                                                     authDetail: authDetail,
                                                     dataCompletion: dataCompletion)
        requestContainer.currentState = .submitted
        self.dispatcher?.dispatchTask(requestContainer: requestContainer)
        return requestContainer
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func prepareRequest(httpRequest: HTTPRequest,
                        authDetail: AuthDetail?,
                        progressBlock: ProgressBlock?,
                        downloadCompletion: @escaping DownloadCompletion) -> RequestContainer? {
        guard let request = httpRequest.prepare() else {
            downloadCompletion(.failure(RequestError.clientError))
            return nil
        }
        let requestContainer = RequestContainer.init(httpRequest: request,
                                                     authDetail: authDetail,
                                                     downloadCompletion: downloadCompletion,
                                                     progressBlock: progressBlock)
        requestContainer.currentState = .submitted
        self.dispatcher?.dispatchTask(requestContainer: requestContainer)
        return requestContainer
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func prepareRequest(httpRequest: HTTPRequest,
                        fileURL: URL,
                        authDetail: AuthDetail?,
                        progressBlock: ProgressBlock?,
                        uploadCompletion: @escaping UploadCompletion) -> RequestContainer? {
        guard let request = httpRequest.prepare() else {
            uploadCompletion(.failure(RequestError.clientError))
            return nil
        }
        guard let fileData = try? Data(contentsOf: fileURL) else {
            uploadCompletion(.failure(RequestError.clientError))
            return nil
        }
        let pathExtension = fileURL.pathExtension
        let mimeType = NetKit.getMimeType(pathExtension: pathExtension)
        let uploadData = NetKit.prepareBody(fileName: pathExtension, mimeType: mimeType, rawData: fileData)
        let requestContainer = RequestContainer.init(httpRequest: request,
                                                     fileData: uploadData.requestBodyData,
                                                     authDetail: authDetail,
                                                     uploadCompletion: uploadCompletion,
                                                     progressBlock: progressBlock)
        requestContainer.request?.setValue(uploadData.contentDisposition, forHTTPHeaderField: "Content-Disposition")
        requestContainer.request?.setValue(uploadData.contentType, forHTTPHeaderField: "Content-Type")
        requestContainer.currentState = .submitted
        self.dispatcher?.dispatchTask(requestContainer: requestContainer)
        return requestContainer
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    @discardableResult
    func prepareRequestForPause(taskId: String) -> RequestContainer? {
        let requestContainer = self.dispatcher?.taskContainerBy(requestId: taskId)
        requestContainer?.currentState = .paused
        self.dispatcher?.dispatchExistingTask(requestContainer: requestContainer)
        return requestContainer
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    @discardableResult
    func prepareRequestForResume(taskId: String) -> RequestContainer? {
        let requestContainer = self.dispatcher?.taskContainerBy(requestId: taskId)
        requestContainer?.currentState = .resumed
        self.dispatcher?.dispatchExistingTask(requestContainer: requestContainer)
        return requestContainer
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    @discardableResult
    func prepareRequestForCancel(taskId: String) -> RequestContainer? {
        let requestContainer = self.dispatcher?.taskContainerBy(requestId: taskId)
        requestContainer?.currentState =
            (requestContainer?.currentState == .paused ) ? .finished : .cancelled
        self.dispatcher?.dispatchExistingTask(requestContainer: requestContainer)
        return requestContainer
    }
}
