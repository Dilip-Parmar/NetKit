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

import XCTest
@testable import NetKit_iOS

internal class MockNetworkMonitor: NetworkMonitor {
    override init() {
        super.init()
        self.testStartNetworkMonitoring()
    }
}

class NetworkMonitorTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testNetworkOnEthernetAvailable() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.ethernet, .wifi, .cellular])
        
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        XCTAssertTrue(NetworkMonitor.shared.getNetworkStatus())
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    /*func testNetworkOnCellularAvailable() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.cellular])
        
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnWifiAvailable() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.wifi])
        
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnLoopbackAvailable() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.loopback])
        
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnEthernetOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.ethernet])
        
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }*/
    
    
    func testNetworkOnCellularOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.cellular, .wifi])
        
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnWifiOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.wifi, .loopback])
        
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnLoopbackOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.loopback, .cellular])
        
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
}
