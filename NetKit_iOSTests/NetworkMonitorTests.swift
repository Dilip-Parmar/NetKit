//
//  NetworkMonitorTests.swift
//  NetKit_iOSTests
//
//  Created by dparmar on 9/26/20.
//  Copyright © 2020 Dilip Parmar. All rights reserved.
//

import XCTest
@testable import NetKit_iOS

internal class MockNetworkMonitor: NetworkMonitor {
    override init() {
        super.init()
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
        NetworkMonitor.shared.startNetworkMonitoring()
        
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
        NetworkMonitor.shared.startNetworkMonitoring()
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnWifiAvailable() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.wifi])
        NetworkMonitor.shared.startNetworkMonitoring()
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnLoopbackAvailable() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.loopback])
        NetworkMonitor.shared.startNetworkMonitoring()
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnEthernetOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.ethernet])
        NetworkMonitor.shared.startNetworkMonitoring()
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }*/
    
    
    func testNetworkOnCellularOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.cellular, .wifi])
        NetworkMonitor.shared.startNetworkMonitoring()
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnWifiOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.wifi, .loopback])
        NetworkMonitor.shared.startNetworkMonitoring()
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkOnLoopbackOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.loopback, .cellular])
        NetworkMonitor.shared.startNetworkMonitoring()
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
}
