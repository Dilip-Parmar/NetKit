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
import Network

@available (iOS 12.0, OSX 10.14, *)
public struct NetworkStatusNotification {
    public static let Offline = "WaitingForNeworkNotification"
    public static let Available = "NetworkAvailableNotification"
}

enum NetworkTypeToMonitor {
    case cellular
    case wifi
    case ethernet
    case loopback
}

@available (iOS 12.0, OSX 10.14, *)
final class NetworkMonitor {
    static var shared: NetworkMonitor {
        if sharedInstance == nil {
            sharedInstance = NetworkMonitor()
        }
        NetworkMonitor.instanceCount += 1
        return sharedInstance!
    }
    private var networkTypeForMonitoring: [NetworkTypeToMonitor]
    private static var sharedInstance: NetworkMonitor?
    private var networkMonitor: NWPathMonitor?
    private static var instanceCount = 0
    private var isConnected: Bool = false
    
    private init() {

        self.networkTypeForMonitoring = [NetworkTypeToMonitor]()
        self.networkTypeForMonitoring.append(.cellular)
        self.networkTypeForMonitoring.append(.wifi)
        
        #if os(OSX) || os(tvOS)
            self.networkTypeForMonitoring.append(.ethernet)
        #endif
        
        self.networkTypeForMonitoring.append(.loopback)
        
        let queue = DispatchQueue(label: "NetKit\(UUID().uuidString)", qos: .userInteractive)
        self.networkMonitor = NWPathMonitor()
        self.networkMonitor?.pathUpdateHandler = { [weak self] path in
            if path.usesInterfaceType(.cellular) && self?.networkTypeForMonitoring.contains(.cellular) ?? false {
                if path.status == .satisfied && self?.isConnected ?? false == false {
                    self?.isConnected = true
                    DispatchQueue.main.async {
                        let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Available)
                        NotificationCenter.default.post(name: notificationName, object: nil)
                    }
                }
            } else if path.usesInterfaceType(.wifi) && self?.networkTypeForMonitoring.contains(.wifi) ?? false {
                if path.status == .satisfied && self?.isConnected ?? false == false {
                    self?.isConnected = true
                    DispatchQueue.main.async {
                        let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Available)
                        NotificationCenter.default.post(name: notificationName, object: nil)
                    }
                }
            } else if path.usesInterfaceType(.wiredEthernet) && self?.networkTypeForMonitoring.contains(.ethernet) ?? false {
                if path.status == .satisfied && self?.isConnected ?? false == false {
                    self?.isConnected = true
                    DispatchQueue.main.async {
                        let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Available)
                        NotificationCenter.default.post(name: notificationName, object: nil)
                    }
                }
            } else if path.usesInterfaceType(.loopback) && self?.networkTypeForMonitoring.contains(.loopback) ?? false {
                if path.status == .satisfied && self?.isConnected ?? false == false {
                    self?.isConnected = true
                    DispatchQueue.main.async {
                        let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Available)
                        NotificationCenter.default.post(name: notificationName, object: nil)
                    }
                }
            } else if path.availableInterfaces.count == 0 && self?.isConnected ?? false == true {
                self?.isConnected = false
                DispatchQueue.main.async {
                    let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Offline)
                    NotificationCenter.default.post(name: notificationName, object: nil)
                }
            }
        }
        self.networkMonitor?.start(queue: queue)
    }
    
    final func stopNetworkMonitoring() {
        NetworkMonitor.instanceCount -= 1
        if NetworkMonitor.instanceCount <= 0 {
            self.networkMonitor?.cancel()
            NetworkMonitor.dispose()
        } else {
            print("\(NetworkMonitor.instanceCount) Net Kit instance(s) exist")
        }
    }
    
    static func dispose() {
        NetworkMonitor.sharedInstance = nil
        NetworkMonitor.instanceCount = 0
        debugPrint("NetworkMonitor - \(self) sharedInstance = nil")
    }
    
    func getNetworkStatus() -> Bool {
        return self.isConnected
    }
    
    deinit {
        debugPrint("NetworkMonitor - \(self) deinit call")
        self.networkMonitor = nil
    }
}
