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
public typealias DataCompletion = ((HTTPURLResponse?, Result<Data?, RequestError>) -> Void)

@available (iOS 12.0, OSX 10.14, *)
public typealias DownloadProgressBlock = ((Float) -> Void)

@available (iOS 12.0, OSX 10.14, *)
public typealias UploadProgressBlock = ((Float) -> Void)

@available (iOS 12.0, OSX 10.14, *)
public typealias DownloadCompletion = ((HTTPURLResponse?, Result<URL?, RequestError>) -> Void)

@available (iOS 12.0, OSX 10.14, *)
public typealias UploadCompletion = ((HTTPURLResponse?, Result<Data?, RequestError>) -> Void)

@available (iOS 12.0, OSX 10.14, *)
public typealias ChallengeCompletion = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

@available (iOS 12.0, OSX 10.14, *)
public typealias ProgressBlock = ((Float) -> Void)

@available (iOS 12.0, OSX 10.14, *)
public enum RequestType {
    case data
    case download
    case upload
}
@available (iOS 12.0, OSX 10.14, *)
enum RequestCurrentState {
    case initiated
    case submitted
    case running
    case paused
    case resumed
    case finished
    case failed
    case cancelled
}
@available (iOS 12.0, OSX 10.14, *)
final class RequestContainer {
    
    @available (iOS 12.0, OSX 10.14, *)
    class ThreadSafeContainer {
        var requestId: String = "\(UUID())"
        var dataCompletion: DataCompletion?
        var downloadCompletion: DownloadCompletion?
        var uploadCompletion: UploadCompletion?
        var challengeCompletion: ChallengeCompletion?
        var progressBlock: ProgressBlock?
        var requestType: RequestType = .data
        var currentState: RequestCurrentState = .initiated
        var request: URLRequest?
        var taskId: Int = -1
        var receivedData: Data? = Data()
        var downloadFileURL: URL?
        var error: RequestError?
        var uploadFileData: Data?
        var authDetail: AuthDetail?
        var resumeData: Data?
    }
    private var threadSafeContainer: ThreadSafeContainer?
    private var protectedValues: SafetyManager<ThreadSafeContainer>

    public var requestId: String {
        get { return protectedValues.read()?.requestId ?? "" }
        set { protectedValues.write { $0?.requestId = newValue } }
    }
    
    public var taskId: Int {
        get { return protectedValues.read()?.taskId ?? -1 }
        set { protectedValues.write { $0?.taskId = newValue } }
    }
    
    public var dataCompletion: DataCompletion? {
        get { return protectedValues.read()?.dataCompletion }
        set { protectedValues.write { $0?.dataCompletion = newValue } }
    }
    
    public var downloadCompletion: DownloadCompletion? {
        get {  return protectedValues.read()?.downloadCompletion }
        set { protectedValues.write { $0?.downloadCompletion = newValue } }
    }
    
    public var uploadCompletion: UploadCompletion? {
        get { return protectedValues.read()?.uploadCompletion }
        set { protectedValues.write { $0?.uploadCompletion = newValue } }
    }
    
    public var progressBlock: ProgressBlock? {
        get { return protectedValues.read()?.progressBlock }
        set { protectedValues.write { $0?.progressBlock = newValue } }
    }
    
    public var challengeCompletion: ChallengeCompletion? {
        get { return protectedValues.read()?.challengeCompletion }
        set { protectedValues.write { $0?.challengeCompletion = newValue } }
    }
    
    var currentState: RequestCurrentState {
        get { return protectedValues.read()?.currentState ?? .initiated }
        set { protectedValues.write { $0?.currentState = newValue } }
    }
    
    var request: URLRequest? {
        get { return protectedValues.read()?.request }
        set { protectedValues.write { $0?.request = newValue } }
    }

    var requestType: RequestType {
        get { return protectedValues.read()?.requestType ?? .data }
        set { protectedValues.write { $0?.requestType = newValue } }
    }
    
    var receivedData: Data? {
        get { return protectedValues.read()?.receivedData }
        set { protectedValues.write { $0?.receivedData = newValue } }
    }
    
    var downloadFileURL: URL? {
        get { return protectedValues.read()?.downloadFileURL }
        set { protectedValues.write { $0?.downloadFileURL = newValue } }
    }
    
    var error: RequestError? {
        get { return protectedValues.read()?.error }
        set { protectedValues.write { $0?.error = newValue } }
    }
    
    var uploadFileData: Data? {
        get { return protectedValues.read()?.uploadFileData }
        set { protectedValues.write { $0?.uploadFileData = newValue } }
    }
    
    var authDetail: AuthDetail? {
        get { return protectedValues.read()?.authDetail }
        set { protectedValues.write { $0?.authDetail = newValue } }
    }
    
    var resumeData: Data? {
        get { return protectedValues.read()?.resumeData }
        set { protectedValues.write { $0?.resumeData = newValue } }
    }
    @available (iOS 12.0, OSX 10.14, *)
    init() {
        self.threadSafeContainer = ThreadSafeContainer.init()
        self.protectedValues = SafetyManager.init(value: self.threadSafeContainer)
        self.currentState = .initiated
        self.taskId = -1
    }
    @available (iOS 12.0, OSX 10.14, *)
    convenience init(httpRequest: URLRequest,
                     authDetail: AuthDetail?,
                     dataCompletion: @escaping DataCompletion) {
        self.init()
        self.dataCompletion = dataCompletion
        self.requestType = .data
        self.request = httpRequest
    }
    @available (iOS 12.0, OSX 10.14, *)
    convenience init(httpRequest: URLRequest,
                     authDetail: AuthDetail?,
                     downloadCompletion: @escaping DownloadCompletion,
                     progressBlock: ProgressBlock?) {
        self.init()
        self.downloadCompletion = downloadCompletion
        self.progressBlock = progressBlock
        self.requestType = .download
        self.request = httpRequest
    }
    @available (iOS 12.0, OSX 10.14, *)
    convenience init(httpRequest: URLRequest,
                     fileData: Data,
                     authDetail: AuthDetail?,
                     uploadCompletion: @escaping UploadCompletion,
                     progressBlock: ProgressBlock?) {
        self.init()
        self.uploadCompletion = uploadCompletion
        self.progressBlock = progressBlock
        self.requestType = .upload
        self.request = httpRequest
        self.uploadFileData = fileData
    }
    
    deinit {
        self.protectedValues.write { (values) in
            values = nil
        }
        self.threadSafeContainer = nil
    }
}
