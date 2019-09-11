import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TokenStreamTests.allTests),
        testCase(LexerProtocolTests.allTests),
    ]
}
#endif
