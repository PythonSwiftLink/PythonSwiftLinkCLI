//
//  Sequence+Extension.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 12/01/2023.
//

import Foundation


extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
    
    func asyncCompactForEach<T>(
        _ transform: (Element) async throws -> T?,
        _ operation: (T) async throws -> Void
    ) async rethrows {
        for element in self {
            if let item = try await transform(element) {
                try await operation(item)
            }
        }
    }
    
    
}

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
    
    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            if let item = try await transform(element) {
                values.append(item)
            }
            
        }
        
        return values
    }
    
    
}

extension Collection {
    @inlinable
    public __consuming func split_(
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true,
        includeSeparator: Bool = false,
        whereSeparator isSeparator: (Element) throws -> Bool
    ) rethrows -> [SubSequence] {
        var result: [SubSequence] = []
        var subSequenceStart: Index = startIndex
        
        func appendSubsequence(end: Index) -> Bool {
            if subSequenceStart == end && omittingEmptySubsequences {
                return false
            }
            result.append(self[subSequenceStart..<end])
            return true
        }
        
        if maxSplits == 0 || isEmpty {
            _ = appendSubsequence(end: endIndex)
            return result
        }
        
        var subSequenceEnd = subSequenceStart
        let cachedEndIndex = endIndex
        while subSequenceEnd != cachedEndIndex {
            if try isSeparator(self[subSequenceEnd]) {
                let didAppend = appendSubsequence(end: subSequenceEnd)
                if includeSeparator {
                    subSequenceStart = subSequenceEnd
                    formIndex(after: &subSequenceEnd)
                } else {
                    formIndex(after: &subSequenceEnd)
                    subSequenceStart = subSequenceEnd
                }
                
                if didAppend && result.count == maxSplits {
                    break
                }
                continue
            }
            formIndex(after: &subSequenceEnd)
        }
        
        if subSequenceStart != cachedEndIndex || !omittingEmptySubsequences {
            result.append(self[subSequenceStart..<cachedEndIndex])
        }
        
        return result
    }
    
}
