//
//  TokenStream.swift
//  LexerProtocol
//
//  Created by Marcus Rossel on 14.09.16.
//

/// A protocol for types that can generate a sequence of tokens.
public protocol TokenStream: AnyObject, Sequence, IteratorProtocol {
    
    associatedtype Token
    
    func nextToken() -> Token
    
    /// Provides a customization point for the sequence-behaviour if needed.
    func next() -> Token?
}

public extension TokenStream {
    /// The method needed to conform to `IteratorProtocol` and in turn `Sequence`.
    func next() -> Token? {
        return nextToken()
    }
}
