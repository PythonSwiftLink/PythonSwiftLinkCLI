//
//  PBXProjWrapper.swift
//  PythonSwiftLink
//
//  Created by MusicMaker on 10/12/2022.
//  Copyright © 2022 Example Corporation. All rights reserved.
//

import Foundation
//import PythonLib
//import PythonSwiftCore
import XcodeProj
import PathKit


public extension Path {
//    static func +(lhs: Path, rhs: String) -> Path {
//        lhs + Path(rhs)
//    }
    
//    static func += (lhs: Path, rhs: StringLiteralType) -> Path {
//        lhs + Path(stringLiteral: rhs)
//    }
}

class XcodeProjectNew {
    
    var name: String
    var project: XcodeProj?
    var project_dir: Path
    //var project_dir_path: Path
    let hmm = "\("").xcodeproj"
    var xcodeproj_path: Path { project_dir + "\(name).xcodeproj" }
    
    init(url: URL, name: String) {
        print("XcodeProjectNew",name,url)
        //let project_path = url.appendingPathComponent("\(name).xcodeproj", isDirectory: true)
        self.name = name.replacingOccurrences(of: "-ios", with: "")
        project_dir = url.Path
                
    }
    func load_project() {
        print("load_project", xcodeproj_path)
        project = try! .init(path: xcodeproj_path )
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
            print("remove_group_by_name - name:", group_name)
            
            remove_group_children(group)
            pbxproj.delete(object: group)
            
        }
        if let group = pbxproj.groups.first(where: {$0.path == group_name}) {
            print("remove_group_by_name - path:", group_name)
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
                print(c.name, c.path)
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
        print("remove_framework_search_paths:")
        //guard let configs = buildConfigurations_no_archs else { return }
        for config in buildConfigurations_no_archs {
            if var fsp = config.buildSettings["FRAMEWORK_SEARCH_PATHS"] as? [String] {
                //var frames = fsp as! [String]
                print(fsp)
                
                fsp.removeAll { key in
                    list.contains(key)
                }
                print(fsp)
                config.buildSettings["FRAMEWORK_SEARCH_PATHS"] = fsp
            }
        }
//        return
//        guard let pbxproj = project?.pbxproj else { return }
//
//        for b in pbxproj.buildConfigurations {
//
//            let build_keys = b.buildSettings.keys
//            if !build_keys.contains(where: {$0 == "ARCHS"}) {
//
//                if let fsp = b.buildSettings["FRAMEWORK_SEARCH_PATHS"] {
//                    var frames = fsp as! [String]
//                    print(fsp)
//                    frames.removeAll { key in
//                        list.contains(key)
//                    }
//                    print(frames)
//                }
//            }
//
//        }
    }
    func add_header_search_paths(_ headers: [String]) {
        guard let pbxproj = project?.pbxproj else { return }
        print("add_header_search_paths",headers)
        for b in pbxproj.buildConfigurations {
            
            let build_keys = b.buildSettings.keys
            if !build_keys.contains(where: {$0 == "ARCHS"}) {
                if let fsp = b.buildSettings["HEADER_SEARCH_PATHS"] {
                    var frames = fsp as! [String]
                    print(fsp)
                    frames.append(contentsOf: headers)
                    print(frames)
                }
            }
            
        }
    }
    
    func add_file(path: Path, group: PBXGroup, copy: Bool = false) throws {
        let dst: Path = copy ? (project_dir + path.lastComponent) : path
        if copy {
            let fileman = FileManager.default
            let dst = dst.string
            if fileman.fileExists(atPath: dst ) {
                try fileman.removeItem(atPath: dst)
            }
            try fileman.copyItem(atPath: path.string, toPath: dst)
        }
        
        
        guard let pbxproj = project?.pbxproj else { return }
        print("add_file", dst)
        let file = try group.addFile(at: dst, sourceRoot: project_dir)
        if let target = pbxproj.nativeTargets.first {
            let sourcesPhase = target.buildPhases.first(where: { $0.buildPhase == .sources }) as! PBXSourcesBuildPhase
            _ = try sourcesPhase.add(file: file)
            
        }
        
    }
    
    func add_folder(path: Path, group: PBXGroup? = nil, copy: Bool = false) throws {
        guard let pbxproj = project?.pbxproj else { return }
        if let root = try pbxproj.rootGroup() {
            let group_name = path.lastComponent
            let group = get_or_create_group(group_name, parent: root, relative: !copy)!
            try FileManager.default.contentsOfDirectory(atPath: path.string).forEach { file in
                
                let _file = path + file
                if _file.isDirectory {
                    let dir = get_or_create_group(file, parent: group, relative: !copy)!
                    try add_folder(path: _file, group: dir, copy: false)
                    return
                }
                try add_file(path: path + file, group: group, copy: copy)
            }
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
                print("deleted by group")
                
                return
            }
            
        }
        if let file = pbxproj.fileReferences.first(where: {$0.path == ref }) {
            remove_from_build(file)
            pbxproj.delete(object: file)
        }
        
    }
    
    func set_flags(_ key: String, _ value: String) {
        guard let pbxproj = project?.pbxproj else { return }
        print("set_flags",key, value)
        for b in pbxproj.buildConfigurations {
            
            let build_keys = b.buildSettings.keys
            if !build_keys.contains(where: {$0 == "ARCHS"}) {
                b.buildSettings[key] = value
            }
        }
    }
    func backup() {
        let root = xcodeproj_path + .init("project.pbxproj")
        copyItem(from: root.string, to: "\(root)_\(Date()).backup")
    }
    
    func save() {
        guard let proj = project else { return }
        try! proj.write(path: xcodeproj_path)
    }
}

//class XcodeProject {
//    
//    var project: PythonObject
//    
//    
//    init(url: URL, name: String) {
//        print("class XcodeProject init:")
//        let project_path = url.appendingPathComponent("\(name).xcodeproj", isDirectory: true).appendingPathComponent("project.pbxproj")
//        print(project_path)
//        //if FM.fileExists(atPath: project_path.path) {
//        project = XcodeProject_cls.load(path: project_path.path).pyObject
////        } else {
////            print("xc proj not found",project_path.path)
////            return
////        }
//    }
//    
//    
//    
//    func get_or_create_group(name: String, path: String? = nil, parent: PyPointer = .PyNone, make_relative: Bool = false) -> PythonObject {
//        let n = name.pyPointer
//        var _path: PyPointer
//        if let path = path {
//            _path = path.pyPointer
//        } else {
//            _path = .PyNone
//        }
//        let relative = make_relative.pyPointer
//        let result = PyObject_VectorcallMethod(get_or_create_group_str, [project.ptr, n, _path, parent, relative], 5, nil).pyObject
//        if result.ptr == nil {
//            PyErr_Print()
//        }
//        n.decref()
//        _path.decref()
//        relative.decref()
//        return result
//    }
//    
//    func remove_group_by_name(group_name: String, recursive: Bool = true) {
//        //let remove_group = PyObject_GetAttr(project.ptr, "remove_group_by_name")
//        let n = group_name.pyPointer
//        let r = recursive.pyPointer
//        //let args = [n].pythonTuple
//        PyErr_Print()
//        //PyObject_CallMethodOneArg(project.ptr, remove_group_by_name_str,project.p, n)
//        //guard let result = PyObject_Call(remove_group, args, nil) else {
//        guard let result = PyObject_VectorcallMethod(remove_group_by_name_str, [project.ptr, n, r], 3, nil) else {
//            PyErr_Print()
//            n.decref()
//            r.decref()
//            return
//        }
//        Py_DecRef(result)
//        //remove_group.decref()
//        n.decref()
//        r.decref()
//        
//        
//    }
//    fileprivate let remove_files_by_path_str = "remove_files_by_path".pyPointer
//    func remove_files_by_path(path: URL) {
//        let p = path.pyPointer
//        pyPrint(p)
//        if let result = PyObject_VectorcallMethod(remove_files_by_path_str, [project.ptr, p], 2, nil) {
//            
//        } else {
//            PyErr_Print()
//        }
//        
//        
//    }
//    
//    func remove_files_by_path(path: String) {
//        let p = path.pyPointer
//        pyPrint(p)
//        if let result = PyObject_VectorcallMethod(remove_files_by_path_str, [project.ptr, p], 2, nil) {
//            
//        } else {
//            PyErr_Print()
//        }
//        
//        
//    }
//    
//    fileprivate let get_files_by_name_str = "get_files_by_name".pyPointer
//    func get_files_by_name( name: String, parent: PyPointer = .PyNone) -> PythonObject {
//        let n = name.pyPointer
//        let p = parent != nil ? parent.xINCREF : .PyNone
//        
//        let result = PyObject_VectorcallMethod(get_files_by_name_str, [project.ptr,  n, p], 3, nil)
//        n.decref()
//        p.decref()
//        return .init(getter: result)
//        
//    }
//    
//    func remove_framework_search_paths(paths: String, target_name: String? = nil, configuration_name: String? = nil) {
//        //return
//        //print("remove_framework_search_paths")
//        //print("remove_framework_search_paths: \(paths)")
//        let p = paths.pyPointer
//        var t: PyPointer
//        var c: PyPointer
//        if let target_name = target_name { t = target_name.pyPointer } else { t = .PyNone}
//        if let configuration_name = configuration_name { c = configuration_name.pyPointer } else { c = .PyNone}
//        let result = PyObject_VectorcallMethod(remove_framework_search_paths_str, [project.ptr, p, t, c], 4, nil)
//        //yproject.ptr.decref()
//        p.decref()
//        t.decref()
//        c.decref()
//        result.decref()
//    }
//    
//    //func remove_files_by_path(path,
//    
//    func remove_file_by_id(file_id: PyConvertible, target_name: String? = nil) {
//        //return
//        print("remove_file_by_id")
//        var t: PyPointer
//        if let target_name = target_name {
//            t = target_name.pyPointer
//        } else { t = .PyNone }
//        if let result = PyObject_VectorcallMethod(remove_file_by_id_str, [project.ptr, file_id.pyPointer, t], 3, nil) {
//            pyPrint(result)
//            result.pyPointer.decref()
//        }
//        //let result = PyObject_CallMethodOneArg(project.ptr, remove_file_by_id_str, file_id.pyPointer)
////        if result == nil {
////            PyErr_Print()
////            t.decref()
////            return
////        }
//        //project.ptr.decref()
//        t.decref()
//        //result.decref()
//    }
//    
//    func add_file(path: URL, parent: PyPointer = nil, forced: Bool = true) {
//        //return
//        print("add_file:", path.path)
//        //let add_file = project.getAttr(key: "add_file")?.pyObject
//        //let add_file = PyObject_GetAttr(project.ptr, "add_file")
//        let p = path.pyPointer
//        var _parent: PyPointer
//        let f = forced.pyPointer
//        if parent != nil {
//            _parent = parent.xINCREF
//        } else { _parent = .PyNone }
////        let kw = PyDict_New()
////        PyDict_SetItem(kw, "parent", _parent)
////        PyDict_SetItem(kw, "forced", f)
//        let kw = ["","parent","forced"].pythonTuple
//        //let result = PyObject_Vectorcall(add_file, [ p, _parent], 2, nil)
//        let result = PyObject_VectorcallMethod(add_file_str, [project.ptr, p, _parent], 3, nil)
//        if result == nil {
//            PyErr_Print()
//        }
//        p.decref()
//        f.decref()
//        _parent.decref()
//        kw.decref()
//        result.decref()
//        //add_file.decref()
//    }
//    
//    func add_package(repository_url: String, package_requirement: PyConvertible, product_name: PyConvertible, target_name: String) {
//        return
//        let r = repository_url.pyPointer
//        let pr = package_requirement.pyPointer
//        let pn = product_name.pyPointer
//        let t = target_name.pyPointer
//        let result = PyObject_VectorcallMethod(add_package_str, [project.ptr, r, pr, pn, t], 5, nil)
//        r.decref()
//        pr.decref()
//        pn.decref()
//        t.decref()
//        
//        result.decref()
//    }
//    
//    func add_header_search_paths(paths: PyConvertible, recursive:Bool=true, escape:Bool=false, target_name:String?=nil, configuration_name:String?=nil) {
//        print("add_header_search_paths")
//        let p = paths.pyPointer
//        let r = recursive.pyPointer
//        let e = escape.pyPointer
//        let t = target_name != nil ? target_name?.pyPointer : .PyNone
//        let c = configuration_name != nil ? configuration_name?.pyPointer : .PyNone
//        let result = PyObject_VectorcallMethod(add_header_search_paths_str, [project.ptr, p, r, e, t, c], 6, nil)
//        p.decref()
//        r.decref()
//        e.decref()
//        t.decref()
//        c.decref()
//        result.decref()
//    }
//    
//    func set_flags(_ flag_name: String , flags: String, target_name: String?=nil, configuration_name: String?=nil) {
//        print("set_flags")
//        let n = flag_name.pyPointer
//        let f = flags.pyPointer
//        let t = target_name != nil ? target_name?.pyPointer : .PyNone
//        let c = configuration_name != nil ? configuration_name?.pyPointer : .PyNone
//        let result = PyObject_VectorcallMethod(set_flags_str, [project.ptr, n, f, t, c], 5, nil)
//        n.decref()
//        f.decref()
//        t.decref()
//        c.decref()
//        result.decref()
//    }
//    
//    func backup() {
//        print(self,"backup")
//        let result = PyObject_CallMethodNoArgs(project.ptr, backup_str)
//        
//        PyErr_Print()
//        result.decref()
//    }
//    
//    func save() {
//        print(self,"save")
//        let result = PyObject_CallMethodNoArgs(project.ptr, save_str)
//        
//        PyErr_Print()
//        result.decref()
//    }
//}
