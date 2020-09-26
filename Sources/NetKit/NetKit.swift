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
public typealias SessionDelegate = URLSessionDelegate & URLSessionDataDelegate

@available (iOS 12.0, OSX 10.14, *)
/// NetKit Main class
public class NetKit {
    
    private var networkMonitor: NetworkMonitor?
    var requestMaker: RequestMaker?
    var taskExecutor: TaskExecutor?
    
    public var isNetworkConnected: Bool {
        return self.networkMonitor?.getNetworkStatus() ?? false
    }
    
    private init() {}
    @available (iOS 12.0, OSX 10.14, *)
    public convenience init(sessionConfiguration: URLSessionConfiguration,
                            sessionDelegate: SessionDelegate?,
                            commonHeaders: [String: String],
                            waitsForConnectivity: Bool,
                            waitingTimeForConnectivity: TimeInterval,
                            statusCodesForRetry: [Int]? = nil) {
        self.init()

        self.networkMonitor = NetworkMonitor.shared
        self.networkMonitor?.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.cellular, .wifi])
        self.networkMonitor?.startNetworkMonitoring()

        let authManager = ChallengeAcceptor.init()
        self.taskExecutor = TaskExecutor.init(sessionConfiguration: sessionConfiguration,
                                              sessionDelegate: sessionDelegate,
                                              commonHeaders: commonHeaders,
                                              waitsForConnectivity: waitsForConnectivity,
                                              waitingTimeForConnectivity: waitingTimeForConnectivity,
                                              authManager: authManager,
                                              statusCodesForRetry: statusCodesForRetry)

        let taskDispatcher = TaskDispatcher.init(taskExecutor: self.taskExecutor)
        self.requestMaker = RequestMaker.init(dispatcher: taskDispatcher)
        self.taskExecutor?.taskDispatcher = taskDispatcher
    }
    
    /// To destroy current session
    /// - Parameter shouldCancelRunningTasks: session should wait untill all running tasks are finished.
    @available (iOS 12.0, OSX 10.14, *)
    public func purgeSession(shouldCancelRunningTasks: Bool) {
        self.taskExecutor?.purgeSession(shouldCancelRunningTasks: shouldCancelRunningTasks)
    }
    
    /// Current session
    @available (iOS 12.0, OSX 10.14, *)
    public func session() -> URLSession? {
        return self.taskExecutor?.urlSession ?? URLSession.init()
    }
    
    deinit {
        debugPrint("NetKit deinit call")
        self.networkMonitor?.stopNetworkMonitoring()
        self.networkMonitor = nil
        self.requestMaker = nil
        self.taskExecutor = nil
    }
    
    #if UNITTEST
    func setNetworkMonitor(nm: NetworkMonitor) {
        self.networkMonitor = nm
    }
    #endif
}
