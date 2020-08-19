import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(carthage_cacheTests.allTests),
    ]
}
#endif
