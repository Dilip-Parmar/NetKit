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
class TaskExecutor: TaskCancellable {
   
    // MARK: - Properties
    private var executorQueue: DispatchQueue?
    private var eventManager: EventManager?
    internal var urlSession: URLSession?
    private var statusCodesForRetry: [Int]?
    
    var taskDispatcher: TaskDispatcher? {
        willSet {
            self.taskFinalizer = TaskFinalizer.init(dispatcher: newValue, statusCodesForRetry: self.statusCodesForRetry)
        }
    }

    private var taskFinalizer: TaskFinalizer?
    private var progressQueue: DispatchQueue?
    // MARK: - Initializer
    init() {
        
    }
    @available (iOS 12.0, OSX 10.14, *)
    init(sessionConfiguration: URLSessionConfiguration,
         sessionDelegate: SessionDelegate?,
         commonHeaders: [String: String],
         waitsForConnectivity: Bool,
         waitingTimeForConnectivity: TimeInterval,
         authManager: ChallengeAcceptor?,
         statusCodesForRetry: [Int]? = nil) {
        
        //Should wait for network or fail immediately
        sessionConfiguration.waitsForConnectivity = waitsForConnectivity
        
        //wait time for network.
        sessionConfiguration.timeoutIntervalForResource = waitingTimeForConnectivity
        //Common headers for all requests
        if !commonHeaders.isEmpty {
            sessionConfiguration.httpAdditionalHeaders = commonHeaders
        }
        
        self.eventManager = EventManager.init(executor: self, authManager: authManager)
        self.executorQueue = DispatchQueue(label: "NetKit\(UUID())", qos: .default, attributes: .concurrent)
        self.progressQueue = DispatchQueue.init(label: "NetKit\(UUID())", qos: .userInitiated, attributes: .concurrent)
        self.urlSession = URLSession.init(configuration: sessionConfiguration,
                                          delegate: (sessionDelegate != nil) ? sessionDelegate! : self.eventManager,
                                          delegateQueue: nil)
        self.statusCodesForRetry = statusCodesForRetry
    }
    
    // MARK: - Task Execution
    @available (iOS 12.0, OSX 10.14, *)
    func executeTask(requestContainer: RequestContainer?) {
        if let requestContainer = requestContainer {
            switch requestContainer.requestType {
            case .data:
                self.handleDataTask(requestContainer: requestContainer)
            case .download:
                self.handleDownloadTask(requestContainer: requestContainer)
            case .upload:
                self.handleUploadTask(requestContainer: requestContainer)
            }
        }
    }
    
    func handleDataTask(requestContainer: RequestContainer) {
        if let request = requestContainer.request {
            self.executorQueue?.async {
                switch requestContainer.currentState {
                case .submitted:
                    if let dataTask = self.urlSession?.dataTask(with: request) {
                        requestContainer.taskId = dataTask.taskIdentifier
                        requestContainer.currentState = .running
                        dataTask.resume()
                    }
                case .cancelled:
                    self.cancelRequestBy(requestId: requestContainer.requestId, taskType: .data)
                default:
                    break
                }
            }
        }
    }
    
    func handleDownloadTask(requestContainer: RequestContainer) {
        if let request = requestContainer.request {
            self.executorQueue?.async {
                switch requestContainer.currentState {
                case .submitted:
                    if let dataTask = self.urlSession?.downloadTask(with: request) {
                        requestContainer.taskId = dataTask.taskIdentifier
                        dataTask.resume()
                        requestContainer.currentState = .running
                        requestContainer.taskId = dataTask.taskIdentifier
                    }
                case .paused:
                    self.getTaskBy(taskId: requestContainer.taskId,
                                   taskType: .download, completion: { (task) in
                                    if let downloadTask = task as? URLSessionDownloadTask {
                                        downloadTask.cancel(byProducingResumeData: { (resumeData) in
                                            requestContainer.resumeData = resumeData
                                        })
                                    }
                    })
                case .resumed:
                    if let resumeData = requestContainer.resumeData,
                        let dataTask = self.urlSession?.downloadTask(withResumeData: resumeData) {
                        requestContainer.taskId = dataTask.taskIdentifier
                        requestContainer.currentState = .running
                        dataTask.resume()
                        requestContainer.resumeData = nil
                    }
                case .cancelled:
                    self.cancelRequestBy(requestId: requestContainer.requestId, taskType: .download)
                case .finished:
                    let error = NSError.init(domain: NSURLErrorDomain, code: -999, userInfo: nil)
                    self.taskFinalizer?.finalizePausedTask(error: error, requestContainer: requestContainer)
                default:
                    break
                }
            }
        }
    }
    
    func handleUploadTask(requestContainer: RequestContainer) {
        if let request = requestContainer.request {
            self.executorQueue?.async {
                switch requestContainer.currentState {
                case .submitted:
                    if let data = requestContainer.uploadFileData,
                        let dataTask = self.urlSession?.uploadTask(with: request, from: data) {
                        requestContainer.taskId = dataTask.taskIdentifier
                        dataTask.resume()
                        requestContainer.currentState = .running
                    }
                case .paused:
                    self.getTaskBy(taskId: requestContainer.taskId,
                                   taskType: .upload, completion: { (task) in
                                    if let uplodTask = task as? URLSessionUploadTask {
                                        uplodTask.suspend()
                                        requestContainer.currentState = .paused
                                    }
                    })
                case .resumed:
                    self.getTaskBy(taskId: requestContainer.taskId,
                                   taskType: .upload, completion: { (task) in
                                    if let uplodTask = task as? URLSessionUploadTask {
                                        uplodTask.resume()
                                        requestContainer.currentState = .running
                                    }
                    })
                case .cancelled: debugPrint("cancelled")
                    fallthrough
                case .finished:
                    self.cancelRequestBy(requestId: requestContainer.requestId, taskType: .upload)
                default:
                    break
                }
            }
        }
    }
    // MARK: - Download Progress
    @available (iOS 12.0, OSX 10.14, *)
    internal final func handleDownloadProgress(taskId: Int,
                                               totalBytesWritten: Int64,
                                               totalBytesExpectedToWrite: Int64) {
        self.progressQueue?.async {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            if let progressBlock = self.taskDispatcher?.taskContainerBy(taskId: taskId)?.progressBlock {
                progressBlock(progress)
            }
        }
    }
    
    // MARK: - Download Completion
    @available (iOS 12.0, OSX 10.14, *)
    internal final func handleDownloadCompletion(task: URLSessionDownloadTask,
                                                 location: URL) {
        self.executorQueue?.async {
            if let taskContainer = self.taskDispatcher?.taskContainerBy(taskId: task.taskIdentifier) {
                let filename = String(describing: UUID.init())
                let fileURL = FileManager.default.urls(for: .documentDirectory,
                                                       in: .userDomainMask)[0].appendingPathComponent(filename)
                try? FileManager.default.moveItem(at: location, to: fileURL)
                taskContainer.downloadFileURL = fileURL
            }
        }
    }
    
    // MARK: - Upload Progress Handling
    @available (iOS 12.0, OSX 10.14, *)
    internal final func handleUploadProgress(taskId: Int,
                                             totalBytesSent: Int64,
                                             totalBytesExpectedToSend: Int64) {
        self.progressQueue?.async {
            let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            if let progressBlock = self.taskDispatcher?.taskContainerBy(taskId: taskId)?.progressBlock {
                progressBlock(progress)
            }
        }
    }
    
    // MARK: - Task Error Handling
    @available (iOS 12.0, OSX 10.14, *)
    internal final func handleSessionDelegate(error: Error?,
                                              task: URLSessionTask) {
        self.executorQueue?.async {
            if let taskContainer = self.taskDispatcher?.taskContainerBy(taskId: task.taskIdentifier) {
                taskContainer.currentState = (error != nil) ? .failed : .finished
                self.taskFinalizer?.finalizeTask(task: task, error: error, requestContainer: taskContainer)
            }
        }
    }
    
    // MARK: - Receive Data
    @available (iOS 12.0, OSX 10.14, *)
    internal func handleDidReceiveData(taskId: Int,
                                       data: Data) {
        self.executorQueue?.async {
            if let taskContainer = self.taskDispatcher?.taskContainerBy(taskId: taskId) {
                taskContainer.receivedData?.append(data)
            }
        }
    }
    // MARK: - Purge Session
    @available (iOS 12.0, OSX 10.14, *)
    public func purgeSession(shouldCancelRunningTasks: Bool) {
        if shouldCancelRunningTasks {
            self.urlSession?.finishTasksAndInvalidate()
        } else {
            self.urlSession?.invalidateAndCancel()
        }
    }
    // MARK: - Task Deinitializer
    deinit {
        self.urlSession?.invalidateAndCancel()
        self.executorQueue = nil
        self.eventManager = nil
        self.urlSession = nil
        self.taskDispatcher = nil
        self.taskFinalizer = nil
        self.progressQueue = nil
    }
}

@available (iOS 12.0, OSX 10.14, *)
extension TaskExecutor {
   
    // MARK: - Task Cancellable Protocol
    @available (iOS 12.0, OSX 10.14, *)
    func getAllRequests(completion: @escaping ([URLSessionTask]) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        self.urlSession?.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            var tasks = [URLSessionTask]()
            tasks.append(contentsOf: dataTasks as [URLSessionTask])
            tasks.append(contentsOf: uploadTasks as [URLSessionTask])
            tasks.append(contentsOf: downloadTasks as [URLSessionTask])
            semaphore.signal()
            completion(tasks)
        }
        _ = semaphore.wait(timeout: DispatchTime.now() + 12.0)
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func getTaskBy(taskId: Int, taskType: RequestType, completion: @escaping (URLSessionTask?) -> Void) {
        var task: URLSessionTask?
        let semaphore = DispatchSemaphore(value: 0)
        self.urlSession?.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            var tasks = [URLSessionTask]()
            switch taskType {
            case .data:
                tasks.append(contentsOf: dataTasks as [URLSessionTask])
                let filterdTasks = tasks.filter({ $0.taskIdentifier == taskId })
                task = filterdTasks.first as? URLSessionDataTask
            case .upload:
                tasks.append(contentsOf: uploadTasks as [URLSessionTask])
                let filterdTasks = tasks.filter({ $0.taskIdentifier == taskId })
                task = filterdTasks.first as? URLSessionUploadTask
            case .download:
                tasks.append(contentsOf: downloadTasks as [URLSessionTask])
                let filterdTasks = tasks.filter({ $0.taskIdentifier == taskId })
                task = filterdTasks.first as? URLSessionDownloadTask
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.now() + 12.0)
        completion(task)
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func cancelAllRequests() {
        self.getAllRequests { (tasks) in
            for task in tasks {
                task.cancel()
            }
        }
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func cancelRequestBy(requestId: String, taskType: RequestType) {
        let semaphore = DispatchSemaphore(value: 0)
        self.urlSession?.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            var tasks = [URLSessionTask]()
            switch taskType {
            case .data:
                tasks.append(contentsOf: dataTasks as [URLSessionTask])
            case .upload:
                tasks.append(contentsOf: uploadTasks as [URLSessionTask])
            case .download:
                tasks.append(contentsOf: downloadTasks as [URLSessionTask])
            }
            let container = self.taskDispatcher?.taskContainerBy(requestId: requestId)
            let filterdTasks = tasks.filter({ $0.taskIdentifier == container?.taskId })
            filterdTasks.first?.cancel()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.now() + 12.0)
    }
}
