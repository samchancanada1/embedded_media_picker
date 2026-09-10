import Flutter
import UIKit
import XCTest

// If your plugin has been explicitly set to "type: .dynamic" in the Package.swift,
// you will need to add your plugin as a dependency of RunnerTests within Xcode.

@testable import embedded_media_picker

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testEmbeddedPickerAvailability() {
    let plugin = EmbeddedMediaPickerPlugin()

    let call = FlutterMethodCall(methodName: "isEmbeddedPickerAvailable", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! Bool, false)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
