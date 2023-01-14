//
//  FileWrapperEx.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 12/01/2023.
//

import Foundation
import PathKit

fileprivate let FM = FileManager.default




@dynamicMemberLookup
public class PWFileWrapper {
    
    struct InMemoryData {
        private var data: Data?
        var writeDate: Date
        
        init() {
            self.data = nil
            self.writeDate = .init()
        }
        
        mutating func update(newValue: Data?) {
            writeDate = .init()
            data = newValue
        }
        func read() -> Data? {
            data
        }
        
        var isEmpty: Bool { (data?.count ?? 0) > 0 }
        
        var size: Int {data?.count ?? 0}
    }
    
    var path: PathKit.Path
    
    var inMemory: InMemoryData
    
    var data: Data? {
        
        get {
            if path.exists {
                if path.isFile {
                    return try? path.read()
                }
            }
            
            return nil
        }
        set {
            if let newValue = newValue {
                try? path.write(newValue)
            }
        }
        
        
    }
    
    init(path: PathKit.Path) {
        self.path = path
        self.inMemory = .init()
    }
    
    subscript(dynamicMember member: String) -> PWFileWrapper {
        return PWFileWrapper(path: path + member )
    }
    
    
    
    var isDirectory: Bool { path.isDirectory }
    
    var isFile: Bool { path.isFile }
    
    var isSymlink: Bool { path.isSymlink }
    
    var exist: Bool { path.exists }
    
    var absolute: Path { path.absolute() }
    
    
    var fileName: String { path.lastComponentWithoutExtension }
    
    var Ext: String { path.extension ?? "" }
    
    func get(file: String) -> PWFileWrapper?  {
        let new = path + file
        if new.exists {
            return PWFileWrapper(path: new)
        }
        
        
        return nil
    }
    
    func folderContent() -> [PWFileWrapper] {
        if path.isDirectory {
            return path.iterateChildren().map(PWFileWrapper.init)
        }
        
        return []
    }
}


public class FileWrapperEx {
    
    public let file: FileWrapper
    public let path: PathKit.Path
    
    
    init(path: PathKit.Path) throws {
        self.file = try .init(url: path.url)
        self.path = path
    }
    
    init(file: FileWrapper, path: PathKit.Path) {
        self.file = file
        self.path = path
    }
    
    init(file: FileWrapper) {
        self.file = file
        self.path = .init(file.preferredFilename ?? "")
    }
    
    required init?(coder inCoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var fileWrappers: [String : FileWrapperEx] {
        if isDirectory {
            return (file.fileWrappers ?? [:]).mapValues({FileWrapperEx(file: $0, path: path + ($0.preferredFilename ?? "") )})
        }
        if isSymbolicLink {
            if let url = symbolicLinkDestinationURL,let file = try? FileWrapper(url: url) {
                
                if file.isDirectory {
                    return (file.fileWrappers ?? [:]).mapValues({FileWrapperEx(file: $0, path: Path(url.path ) + ($0.preferredFilename ?? "") )})
                }
            }
            
        }
        return [:]
    }
    
    
    public var fileAttributes: [String : Any] { file.fileAttributes }
    
    public var preferredFilename: String? { file.preferredFilename }
    
    public var regularFileContents: Data? { file.regularFileContents }
    
    public var isSymbolicLink: Bool { file.isSymbolicLink }
    
    public var isDirectory: Bool { file.isDirectory }
    
    public var isRegularFile: Bool { file.isRegularFile }
    
    public var symbolicLinkDestinationURL: URL? { file.symbolicLinkDestinationURL }
}


