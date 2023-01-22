//
//  PythonSwiftLink_Project.swift
//  PythonSwiftLink
//
//  Created by MusicMaker on 27/12/2022.
//  Copyright © 2022 Example Corporation. All rights reserved.
//

import Foundation
import PathKit
import XcodeProj


let BRIDGE_STRING_NEW = """
#include "Python.h"
#include "PythonLib.h"

//Insert Other OBJ-C / C Headers Here:
"""

let XCODE_PATH = "/Applications/Xcode.app"

import ArgumentParser

final class PySwiftProject: ExpressibleByArgument {
    
    var name: String
    var project: XcodeProj?
    var project_dir: Path

    var xcodeproj: Path { project_dir + "\(name).xcodeproj" }
    
    
    init(path: PathKit.Path) {
        DEBUG_PRINT("PySwiftProject",path)
        
        
        
        self.name = path.lastComponent.replacingOccurrences(of: "-ios", with: "")
        project_dir = path
        
    }
    
    required convenience init?(argument: String) {
        
        let path = Path(argument)
        
        var target: Path
        
        let name = path.lastComponent.replacingOccurrences(of: "-ios", with: "")
        switch path {
        case let p where (p + "\(name).xcodeproj").exists:
            print("Using path")
            target = p
        case _ where (ROOT_PATH + "\(name).xcodeproj").exists:
            print("Using ROOT_PATH")
            target = ROOT_PATH
        default:
            print("I Pity the Fool who insert the wrong project path.. ")
            exit(1)
        }
        print(path,ROOT_PATH)
        
        self.init(path: target)
        currentProject = self
    }
    
    func load_project() {
        print("load_project", xcodeproj)
        project = try! .init(path: xcodeproj )
    }
    
    func get_or_create_group(_ group: String, parent: PBXGroup? = nil, relative: Bool = true) -> PBXGroup? {
        
        guard let pbxproj = project?.pbxproj else { return nil }
        
        if let first = pbxproj.groups.first(where: { $0.name == group }) {
            return first
        }
        let options: GroupAddingOptions = relative ? [.withoutFolder] : []
        //let g = PBXGroup(name: group)
        //pbxproj.add(object: g)
        if let parent = parent {
            let new = try? parent.addGroup(named: group, options: options)
            return new?.first
        }
        if let root = try? pbxproj.rootGroup() {
            
            let new = try? root.addGroup(named: group, options: options)
            return new?.first
        }
        //return g
        return nil
    }
    
    func remove_group_by_name(group_name: String) {
        guard let pbxproj = project?.pbxproj else { return }
        
        if let group = pbxproj.groups.first(where: {$0.name == group_name}) {
            DEBUG_PRINT("remove_group_by_name - name:", group_name)
            
            remove_group_children(group)
            pbxproj.delete(object: group)
            
        }
        if let group = pbxproj.groups.first(where: {$0.path == group_name}) {
            DEBUG_PRINT("remove_group_by_name - path:", group_name)
            remove_group_children(group)
            pbxproj.delete(object: group)
        }
        
    }
    private func remove_group_children(_ group: PBXGroup) {
        guard let pbxproj = project?.pbxproj else { return }
        for c in group.children {
            remove_from_build(c)
            pbxproj.delete(object: c)
        }
    }
    func remove_group(_ group: PBXGroup) {
        guard let pbxproj = project?.pbxproj else { return }
        if let root = try? pbxproj.rootGroup() {
            for c in root.children {
                DEBUG_PRINT(c.name, c.path)
            }
        }
    }
    
    var buildConfigurations_no_archs: [XCBuildConfiguration] {
        guard let pbxproj = project?.pbxproj else { return [] }
        return pbxproj.buildConfigurations.filter { b -> Bool in
            !b.buildSettings.keys.contains("ARCHS")
        }
    }
    
    func remove_framework_search_paths(list: [String]) {
        DEBUG_PRINT("remove_framework_search_paths:")
        for config in buildConfigurations_no_archs {
            if var fsp = config.buildSettings["FRAMEWORK_SEARCH_PATHS"] as? [String] {
                //var frames = fsp as! [String]
                DEBUG_PRINT(fsp)
                
                fsp.removeAll { key in
                    list.contains(key)
                }
                DEBUG_PRINT(fsp)
                config.buildSettings["FRAMEWORK_SEARCH_PATHS"] = fsp
            }
        }
        

    }
    func add_header_search_paths(_ headers: [String]) {
        guard let pbxproj = project?.pbxproj else { return }
        DEBUG_PRINT("add_header_search_paths",headers)
        for b in pbxproj.buildConfigurations {
            
            let build_keys = b.buildSettings.keys
            if !build_keys.contains(where: {$0 == "ARCHS"}) {
                if let fsp = b.buildSettings["HEADER_SEARCH_PATHS"] {
                    var frames = fsp as! [String]
                    DEBUG_PRINT(fsp)
                    frames.append(contentsOf: headers)
                    DEBUG_PRINT(frames)
                }
            }
            
        }
    }
    
    func add_file(path: Path, group: PBXGroup, copy: Bool = false) throws {
        let dst: Path = copy ? (project_dir + path.lastComponent) : path
        
        if copy {
            if dst.exists {
                //try dst.delete()
                return
            }
            try path.copy(dst)
        }
        
//        if copy {
//            let fileman = FileManager.default
//            let dst = dst.string
//            if fileman.fileExists(atPath: dst ) {
//                try fileman.removeItem(atPath: dst)
//            }
//            try fileman.copyItem(atPath: path.string, toPath: dst)
//        }
        
        
        guard let pbxproj = project?.pbxproj else { return }
        //DEBUG_PRINT("add_file", dst)
//        print(path, ":")
//        group.children.forEach { f in
//            let f_path = Path(f.path ?? "")
//            let f_last = f_path.lastComponent
//            let f_parent = f_path.parent().lastComponent
//
//            let path_last = path.lastComponent
//            let path_parent = path.parent().lastComponent
//
//
//            if f_last == path_last && f_parent == path_parent {
//                print("\t",f_last, path_last)
//            }
//        }
        
        guard group.children.first(where: { f in
            let f_path = Path(f.path ?? "")
            let f_last = f_path.lastComponent
            let f_parent = f_path.parent().lastComponent
            
            let path_last = path.lastComponent
            let path_parent = path.parent().lastComponent
            return f_last == path_last && f_parent == path_parent
        }) == nil else { return }

        let file = try group.addFile(at: dst, sourceRoot: project_dir)
        if let target = pbxproj.nativeTargets.first {
            let sourcesPhase = target.buildPhases.first(where: { $0.buildPhase == .sources }) as! PBXSourcesBuildPhase
            //if (sourcesPhase.files ?? []).first(where: { f in f.file?.path == file.path } ) != nil { return }
            
            _ = try sourcesPhase.add(file: file)
            
        }
        
    }
    
    func add_folder(path: Path, group: PBXGroup? = nil, copy: Bool = false) throws {
        guard let pbxproj = project?.pbxproj else { return }
        if let root = try pbxproj.rootGroup() {
            let group_name = path.lastComponent
            let group = get_or_create_group(group_name, parent: root, relative: !copy)!
            
            try path.forEach { file in
                let _file = path + file
                if _file.isDirectory {
                    let dir = get_or_create_group(file.lastComponent, parent: group, relative: !copy)!
                    try add_folder(path: _file, group: dir, copy: false)
                    return
                }
                try add_file(path: path + file, group: group, copy: copy)
            }
            
            
//            try FileManager.default.contentsOfDirectory(atPath: path.string).forEach { file in
//
//                let _file = path + file
//                if _file.isDirectory {
//                    let dir = get_or_create_group(file, parent: group, relative: !copy)!
//                    try add_folder(path: _file, group: dir, copy: false)
//                    return
//                }
//                try add_file(path: path + file, group: group, copy: copy)
//            }
        }
    }
    
    func add_package(repositoryURL: String, productName: String, version: XCRemoteSwiftPackageReference.VersionRequirement, target: String) {
        guard let root = project?.pbxproj.rootObject else { return }
        _ = try? root.addSwiftPackage(repositoryURL: repositoryURL, productName: productName, versionRequirement: version, targetName: target)
    }
    
    
    private func remove_from_build(_ element: PBXFileElement) {
        guard let pbxproj = project?.pbxproj else { return }
        if let target = pbxproj.nativeTargets.first {
            let sourcesPhase = target.buildPhases.first(where: { $0.buildPhase == .sources }) as! PBXSourcesBuildPhase
            for b in sourcesPhase.files ?? [] {
                if let file = b.file {
                    if file.name == element.name {
                        pbxproj.delete(object: b)
                    }
                }
            }
            
        }
    }
    
    func remove_file(name ref: String, group: PBXGroup? = nil) {
        guard let pbxproj = project?.pbxproj else { return }
        if let group = group {
            
            if let file = group.children.first(where: { f in f.path == ref }) {
                remove_from_build(file)
                pbxproj.delete(object: file)
                DEBUG_PRINT("deleted by group")
                
                return
            }
            
        }
        if let file = pbxproj.fileReferences.first(where: {$0.path == ref }) {
            remove_from_build(file)
            pbxproj.delete(object: file)
        }
        
    }
    
    
    func set_flags(_ key: String, _ value: StringLiteralType) {
        guard let pbxproj = project?.pbxproj else { return }
        DEBUG_PRINT("set_flags",key, value)
        
        let configs = pbxproj.buildConfigurations.filter({!$0.buildSettings.keys.contains(where: {$0 == "ARCHS"})})
        configs.forEach({$0.buildSettings[key] = value})
//        for b in pbxproj.buildConfigurations {
//
//            let build_keys = b.buildSettings.keys
//            if !build_keys.contains(where: {$0 == "ARCHS"}) {
//                b.buildSettings[key] = value
//            }
//        }
    }
    
    
    func backup() throws {
        let pbxproj = xcodeproj + "project.pbxproj"
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyy_HHmmss_SSS"
        let date: String = formatter.string(from: .init())
        try pbxproj.copy(xcodeproj + "project.pbxproj_\(date).backup")
    }
    
    
    func save() {
        guard let proj = project else { return }
        try! proj.write(path: xcodeproj)
    }
//}
//
//
//
//
//public class PythonSwiftLink_Project {
//
//    let FM = FileManager.default
//
//    let name: String
//
//    let xc_handler: XcodeProjectNew
//
//    let path_url: URL
    
    
    
    
    
//    public init(url: URL, name: String) {
//
//        self.name = name
//        path_url = url
//        xc_handler = .init(url: url, name: name)
//    }
//
//    public init(path: Path) {
//        let name = path.lastComponent
//        let url = path.url
//        self.name = name
//        self.path_url = url
//        xc_handler = .init(url: url, name: name)
//        DEBUG_PRINT(self,"INIT",path_url)
//    }
    
    
    public func mod_newXCProj(root: PathKit.Path) async throws {
        DEBUG_PRINT("mod_newXCProj:")
        let system_files = root + "system_files"
        DEBUG_PRINT(system_files, project_dir)
        //let xc = xc_handler
        load_project()
        let admob_mode = false
        
        //let project_dir = project_dir
        
        
        
//        if !FM.fileExists(atPath: bridge_header) {
//            let bridge_string = BRIDGE_STRING_NEW
//            try! bridge_string.write(to: bridge_header_url, atomically: true, encoding: .utf8)
//        }
        
        var frameworks_search_paths = [String]()
        for x in 14...17 {
            for i in 0...14 {
                frameworks_search_paths.append("\(XCODE_PATH)/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator\(x).\(i).sdk/System/Library/Frameworks")
            }}
        remove_framework_search_paths(list: frameworks_search_paths)
        
        if !Sources.exists {
            try Sources.mkdir()
        }
        let _sources = get_or_create_group("Sources")!
        remove_file(name: "main.m", group: _sources)
        
        remove_group_by_name(group_name: "Classes")
        
        guard let _classes = get_or_create_group("Objc-Classes") else { return }
        
        let support_files = system_files + "project_support_files"
        //try add_file(path: support_files + "AppDelegate.swift" , group: _sources)
        //let pythonobjectsupport = support_files + "PythonObjectSupport"
        
        
        let pythonlib = system_files + "PythonLib/Sources/PythonLib"
        try add_file(path: pythonlib + "include/PythonLib.h", group: _classes, copy: true)
        try add_file(path: pythonlib + "PythonLib.c", group: _classes, copy: true)
        
        let pythonswiftcore = system_files + "PythonSwiftCore/Sources/PythonSwiftCore"
        try add_folder(path: pythonswiftcore)
        
        
        let filtered_support_files = try support_files.children().compactMap { item -> Path? in
            //DEBUG_PRINT(item.string)
            if item.isDirectory { return nil }
            
            if item.extension == "swift" {
                if [
                    "old_PythonSupport.swift",
                    "JsonSupport.swift",
                    "PythonSupport.swift",
                    "PythonMain.swift",
                    //"AppDelegate.swift",
                    "Main.swift"
                ].contains(item.lastComponent) { return nil }
                
                return item
            }
            return nil
        }
        
        try filtered_support_files.forEach { file in
            let dst = Sources + file.lastComponent
            try? file.copy(dst)
            try add_file(path: dst, group: _sources)
        }
        
        
        
        try pythonSwiftImports.write( PythonSwiftImportList_Template(wrappers: []) )
        try! add_file(path: pythonSwiftImports, group: _sources)
        
        
        if !wrapper_builds.exists {
            try wrapper_builds.mkdir()
        }
        if !wrapper_sources.exists {
            try wrapper_sources.mkdir()
        }
        
        if !bridge_header.exists {
            try bridge_header.write(BRIDGE_STRING_NEW)
            try add_file(path: bridge_header, group: _classes)
            
        }
        
        set_flags("SWIFT_OBJC_BRIDGING_HEADER", bridge_header.lastComponent)
        set_flags("SWIFT_VERSION", "5.0")
        set_flags("IPHONEOS_DEPLOYMENT_TARGET", "11.0")
        
        try backup()
        save()

        
    }
    
//    static func updateWrapperImports(path: String) throws {
//        let project_dir = URL(fileURLWithPath: path)
//        let FM = FileManager.default
//        let wrappers = try FM.contentsOfDirectory(atPath: project_dir.appendingPathComponent("wrapper_builds").path)
//            .filter({$0.contains(".swift")})
//            .map{$0.replacingOccurrences(of: ".swift", with: "")}
//
//        DEBUG_PRINT(wrappers)
//
//
//        let wrapper_import_url = project_dir.appendingPathComponent("PythonSwiftImports.swift")
//        try PythonSwiftImportList_Template(wrappers: wrappers).write(to: wrapper_import_url, atomically: true, encoding: .utf8)
//    }
    
    func updateWrapperImports() throws {
        let wrappers = wrapper_builds.compactMap { file in
            if file.extension == "swift" {
                return file.lastComponentWithoutExtension
            }
            return nil
        }
        let import_string = PythonSwiftImportList_Template(wrappers: wrappers)
        
        try pythonSwiftImports.write(import_string)
    }
}


extension PySwiftProject {
    var bridge_header: Path { project_dir + "\(name)-Bridging-Header.h" }
    
    //var bridge_header: String { bridge_header_url.string }
    
    var working_dir: Path { .current }
    
    var wrapper_sources: Path { project_dir + "wrapper_sources"}
    
    var wrapper_builds: Path { project_dir + "wrapper_builds"}
    
    var projectFile: ProjectFile {
        ( project_dir + "project.json").url.projectFile ?? .init(name: name, depends: [])
    }
    
    var Sources: Path { project_dir + "Sources" }
    
    var pythonSwiftImports: Path { Sources + "PythonSwiftImports.swift" }
    
    var plist: Path { project_dir + "\(name)-Info.plist"}
}
