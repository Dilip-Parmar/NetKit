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
class TaskDispatcher: RequestMakerToDispatcher, TaskExecutorToDispatcher, TaskFinalizerToDispatcher {

    // MARK: - Properties
    private var requestsPool: [RequestContainer]?
    private var requestPoolSemaphore: DispatchSemaphore?
    private var dispatchQueue: DispatchQueue?
    private weak var taskExecutor: TaskExecutor?
    private var requestsBuffer: [RequestContainer]?
    private var protectedRequestPool: SafetyManager<[RequestContainer]>?
    private var protectedRequestBuffer: SafetyManager<[RequestContainer]>?

    // MARK: - Initializer
    @available (iOS 12.0, OSX 10.14, *)
    init(taskExecutor: TaskExecutor?) {
        self.requestPoolSemaphore = DispatchSemaphore.init(value: 0)
        self.dispatchQueue = DispatchQueue(label: "NetKit\(UUID())", qos: .default)
        self.taskExecutor = taskExecutor
        self.requestsPool = [RequestContainer]()
        self.requestsBuffer = [RequestContainer]()
        self.protectedRequestPool = SafetyManager.init(value: self.requestsPool)
        self.protectedRequestBuffer = SafetyManager.init(value: self.requestsBuffer)
    }
    @available (iOS 12.0, OSX 10.14, *)
    func startObservingRequestNow() {
        self.dispatchQueue?.async {
            self.startObservingRequest()
        }
    }
    // MARK: - Tasks
    @available (iOS 12.0, OSX 10.14, *)
    func allTasks() -> [RequestContainer]? {
        return self.protectedRequestPool?.read()
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func taskContainerBy(requestId: String) -> RequestContainer? {
        return self.protectedRequestPool?.read()?.filter({ $0.requestId == requestId }).first
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func taskContainerBy(taskId: Int) -> RequestContainer? {
        return self.protectedRequestPool?.read()?.filter({ $0.taskId == taskId }).first
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func dispatchTask(requestContainer: RequestContainer?) {
        if let requestContainer = requestContainer {
            self.addToRequestPool(requestContainer: requestContainer)
            self.addToRequestBuffer(requestContainer: requestContainer)
            self.requestPoolSemaphore?.signal()
        }
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func dispatchExistingTask(requestContainer: RequestContainer?) {
        if let requestContainer = requestContainer {
            self.addToRequestBuffer(requestContainer: requestContainer)
            self.requestPoolSemaphore?.signal()
        }
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    private func startObservingRequest() {
        self.requestPoolSemaphore?.wait()
        if let requestContainer = self.protectedRequestBuffer?.read()?.first {
            self.removeFromBuffer(requestId: requestContainer.requestId)
            self.taskExecutor?.executeTask(requestContainer: requestContainer)
            self.dispatchQueue?.async {
                self.startObservingRequest()
            }
        }
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func addToRequestBuffer(requestContainer: RequestContainer?) {
        if let requestContainer = requestContainer {
            protectedRequestBuffer?.write(closure: { (containers) in
                containers?.append(requestContainer)
            })
        }
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func removeFromBuffer(requestId: String) {
        protectedRequestBuffer?.write(closure: { (containers) in
            containers?.removeAll(where: { (container) -> Bool in
                container.requestId == requestId
            })
        })
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func addToRequestPool(requestContainer: RequestContainer?) {
        if let requestContainer = requestContainer {
            self.protectedRequestPool?.write(closure: { (containers) in
                containers?.append(requestContainer)
            })
        }
    }
    
    @available (iOS 12.0, OSX 10.14, *)
    func removeFromRequestPool(requestId: String) {
        self.protectedRequestPool?.write(closure: { (containers) in
            containers?.removeAll(where: { (container) -> Bool in
                container.requestId == requestId
            })
        })
    }
    
    deinit {
        self.protectedRequestPool = nil
        self.protectedRequestBuffer = nil
        self.requestPoolSemaphore = nil
        self.requestsPool = nil
        self.taskExecutor = nil
        self.dispatchQueue = nil
        self.requestsBuffer = nil
    }
}
