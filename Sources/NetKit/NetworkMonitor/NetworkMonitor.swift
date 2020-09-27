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
    case other
}

@available (iOS 12.0, OSX 10.14, *)
internal class NetworkMonitor {
    #if UNITTEST
    public static var shared: NetworkMonitor!
    public func testStartNetworkMonitoring() {
        self.startNetworkMonitoring()
    }
    public func setNetworkStatus(isConnected: Bool) {
        self.isConnected = isConnected
    }
    #else
    static var shared: NetworkMonitor {
        if sharedInstance == nil {
            sharedInstance = NetworkMonitor()
        }
        NetworkMonitor.instanceCount += 1
        return sharedInstance!
    }
    private init() { }
    #endif
    
    private var isConnected: Bool = false
    private var networkTypeForMonitoring = [NetworkTypeToMonitor]()
    private var networkMonitor: NWPathMonitor?
    private static var sharedInstance: NetworkMonitor?
    private static var instanceCount = 0
    
    final func setNetworkInteraceToMonitor(networkTypeForMonitoring: [NetworkTypeToMonitor]) {
        self.networkTypeForMonitoring = networkTypeForMonitoring
    }
    
    final func startMonitoring() {
        if NetworkMonitor.instanceCount == 1 {
            self.startNetworkMonitoring()
        }
    }
    
    private final func startNetworkMonitoring() {
        self.networkMonitor = NWPathMonitor()
        self.networkMonitor?.pathUpdateHandler = { [weak self] path in
            #if INTERNETNOTAVAILABLE
            if self?.isConnected ?? false {
                self?.pushOnlineNotification()
            } else {
                self?.pushOfflineNotification()
            }
            #else
            if path.usesInterfaceType(.cellular) {
                if path.status == .satisfied &&
                    self?.networkTypeForMonitoring.contains(.cellular) ?? false &&
                    self?.isConnected ?? true == false {
                    self?.isConnected = true
                    self?.pushOnlineNotification()
                }
            } else if path.usesInterfaceType(.wifi) {
                if path.status == .satisfied &&
                    self?.networkTypeForMonitoring.contains(.wifi) ?? false &&
                    self?.isConnected ?? true == false {
                    self?.isConnected = true
                    self?.pushOnlineNotification()
                }
            } else if path.usesInterfaceType(.wiredEthernet) {
                if path.status == .satisfied &&
                    self?.networkTypeForMonitoring.contains(.ethernet) ?? false &&
                    self?.isConnected ?? true == false {
                    self?.isConnected = true
                    self?.pushOnlineNotification()
                }
            } else if path.usesInterfaceType(.loopback) {
                if path.status == .satisfied &&
                    self?.networkTypeForMonitoring.contains(.loopback) ?? false &&
                    self?.isConnected ?? true == false {
                    self?.isConnected = true
                    self?.pushOnlineNotification()
                }
            } else if path.usesInterfaceType(.other) {
                if path.status == .satisfied &&
                    self?.networkTypeForMonitoring.contains(.other) ?? false &&
                    self?.isConnected ?? true == false {
                    self?.isConnected = true
                    self?.pushOnlineNotification()
                }
            } else if path.availableInterfaces.count == 0 && self?.isConnected ?? false == true {
                self?.isConnected = false
                self?.pushOfflineNotification()
            }
            //For checking connected network is captive protal
            //path.status == .requiresConnection
            #endif
        }
        let queue = DispatchQueue(label: "NetKit\(UUID().uuidString)", qos: .userInteractive)
        self.networkMonitor?.start(queue: queue)
    }
    
    private func pushOnlineNotification() {
        DispatchQueue.main.async {
            let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Available)
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    
    private func pushOfflineNotification() {
        DispatchQueue.main.async {
            let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Offline)
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    
    final func stopNetworkMonitoring() {
        #if UNITTEST
        self.networkMonitor?.cancel()
        NetworkMonitor.dispose()
        #else
        NetworkMonitor.instanceCount -= 1
        if NetworkMonitor.instanceCount <= 0 {
            self.networkMonitor?.cancel()
            NetworkMonitor.dispose()
        } else {
            print("\(NetworkMonitor.instanceCount) Net Kit instance(s) exist")
        }
        #endif
    }
    
    static func dispose() {
        NetworkMonitor.sharedInstance = nil
        NetworkMonitor.instanceCount = 0
        debugPrint("NetworkMonitor - \(self) sharedInstance = nil")
    }
    
    final func getNetworkStatus() -> Bool {
        return self.isConnected
    }
    
    deinit {
        debugPrint("NetworkMonitor - \(self) deinit call")
        self.networkMonitor = nil
    }
}
