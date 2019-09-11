//
//  TokenStream.swift
//  LexerProtocol
//
//  Created by Marcus Rossel on 14.09.16.
//

/// A protocol for types that can generate a sequence of tokens.
public protocol TokenStream: Sequence, IteratorProtocol {
    
    associatedtype Token
    
    mutating func nextToken() -> Token
    
    /// Provides a customization point for the sequence-behaviour if needed.
    mutating func next() -> Token?
}

public extension TokenStream {
    /// The method needed to conform to `IteratorProtocol` and in turn `Sequence`.
    mutating func next() -> Token? {
        return nextToken()
    }
}
