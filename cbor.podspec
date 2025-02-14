#
#  Be sure to run `pod spec lint libIso18013.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "cbor"
  spec.version      = "0.0.1"
  spec.summary      = "The library offers functions to handle objects in CBOR format and manages COSE signing and verification"

  spec.description  = <<-DESC
                  The library offers a specific set of functions to handle objects in CBOR format. It also supports the creation and verification of COSE signatures.
                   DESC

  spec.homepage     = "https://github.com/pagopa/cbor-ios"

  spec.license      = { :type => "MIT", :file => "../LICENSE" }

  spec.authors = [
    "acapadev",
    "MartinaDurso95"
  ]

  spec.ios.deployment_target = '16.0'

  spec.source                  = { :http => "https://github.com/pagopa/cbor-ios/releases/download/0.0.1/cbor-0.0.1.xcframework.zip" }
  spec.ios.vendored_frameworks = "cbor.xcframework"

  spec.pod_target_xcconfig = { 
    'SWIFT_INCLUDE_PATHS' => '$(inherited) ${PODS_BUILD_DIR}/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }

end
