import XCTest
@testable import LexerProtocol

final class TokenStreamTests: XCTestCase {
    
    static var allTests = [
        ("testNextToken", testNextToken),
        ("testDefaultSequenceBehaviour", testDefaultSequenceBehaviour),
        ("testModifiedSequenceBehaviour", testModifiedSequenceBehaviour),
    ]
    
    /// A naïve token-stream structure used for testing purposes.
    final class TestTokenStream: TokenStream {
        func nextToken() -> Int {
            return 0
        }
    }
    
    /// A token-stream class, which provides a specific implementation for
    /// `IteratorProtocol`'s `next() -> Self.Element?` method.
    final class TestFiniteTokenStream: TokenStream {
        var counter = 0
        
        func nextToken() -> Int {
            return 1
        }
        
        /// Changes `TestFiniteTokenStream`'s sequence-behaviour to cut off after
        /// ten values have been generated.
        func next() -> Int? {
            guard counter < 10 else { return nil }
            counter += 1
            return nextToken()
        }
    }
    
    func testNextToken() {
        let tokenStream = TestTokenStream()
        
        for _ in 1...5 {
            XCTAssertEqual(tokenStream.nextToken(), 0)
        }
    }
    
    func testDefaultSequenceBehaviour() {
        let tokenStream = TestTokenStream()
        
        // Iterating over a `TokenStream` currently generates an infinite sequence.
        // Therefore the sequence is broken off after five iterations.
        for (index, token) in tokenStream.enumerated() {
            guard index < 5 else { break }
            XCTAssertEqual(token, 0)
        }
    }
    
    func testModifiedSequenceBehaviour() {
        let finiteTokenStream = TestFiniteTokenStream()
        
        /// Produces the same value ten times.
        for token in finiteTokenStream {
            XCTAssertEqual(token, 1)
        }
        
        XCTAssertEqual(finiteTokenStream.counter, 10)
    }
}
