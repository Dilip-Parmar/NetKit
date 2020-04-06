# NetKit
A simple HTTP library written in Swift (URLSession Wrapper). It has VIPER like architecture that makes it easy to understand.

<div>
<a href="https://guides.cocoapods.org/">
<img src="https://img.shields.io/badge/Pod1.6.1-Compatible-brightgreen.svg" />
</a>
<a href="https://github.com/Carthage/Carthage">
<img src="https://img.shields.io/badge/Carthage-Compatible-orange.svg" />
</a>
<a href="https://swift.org/">
<img src="https://img.shields.io/badge/Swift5.0-Compatible-brightgreen.svg" />
</a>
<a href="https://swift.org/package-manager">
<img src="https://img.shields.io/badge/swift--package--manager-Compatible-yellow.svg" />
</a>
</div>

## Table of Contents

* [Features](#Features)
* [Requirements](#Requirements)
* [Installation](#Installation)
* [How to use](#How-to-use)
    * [Initialization](#Initialization)
    * [Single Request](#Single-Request)
    * [Download File Request](#Download-File-Request)
        * [Pause download request](#Pause-download-request)
        * [Resume download request](#Resume-download-request)
    * [Upload File Request](#Upload-File-Request)
        * [Pause upload request](#Pause-upload-request)
        * [Resume upload request](#Resume-upload-request)
    * [Cancel Request](#Cancel-Request)
    * [SSL Certificate Pinning](#SSL-Certificate-Pinning)
    * [HTTP Basic Authentication](#HTTP-Basic-Authentication)
    * [HTTP Digest Authentication](#HTTP-Digest-Authentication)
    * [Network Monitor](#Network-Monitor)
    * [Destroy Session](#Destroy-Session)
* [Author](#Author)
* [License](#License)
* [TODO](#TODO)

## Features

- Singleton free
- No external dependencies
- Simple and Configurable Request
- Single Data Call
- Resumable Download file request 
- Resumable Upload file request
- Cancellable requests
- Network Monitor for network connectivity
- Request Body/Query Parameters Encoding
- SSL Certificate Pinning
- HTTP Basic Authentication
- HTTP Digest Authentication
- Request Body Encryption (SHA256)
- Free

## Requirements

- iOS 12.0+ / macOS 10.14+ / tvOS 12.0+ / watchOS 5.0+
- Xcode 10.2+
- Swift 5+

## Installation

**NetKit** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'NetKit', :git => 'https://github.com/Dilip-Parmar/NetKit'
```

**NetKit** is also available through [Carthage](https://github.com/Carthage/Carthage). To install it, simply add the following line to your Cartfile:

```ruby
github "Dilip-Parmar/NetKit"  "2.0.0" //always use latest release version
```

**NetKit** is also available through [Swift Package Manager](https://swift.org/package-manager/). To install it, simply enter given URL into "Enter Package Repository URL" search field of Xcode.

```ruby
https://github.com/Dilip-Parmar/NetKit
```
## How to use
## Initialization
```ruby
let netKit = NetKit.init(sessionConfiguration: sessionConfiguration, sessionDelegate: nil, commonHeaders: ["Content-Type":"application/json"], waitsForConnectivity: false, waitingTimeForConnectivity: 300)
```
It's easy to provide session configuration. The available types are Default, Ephemeral and Background.
Use [URLSessionConfiguration](https://developer.apple.com/documentation/foundation/urlsessionconfiguration) to get one of the available type.

- `Default` -
`let sessionConfiguration = URLSessionConfiguration.default`

- `Ephemeral` -
`let sessionConfiguration = URLSessionConfiguration.ephemeral`

- `Background` -
`let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "CUSTOM UNIQUE IDENTIFIER")`

`sessionDelegate` - You may have such requirement where a controller class should be an instance of URLSessionDelegate instead of Network library itself. NetKit gives that flexibility by using custom delegate.

`let commonHeaders = ["Content-Type":"application/json"]` 

`waitsForConnectivity` - should NetKit fails immediately or wait for network connectivity.

`waitingTimeForConnectivity` - in seconds.

## Single Request
```ruby
let queryParames = ["country":"in", "apiKey":"daae11"]
let request = HTTPRequest.init(baseURL: "https://www.google.com", path: "/safe", method: .GET, requestBody: nil, bodyEncoding: nil, requestHeaders: ["Content-Type":"application/json"], queryParams: queryParames, queryParamsEncoding: .default, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60, networkServiceType: .background, bodyEncryption: nil)

let taskId = netkit.send(request: request, authDetail: nil, completionBlock: { (urlResponse, result) in
switch result {
    case .failure(let failure):
    switch failure {
        default:
            break
    }
    case .success(let success):
        switch success {
        case .block(let data, let response):
            if let data = data {
            let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            print(response)
            print(json)
           }
        }
    }
})
```
## Download File Request
```ruby
let queryParames = ["country":"in", "apiKey":"daae11"]
let request = HTTPRequest.init(baseURL: "https://www.google.com", path: "/safe", method: .GET, requestBody: nil, bodyEncoding: nil, requestHeaders: ["Content-Type":"application/json"], queryParams: queryParames, queryParamsEncoding: .default, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 120, networkServiceType: .background, bodyEncryption: nil)

let taskId = netkit.sendDownload(request: request, authDetail: nil, progressBlock: { (progress) in
print(progress)
}, completionBlock: { (urlResponse, result) in
    switch result {      
      case .success(let success):
        switch success {
            case .block(let url, let response):
        }
      case .failure(let failure):
        switch failure {
        default:
        }      
    }
})
```
## Pause download request

```ruby
netkit.pauseDownloadRequestBy(taskId: taskId)
```

## Resume download request
```ruby
netkit.resumeDownloadRequestBy(taskId: taskId)
```

## Upload File Request
```ruby
let fileURL = URL.init(fileURLWithPath: "/Users/...../file.jpg")
let taskId = netkit.sendUpload(request: request, fileURL: fileURL, authDetail: nil, progressBlock: { (progress) in
print(progress)
}, completionBlock: { (urlResponse, result) in

})
```
## Pause Upload request

```ruby
netkit.pauseUploadRequestBy(taskId: taskId)
```
## Resume Upload request
```ruby
netkit.resumeUploadRequestBy(taskId: taskId)
```
## Cancel Request
```ruby
//Cancel given request
netkit.cancelRequestBy(taskId: taskId, taskType: .download)

//Cancel all requests
netkit.cancelAllRequests()
```
## SSL Certificate Pinning
```ruby
let queryParames = ["country":"in", "apiKey":"daae11"]
let request = HTTPRequest.init(baseURL: "https://www.google.com", path: "/safe", method: .GET, requestBody: nil, bodyEncoding: nil, requestHeaders: ["Content-Type":"application/json"], queryParams: queryParames, queryParamsEncoding: .default, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60, networkServiceType: .background, bodyEncryption: nil)

let authDetail = AuthDetail.init(authType: .serverTrust, shouldValidateHost: true, host: "google.com", userCredential: nil, certificateFileName: "my-certificate")

let taskId = netkit.send(request: request, authDetail: authDetail, completionBlock: { (urlResponse, result) in
    switch result {
    case .failure(let failure):
        switch failure {
        default:
            break
        }
    case .success(let success):
        switch success {
        case .block(let data, let response):
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                print(response)
                print(json)
            }
        }
    }
})
```
## HTTP Basic Authentication
```ruby
let queryParames = ["country":"in", "apiKey":"daae11"]
let request = HTTPRequest.init(baseURL: "https://www.google.com", path: "/safe", method: .GET, requestBody: nil, bodyEncoding: nil, requestHeaders: ["Content-Type":"application/json"], queryParams: queryParames, queryParamsEncoding: .default, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60, networkServiceType: .background, bodyEncryption: nil)

let userCredential = URLCredential.init(user: "user", password: "password", persistence: .forSession)

let authDetail = AuthDetail.init(authType: .HTTPBasic, shouldValidateHost: true, host: "google.com", userCredential: userCredential, certificateFileName: nil)

let taskId = netkit.send(request: request, authDetail: authDetail, completionBlock: { (urlResponse, result) in
    switch result {
    case .failure(let failure):
        switch failure {
        default:
            break
    }
    case .success(let success):
    switch success {
        case .block(let data, let response):
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                print(response)
                print(json)
            }
        }
    }
})
```
## HTTP Digest Authentication
```ruby
let queryParames = ["country":"in", "apiKey":"daae11"]
let request = HTTPRequest.init(baseURL: "https://www.google.com", path: "/safe", method: .GET, requestBody: nil, bodyEncoding: nil, requestHeaders: ["Content-Type":"application/json"], queryParams: queryParames, queryParamsEncoding: .default, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60, networkServiceType: .background, bodyEncryption: nil)

let userCredential = URLCredential.init(user: "user", password: "password", persistence: .forSession)

let authDetail = AuthDetail.init(authType: .HTTPDigest, shouldValidateHost: true, host: "google.com", userCredential: userCredential, certificateFileName: nil)

let taskId = netkit.send(request: request, authDetail: authDetail, completionBlock: { (urlResponse, result) in
    switch result {
    case .failure(let failure):
        switch failure {
        default:
            break
        }
    case .success(let success):
        switch success {
        case .block(let data, let response):
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                print(response)
                print(json)
            }
        }
    }
})
```
## Network Monitor
Register for these notifications to get notified for network status.
`NetworkStatusNotification.Available` 
`NetworkStatusNotification.Offline` 

```ruby
NotificationCenter.default.addObserver(self, selector: #selector(netwokConnected(aNotification:)), name: NSNotification.Name.init(NetworkStatusNotification.Available), object: nil)

NotificationCenter.default.addObserver(self, selector: #selector(waitingForNetwork(aNotification:)), name: NSNotification.Name.init(NetworkStatusNotification.Offline), object: nil)
```
## Destroy Session

```ruby
netkit.purgeSession(shouldCancelRunningTasks: true)
```
## Author

[Dilip Parmar](https://github.com/Dilip-Parmar)

## License

NetKit is released under the MIT license. [See LICENSE](https://github.com/Dilip-Parmar/NetKit/blob/master/LICENSE) for details.

## TODO:
Unit test cases
