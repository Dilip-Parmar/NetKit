Pod::Spec.new do |spec|

  spec.name         = "NetKit"
  spec.version      = "2.0.1"
  spec.summary      = "A short description of NetKit."
  spec.description  = <<-DESC

- Singleton free
- No external dependencies
- Simple and Configurable Request
- Data Call
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
DESC

  spec.homepage     = "https://github.com/Dilip-Parmar/NetKit"
  spec.license      = "MIT"
  spec.author             = { "Dilip Parmar" => "dp.sgsits@gmail.com" }
  spec.authors            = { "Dilip Parmar" => "dp.sgsits@gmail.com" }

  # spec.platform     = :ios
  # spec.platform     = :ios, "12.0"

  spec.ios.deployment_target = "12.0"
  spec.osx.deployment_target = "10.14"
  spec.watchos.deployment_target = "5.0"
  spec.tvos.deployment_target = "12.0"

  spec.source       = { :git => "https://github.com/Dilip-Parmar/NetKit.git", :tag => spec.version }
  spec.source_files  = "Sources", "Sources/**/*.swift"
  spec.source_files  = "Sources", "Sources/**/**/*.swift"
  #spec.exclude_files = "Classes/Exclude"

  spec.public_header_files = "iOS/**/*.h"
  spec.public_header_files = "OSX/**/*.h"
  spec.public_header_files = "tvOS/**/*.h"
  spec.public_header_files = "watchOS/**/*.h"
  spec.requires_arc = true

end
