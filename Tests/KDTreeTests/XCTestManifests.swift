import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(KDTree2DimensionTests.allTests),
        testCase(KDTree3DimensionTests.allTests),
    ]
}
#endif
