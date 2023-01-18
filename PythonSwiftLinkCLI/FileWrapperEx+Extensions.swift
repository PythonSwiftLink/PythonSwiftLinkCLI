//
//  FileWrapperEx+Extensions.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 12/01/2023.
//

import Foundation
import PythonSwiftLinkParser
import PathKit


public protocol WrapPackageEx {
    var sourceFiles: [FileWrapperEx] { get }
    var targetFiles: [FileWrapperEx] { get }
    var wrapPackage: FileWrapperEx? { get }
    //var wrapPackageConfig: WrapPackageConfig? { get }
}

extension FileWrapperEx {
    func wrapModule() async throws -> WrapModule {
        guard
            let data = regularFileContents,
            let string = String(data: data, encoding: .utf8),
            let name = preferredFilename
        else { throw CocoaError(.fileReadCorruptFile) }
        
        return await .init(fromAst: name, string: string)
    }
    
    func asyncCompactMap<T>(
        _ transform: (String,FileWrapperEx) async throws -> T?
    ) async rethrows -> [T] {
        return try await fileWrappers.asyncCompactMap( transform )
    }
    
    func asyncCompactForEach<T>(
        _ transform: (String,FileWrapperEx) async throws -> T?,
        _ operation: (T) async throws -> Void
    ) async rethrows {
        return try await fileWrappers.asyncCompactForEach(transform, operation)
    }
    
    func get(file name: String) -> FileWrapperEx? {
        if let result = file.fileWrappers?.first(where: { (key: String, value: FileWrapper) in
            key == name
        }) {
            return FileWrapperEx(file: result.value, path: path + name)
        }
        
        return nil
    }
    //func files(ofType type: FileWrapper.FileType) -> [FileWrapperEx] { files(ofType: type.rawValue) }
    
    func files(ofType type: String) -> [FileWrapperEx] {
        return fileWrappers.compactMap { k,v in
            if v.isRegularFile {
                if k.lowercased().contains(type) {
                    return v
                }
            }
            return nil
        }
    }
}

//extension FileWrapperEx: WrapPackageEx {
//    public var sourceFiles: [FileWrapperEx] {
//        if let sources = get(file: "sources") {
//            return sources.fileWrappers.map(\.value)
//        }
//        return []
//    }
//
//    public var targetFiles: [FileWrapperEx] {
//        if let sources = get(file: "targets") {
//            return sources.fileWrappers.map(\.value)
//        }
//        return []
//    }
//
////    public var wrapPackage: FileWrapperEx? {
////        guard let pack = file.wrapPackage else { return nil }
////        return .init(file: pack, path: path + "package.json" )
////    }
////
////    public var wrapPackageConfig: WrapperPackageHandler.WrapPackageConfig? {
////        file.wrapPackageConfig
////    }
////
//
//}

//extension PathKit.Path {
//    public var wrapPackage: Path? {
//
//        if isDirectory, let pack = self.first(where: {$0.lastComponent == "package.json"}) {
//            return pack
//        }
//        return nil
//    }
//
//    public var wrapPackageConfig: WrapPackageConfig? {
//
//        if let data = try? read(), let config = try? JSONDecoder().decode(WrapPackageConfig.self, from: data) {
//            return config
//        }
//
//        return nil
//    }
//}
