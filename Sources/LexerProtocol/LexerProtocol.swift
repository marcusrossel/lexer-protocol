//
//  LexerProtocol.swift
//  LexerProtocol
//
//  Created by Marcus Rossel on 14.09.16.
//

public protocol LexerProtocol: TokenStream {
    /// A token-transform that is guaranteed to produce a token.
    ///
    /// - Note: `GuaranteedTransform` is expected to set `buffer` to the next
    /// relevant character before it returns.
    typealias GuaranteedTransform = (
        _ buffer: inout Character,
        _ lexer: inout Self
    ) -> Token
    
    /// A token-transform that might produce a token or could fail.
    ///
    /// - Note: `PossibleTransform` is expected to set `buffer` to the next
    /// relevant character before it returns.
    typealias PossibleTransform = (
        _ buffer: inout Character,
        _ lexer: inout Self
    ) -> Token?
    
    /// The plain text, which will be lexed.
    var text: String { get set }
    
    /// Used to keep track of the next relevant character in `text`.
    var position: Int { get set }
    
    /// The character that signifies that the end of `text` is reached.
    ///
    /// - Note: This character is used to circumvent the need to return an
    /// optional from `nextCharacter()`.
    var endOfText: Character { get set }
    
    /// A default `GuaranteedTransform` which is called when all other
    /// `tokenTransforms` fail.
    var defaultTransform: GuaranteedTransform { get set }
    
    /// A sequence of `PossibleTransform`s, which will be called in order in
    /// `nextToken()`.
    ///
    /// - Note: These transforms are inteded to perform the pattern matching,
    /// aswell. If a pattern does not match `nil` should be returned.
    var tokenTransforms: [PossibleTransform] { get set }
}

public extension LexerProtocol {
    /// Returns the the next character in `text`.
    ///
    /// - Note: If `position` has reached `text`'s maximum index `endOfFile` is
    /// returned on every subsequent call.
    ///
    /// - Parameter peek: Determines whether or not the `position` will be
    /// incremented or not.
    /// - Parameter stride: The offset from the current `position` that the
    /// character to be returned is at. The `stride` also affects the amount by
    /// which `position` will be increased.
    mutating func nextCharacter(peek: Bool = false, stride: Int = 1) -> Character {
        guard stride >= 1 else {
            fatalError("Lexer Error: \(#function): `stride` must be >= 1.\n")
        }
        
        let nextCharacterIndex = position + stride - 1
        
        defer {
            if !peek && nextCharacterIndex <= text.count {
                position += stride
            }
        }
        guard nextCharacterIndex < text.count else { return endOfText }
        
        return text[text.index(text.startIndex, offsetBy: position + stride - 1)]
    }
    
    /// Returns the next `Token` according to the following system:
    ///
    /// 1. Stores the next relevant character in a buffer.
    /// 2. Sequentially calls the `tokenTransforms`.
    /// 3. If one of the `tokenTransforms` does not return `nil`, its `Token` is
    /// returned.
    /// 4. If all `tokenTransforms` return `nil` the `defaultTransform`'s return
    /// value is returned.
    /// 5. The pending buffer character is restored by decrementing `position`.
    mutating func nextToken() -> Token {
        var buffer = nextCharacter()
        defer { position -= 1 }
        
        for transform in tokenTransforms {
            if let token = transform(&buffer, &self) {
                return token
            }
        }
        
        return defaultTransform(&buffer, &self)
    }
}
