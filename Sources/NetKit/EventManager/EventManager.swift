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
import Security
import CommonCrypto

/// Event manager class as Session Delegate
@available (iOS 12.0, OSX 10.14, *)
internal class EventManager: NSObject, URLSessionDelegate, URLSessionDownloadDelegate, URLSessionDataDelegate {
    private weak var executor: TaskExecutor?
    internal var authManager: ChallengeAcceptor?
    
    override init() {
        super.init()
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    convenience init(executor: TaskExecutor?, authManager: ChallengeAcceptor?) {
        self.init()
        self.executor = executor
        self.authManager = authManager
    }
    deinit {
        self.executor = nil
        self.authManager = nil
    }
    /// Delegate method called for download task progress
    /// - Parameter session: current session
    /// - Parameter downloadTask: download task
    /// - Parameter bytesWritten: bytes written
    /// - Parameter totalBytesWritten: total bytes written
    /// - Parameter totalBytesExpectedToWrite: total bytes expected to be written
    @available (iOS 12.0, OSX 10.14, *)
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        self.executor?.handleDownloadProgress(taskId: downloadTask.taskIdentifier,
                                              totalBytesWritten: totalBytesWritten,
                                              totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    /// Delegate method called once file download is finished.
    /// - Parameter session: current session
    /// - Parameter downloadTask: download task
    /// - Parameter location: file url
    @available (iOS 12.0, OSX 10.14, *)
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        self.executor?.handleDownloadCompletion(task: downloadTask,
                                                location: location)
    }
    /// Delegate method once task is finished
    /// - Parameter session: current session
    /// - Parameter task: a task (Download, DataTask or Upload task)
    /// - Parameter error: URLError type
    @available (iOS 12.0, OSX 10.14, *)
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        self.executor?.handleSessionDelegate(error: error, task: task)
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        self.executor?.handleUploadProgress(taskId: task.taskIdentifier,
                                            totalBytesSent: totalBytesSent,
                                            totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    // MARK: Task level authentication
    /// Delegate method for task level authentication
    /// - Parameter session: current session
    /// - Parameter task: a task (Download, DataTask or Upload task)
    /// - Parameter challenge: Authentication Challenge
    /// - Parameter completionHandler: An instance of ChallengeCompletion
    @available (iOS 12.0, OSX 10.14, *)
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping ChallengeCompletion) {
        if let container = self.executor?.taskDispatcher?.taskContainerBy(taskId: task.taskIdentifier) {
            self.authManager?.handleAuthChallenge(requestContainer: container,
                                                  challenge: challenge,
                                                  completion: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.executor?.handleDidReceiveData(taskId: dataTask.taskIdentifier, data: data)
    }
}
