//
//  File.swift
//  
//
//  Created by MusicMaker on 13/01/2023.
//

import Foundation
import PathKit


typealias PListDict = [String:any Decodable]





extension PathKit.Path: Codable {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(string)
    }
    
    public init(from decoder: Decoder) throws {
        self.init(stringLiteral: try decoder.singleValueContainer().decode(String.self))
    }
    
    
}

public struct SwiftPackage: Decodable {
    let name: String
    let url: String
    let min: String?
    let max: String?
    let branch: String?
    let dependencies: [SwiftPackage]
}

public struct WrapPackage: Decodable {

    public let name: String
    public let library: String
    public let dependencies: [WrapPackage]
    public let file: Path
    let swift_packages: [SwiftPackage]
    let plist_keys: String

    
    enum CodingKeys: CodingKey {
        case name
        case library
        case dependencies
        case file
        case swift_packages
        case plist_keys
    }
    
    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<WrapPackage.CodingKeys> = try decoder.container(keyedBy: WrapPackage.CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: WrapPackage.CodingKeys.name)
        self.library = try container.decode(String.self, forKey: WrapPackage.CodingKeys.library)
        self.dependencies = try container.decode([WrapPackage].self, forKey: WrapPackage.CodingKeys.dependencies)
        let _file = try container.decode(Path.self, forKey: WrapPackage.CodingKeys.file)
        if _file.lastComponent == "__init__.py" {
            self.file = _file.parent()
        } else {
            self.file = _file
        }
        self.swift_packages = try container.decode([SwiftPackage].self, forKey: WrapPackage.CodingKeys.swift_packages)
        self.plist_keys = try container.decode(String.self, forKey: .plist_keys)
        
    }
    

    public var sources: [Path] { (try? (file + "sources").children()) ?? []  }
    
    

    
}






