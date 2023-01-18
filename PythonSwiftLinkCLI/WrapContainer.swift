//
//  WrapFolder+Project.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 15/01/2023.
//

import Foundation
import PathKit
import PythonSwiftCore





class XCProject: Decodable {
    let name: String
    let dependencies: [WrapPackage]
    let swift_packages: [SwiftPackage]
    let python_source: Path
    let linked_source: Bool
    
}

extension XCProject {
    
    func build() async throws {
        let wrap_builds = dependencies.map { "toolchain build \($0)"}.joined(separator: ",\n")
        
        let py_src: String = linked_source ? python_source.lastComponent : python_source.string
        print(ROOT_PATH + py_src)
        if linked_source { try? (ROOT_PATH + py_src).symlink(python_source) }
        
        try await Process().zsh_run(
            script: """
            #!/bin/zsh
            
            cd \(ROOT_PATH.string)
            . venv/bin/activate
            
            toolchain create \(name) \(py_src)
            
            """
        )
        
        
        let project = PySwiftProject.fromString("\(name)-ios")
        
        try await project.mod_newXCProj(root: ROOT_PATH )
        
        try ProjectFile(name: String(project.name), depends: []).write()
        
        project.load_project()
        
        try await dependencies.asyncForEach { package in try await package.build(target: project) }
        
        try project.backup()
        
        project.save()
        
        try project.updateWrapperImports()
    }
}


class WorkDirectory: Decodable {
    let python: String
    let projects: [XCProject]
    let pips: [String]
    let kivy_recipes: [String]
    let site_packages: Path?
}

extension WorkDirectory {
    
    func build() async throws {
        let recipe_installs = kivy_recipes.map { "toolchain build \($0)"}.joined(separator: ",\n")
        let pip_installs = pips.map { "toolchain pip install \($0)"}.joined(separator: ",\n")
        try await Process().zsh_run(
            script: """
            #!/bin/zsh
            
            cd \(ROOT_PATH.string)
            \(python) -m venv venv
            . venv/bin/activate
            pip install Cython==0.29.28
            pip install kivy-ios
            toolchain build python3
            toolchain build kivy
            \(recipe_installs)
            \(pip_installs)
            """
        )
        
        try run_setup()
        if let site = site_packages {
            try FolderSettings.update(withKey: .site_packages_path, value: site.absolute().string)
        }
        
        try await projects.asyncForEach{try await $0.build()}
    }
}


class WrapContainer: Decodable {
    let project: XCProject?
    let directory: WorkDirectory?
}

extension WrapContainer {
    
    func build() async throws {
        if let directory = directory {
            try await directory.build()
            return
        }
        if let project = project {
            try await project.build()
        }
    }

}










struct JSONCodingKeys: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}




extension KeyedDecodingContainer {
    
    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any>? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any>? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    
    mutating func decode(_ type: Array<Any>.Type) throws -> Array<Any> {
        var array: [Any] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<Any>.self) {
                array.append(nestedArray)
            }
        }
        return array
    }
    
    mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
