//
//  FileWrapper+Extensions.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 12/01/2023.
//

import Foundation
import PythonSwiftLinkParser

extension FileWrapper {
    func wrapModule() async throws -> WrapModule {
        guard
            let data = regularFileContents,
            let string = String(data: data, encoding: .utf8),
            let name = preferredFilename
        else { throw CocoaError(.fileReadCorruptFile) }
        
        return await .init(fromAst: name, string: string)
    }
    
    func asyncCompactMap<T>(
        _ transform: (String,FileWrapper) async throws -> T?
    ) async rethrows -> [T] {
        return try await (fileWrappers ?? [:]).asyncCompactMap(transform )
    }
    
    func asyncCompactForEach<T>(
        _ transform: (String,FileWrapper) async throws -> T?,
        _ operation: (T) async throws -> Void
    ) async rethrows {
        return try await (fileWrappers ?? [:]).asyncCompactForEach(transform, operation)
    }
}


