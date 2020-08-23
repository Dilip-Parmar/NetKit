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

@available (iOS 12.0, OSX 10.14, *)
final class NetworkMonitor {
    private var networkMonitor: NWPathMonitor?
    private var isNetworkConnected: Bool = false
    init() {
        let queue = DispatchQueue(label: "NetKit\(UUID().uuidString)", qos: .background, attributes: .concurrent)
        self.networkMonitor = NWPathMonitor()
        self.networkMonitor?.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.isNetworkConnected = true
                DispatchQueue.main.async {
                    let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Available)
                    NotificationCenter.default.post(name: notificationName, object: nil)
                }
            } else {
                self?.isNetworkConnected = false
                DispatchQueue.main.async {
                    let notificationName = Notification.Name(rawValue: NetworkStatusNotification.Offline)
                    NotificationCenter.default.post(name: notificationName, object: nil)
                }
            }
        }
        self.networkMonitor?.start(queue: queue)
    }
    
    final func stopNetworkMonitoring() {
        self.networkMonitor?.cancel()
    }
    
    func getNetworkStatus() -> Bool {
        return self.isNetworkConnected
    }
    
    deinit {
        self.networkMonitor = nil
        debugPrint("NetworkMonitor - \(self) deinit call")
    }
}
