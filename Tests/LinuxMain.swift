import XCTest

import autoHatMiniTests

var tests = [XCTestCaseEntry]()
tests += autoHatMiniTests.allTests()
XCTMain(tests)
