// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -cxx-interoperability-mode=upcoming-swift -Xcc -std=c++17)
//
// REQUIRES: executable_test

import StdlibUnittest
import StdOptional
import CxxStdlib

var StdOptionalTestSuite = TestSuite("StdOptional")

StdOptionalTestSuite.test("pointee") {
  let nonNilOpt = getNonNilOptional()
  let pointee = nonNilOpt.pointee
  expectEqual(123, pointee)

  var modifiedOpt = getNilOptional()
  modifiedOpt.pointee = 777
  expectEqual(777, modifiedOpt.pointee)
}

StdOptionalTestSuite.test("std::optional => Swift.Optional") {
  let nonNilOpt = getNonNilOptional()
  let swiftOptional = Optional(fromCxx: nonNilOpt)
  expectNotNil(swiftOptional)
  expectEqual(123, swiftOptional!)

  let nilOpt = getNilOptional()
  let swiftNil = Optional(fromCxx: nilOpt)
  expectNil(swiftNil)
}

StdOptionalTestSuite.test("std::optional hasValue/value") {
  let nonNilOpt = getNonNilOptional()
  expectTrue(nonNilOpt.hasValue)
  expectEqual(123, nonNilOpt.value!)

  let nilOpt = getNilOptional()
  expectFalse(nilOpt.hasValue)
  expectNil(nilOpt.value)
}

StdOptionalTestSuite.test("std::optional as ExpressibleByNilLiteral") {
  let res1 = takesOptionalInt(nil)
  expectFalse(res1)

  let res2 = takesOptionalString(nil)
  expectFalse(res2)
}

runAllTests()
