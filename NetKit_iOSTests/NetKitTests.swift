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

extension Notification.Name {
    static var networkOffline = Notification.Name(NetworkStatusNotification.Offline)
    static var networkAvailable = Notification.Name(NetworkStatusNotification.Available)
}

class TestURLSessionDelegate: NSObject, SessionDelegate {
    override init() {
        super.init()
    }
}

class NetKitTests: XCTestCase {
    
    private var netKitInstance: NetKit!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        netKitInstance = NetKit.init(sessionConfiguration: .ephemeral, sessionDelegate: nil, commonHeaders: [:], waitsForConnectivity: true, waitingTimeForConnectivity: 0.0)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        netKitInstance.cancelAllRequests()
        netKitInstance = nil
    }
    
    func testInstanceNotNil() {
        XCTAssertNotNil(netKitInstance)
    }
    
    func testTaskExecutorNotNil() {
        XCTAssertNotNil(netKitInstance.taskExecutor)
    }
    
    func testRequestMakerNotNil() {
        XCTAssertNotNil(netKitInstance.requestMaker)
    }
    
    func testNetworkStatusNotificationAvailable() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.ethernet, .wifi, .cellular])
        netKitInstance.setNetworkMonitor(nm: NetworkMonitor.shared)
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        XCTAssertTrue(NetworkMonitor.shared.getNetworkStatus())
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkStatusNotificationOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.loopback])
        netKitInstance.setNetworkMonitor(nm: NetworkMonitor.shared)
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        XCTAssertFalse(NetworkMonitor.shared.getNetworkStatus())
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkStatusAvailable() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.ethernet])
        netKitInstance.setNetworkMonitor(nm: NetworkMonitor.shared)
        
        let notificationExpectation = expectation(forNotification: .networkAvailable,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        XCTAssertTrue(netKitInstance.isNetworkConnected)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testNetworkStatusOffline() {
        NetworkMonitor.shared = MockNetworkMonitor()
        NetworkMonitor.shared.setNetworkInteraceToMonitor(networkTypeForMonitoring: [.loopback])
        netKitInstance.setNetworkMonitor(nm: NetworkMonitor.shared)
        
        let notificationExpectation = expectation(forNotification: .networkOffline,
                                                  object: nil,
                                                  handler: nil)
        wait(for: [notificationExpectation], timeout: 5.0)
        XCTAssertFalse(netKitInstance.isNetworkConnected)
        NetworkMonitor.shared.stopNetworkMonitoring()
    }
    
    func testPurgeSessionWaitForTask() {
        let request = HTTPRequest.init(baseURL: "http://www.google.com", path: "", method: .GET, requestBody: nil, bodyEncoding: nil, requestHeaders: nil, queryParams: nil, queryParamsEncoding: nil, cachePolicy: nil, timeoutInterval: nil, networkServiceType: .default, bodyEncryption: nil)
        let requestId = netKitInstance.send(request: request, authDetail: nil) { _,_ in }
        XCTAssertNotNil(requestId)
        usleep(1000)
        netKitInstance.purgeSession(shouldCancelRunningTasks: false)
        let expectaion = XCTestExpectation.init(description: "\(#function)\(#file)\(#line)")
        netKitInstance.getAllRequests { (task) in
            XCTAssertEqual(task.count, 1)
            expectaion.fulfill()
        }
        wait(for: [expectaion], timeout: 5.0)
    }
    
    func testPurgeSessionDontWaitForTask() {
        let request = HTTPRequest.init(baseURL: "http://www.google.com", path: "", method: .GET, requestBody: nil, bodyEncoding: nil, requestHeaders: nil, queryParams: nil, queryParamsEncoding: nil, cachePolicy: nil, timeoutInterval: nil, networkServiceType: .default, bodyEncryption: nil)
        let requestId = netKitInstance.send(request: request, authDetail: nil) { _,_ in }
        XCTAssertNotNil(requestId)
        usleep(1000)
        netKitInstance.purgeSession(shouldCancelRunningTasks: true)
        let expectaion = XCTestExpectation.init(description: "\(#function)\(#file)\(#line)")
        netKitInstance.getAllRequests { (task) in
            XCTAssertEqual(task.count, 0)
            expectaion.fulfill()
        }
        wait(for: [expectaion], timeout: 5.0)
    }
    
    func testSessionDefault() {
        let delegate = TestURLSessionDelegate()
        let config = URLSessionConfiguration.default
        netKitInstance = NetKit.init(sessionConfiguration: config, sessionDelegate: delegate, commonHeaders: [:], waitsForConnectivity: true, waitingTimeForConnectivity: 0.0)
        XCTAssertNotNil(netKitInstance.session())
        XCTAssertNotNil(netKitInstance.session()?.delegate)
        XCTAssertEqual(config, netKitInstance.session()?.configuration)
    }
    
    func testSessionEphemeral() {
        let delegate = TestURLSessionDelegate()
        let config = URLSessionConfiguration.ephemeral
        netKitInstance = NetKit.init(sessionConfiguration: config, sessionDelegate: delegate, commonHeaders: [:], waitsForConnectivity: true, waitingTimeForConnectivity: 0.0)
        XCTAssertNotNil(netKitInstance.session())
        XCTAssertNotNil(netKitInstance.session()?.delegate)
        XCTAssertEqual(config, netKitInstance.session()?.configuration)
    }
    
    func testSessionBackground() {
        let delegate = TestURLSessionDelegate()
        let identifier = "\(UUID.init().uuidString)"
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        netKitInstance = NetKit.init(sessionConfiguration: config, sessionDelegate: delegate, commonHeaders: [:], waitsForConnectivity: true, waitingTimeForConnectivity: 0.0)
        XCTAssertNotNil(netKitInstance.session())
        XCTAssertNotNil(netKitInstance.session()?.delegate)
        XCTAssertEqual(config.identifier, netKitInstance.session()?.configuration.identifier)
    }
    
    func testSessionWaitingTime() {
        let delegate = TestURLSessionDelegate()
        let config = URLSessionConfiguration.default
        netKitInstance = NetKit.init(sessionConfiguration: config, sessionDelegate: delegate, commonHeaders: [:], waitsForConnectivity: true, waitingTimeForConnectivity: 0.0)
        XCTAssertNotNil(netKitInstance.session())
        XCTAssertEqual(config.timeoutIntervalForResource, netKitInstance.session()?.configuration.timeoutIntervalForResource)
    }
    
    func testSessionShouldWaitForConnectivity() {
        let delegate = TestURLSessionDelegate()
        let identifier = "\(UUID.init().uuidString)"
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        netKitInstance = NetKit.init(sessionConfiguration: config, sessionDelegate: delegate, commonHeaders: [:], waitsForConnectivity: true, waitingTimeForConnectivity: 0.0)
        XCTAssertNotNil(netKitInstance.session())
        XCTAssertNotNil(netKitInstance.session()?.delegate)
        XCTAssertEqual(config.waitsForConnectivity, netKitInstance.session()?.configuration.waitsForConnectivity)
    }
    
    func testSessionCommonHeaders() {
        let delegate = TestURLSessionDelegate()
        let identifier = "\(UUID.init().uuidString)"
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        netKitInstance = NetKit.init(sessionConfiguration: config, sessionDelegate: delegate, commonHeaders: ["Content-Type":"JSON"], waitsForConnectivity: true, waitingTimeForConnectivity: 0.0)
        XCTAssertNotNil(netKitInstance.session())
        XCTAssertNotNil(netKitInstance.session()?.delegate)
        XCTAssertEqual(netKitInstance.session()?.configuration.httpAdditionalHeaders as! [String: String], ["User-Agent": "xctest/15702 CFNetwork/1121.2.1 Darwin/19.6.0", "Accept-Language": "en-us", "Content-Type": "JSON"])
    }
}
