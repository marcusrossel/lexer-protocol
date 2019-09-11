import XCTest
@testable import LexerProtocol

// Helper method.
fileprivate extension Character {
    func isPart(of set: CharacterSet) -> Bool {
        return String(self).rangeOfCharacter(from: set) != nil
    }
}

final class LexerProtocolTests: XCTestCase {
    
    static var allTests = [
        ("testInitializer", testInitializer),
        ("testNextCharacter", testNextCharacter),
        ("testNextToken", testNextToken),
    ]
    
    /// A naïve token structure used for testing purposes.
    struct TestToken: Equatable {
        var type: String
        var value: String
        
        static func ==(lhs: TestToken, rhs: TestToken) -> Bool {
            return (lhs.type, lhs.value) == (rhs.type, rhs.value)
        }
    }
    
    /// A simple non-specific lexer-class used for testing purposes.
    final class TestLexer: LexerProtocol {
        // The compiler can't infer `Token`'s type from the given information, so
        // an explicit typealias is needed.
        typealias Token = TestToken
        
        var text = ""
        var position = 0
        var endOfText: Character = "\0"
        
        var defaultTransform: (inout Character, TestLexer) -> TestToken
        var tokenTransforms: [(inout Character, TestLexer) -> TestToken?] = []
        
        init(
            text: String = "",
            defaultTransform:
            @escaping (inout Character, TestLexer) -> TestToken
            ) {
            self.text = text
            self.defaultTransform = defaultTransform
        }
    }
    
    func testInitializer() {
        // Tests the bare minimum initializer (only passing the `defaultTransform`).
        var lexer = TestLexer { buffer, lexer in
            defer { buffer = lexer.nextCharacter() }
            return TestToken(type: "Undefined", value: String(buffer))
        }
        
        // `text` should be empty and every call on `nextToken()` should produce the
        // token returned by the `defaultTransform`.
        XCTAssertTrue(lexer.text.isEmpty)
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "\0"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "\0"))
        
        // Initializes `lexer` with additional transforms for ignoring whitespaces,
        // and lexing single new-line characters.
        lexer = TestLexer { buffer, lexer in
            defer { buffer = lexer.nextCharacter() }
            return TestToken(type: "Undefined", value: String(buffer))
        }
        lexer.tokenTransforms = [
            { buffer, lexer in
                while buffer.isPart(of: .whitespaces) {
                    buffer = lexer.nextCharacter()
                }
                return nil
            },
            { buffer, lexer in
                guard buffer.isPart(of: .newlines) else { return nil }
                
                buffer = lexer.nextCharacter()
                return TestToken(type: "NewLine", value: "\n")
            }
        ]
        
        // `text` should be empty and every call on `nextToken()` should produce the
        // token returned by the `defaultTransform`.
        XCTAssertTrue(lexer.text.isEmpty)
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "\0"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "\0"))
        
        // Resets `lexer`.
        lexer.position = 0
        lexer.text = " \n  a\n"
        
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "NewLine", value: "\n"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "a"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "NewLine", value: "\n"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "\0"))
        
        // Initializes `lexer` with an initial `text`.
        lexer = TestLexer(text: "1\n") { buffer, lexer in
            defer { buffer = lexer.nextCharacter() }
            return TestToken(type: "Undefined", value: String(buffer))
        }
        
        XCTAssertEqual(lexer.text, "1\n")
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "1"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "\n"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "\0"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Undefined", value: "\0"))
    }
    
    func testNextCharacter() {
        var lexer = TestLexer(text: "01234") { buffer, lexer in
            defer { buffer = lexer.nextCharacter() }
            return TestToken(type: "", value: "")
        }
        
        // Tests the default call (`peek == false`, `stride == 1`).
        for position in 0...5 {
            XCTAssertEqual(lexer.position, position)
            let _ = lexer.nextCharacter()
        }
        
        /* Not quite happy with this yet. Should be `5`. */
        XCTAssertEqual(lexer.position, 6)
        
        // Resets `lexer`.
        lexer.position = 0
        
        // Tests peeking at a character (`peek == true`, `stride == 1`).
        for _ in 0...100 {
            let character = lexer.nextCharacter(peek: true)
            XCTAssertEqual(character, "0")
        }
        
        XCTAssertEqual(lexer.position, 0)
        
        // Resets `lexer`.
        lexer.position = 0
        
        // Tests increasing the `stride` (`peek == false`, `stride > 1`).
        XCTAssertEqual(lexer.nextCharacter(stride: 3), "2")
        XCTAssertEqual(lexer.nextCharacter(stride: 2), "4")
        XCTAssertEqual(lexer.nextCharacter(stride: 5), "\0")
        XCTAssertEqual(lexer.position, 5)
        
        // Tests changing the `endOfText` character.
        lexer.endOfText = "_"
        XCTAssertEqual(lexer.nextCharacter(), "_")
    }
    
    func testNextToken() {
        // Defines a `TestLexer` with an initial text, and three `tokenTransforms`:
        // for lexing whitespaces, identifiers and integers.
        var lexer = TestLexer(text: "&    1101 ab0c _") { buffer, lexer in
            defer { buffer = lexer.nextCharacter() }
            return TestToken(type: "", value: "")
        }
        lexer.tokenTransforms = [
            { buffer, lexer in
                guard buffer.isPart(of: .whitespaces) else { return nil }
                repeat {
                    buffer = lexer.nextCharacter()
                } while buffer.isPart(of: .whitespaces)
                return TestToken(type: "Whitespace", value: " ")
            },
            { buffer, lexer in
                guard buffer.isPart(of: .letters) else { return nil }
                var identifierBuffer = ""
                repeat {
                    identifierBuffer.append(buffer)
                    buffer = lexer.nextCharacter()
                } while buffer.isPart(of: .alphanumerics)
                return TestToken(type: "Identif", value: identifierBuffer)
            },
            { buffer, lexer in
                guard buffer.isPart(of: .decimalDigits) else { return nil }
                var integerBuffer = ""
                repeat {
                    integerBuffer.append(buffer)
                    buffer = lexer.nextCharacter()
                } while buffer.isPart(of: .decimalDigits)
                return TestToken(type: "Integer", value: integerBuffer)
            }
        ]
        
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "", value: ""))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Whitespace", value: " "))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Integer", value: "1101"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Whitespace", value: " "))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Identif", value: "ab0c"))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "Whitespace", value: " "))
        XCTAssertEqual(lexer.nextToken(), TestToken(type: "", value: ""))
    }
}
