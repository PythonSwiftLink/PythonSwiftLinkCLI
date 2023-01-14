//
//  SwiftTools+Install.swift
//  PythonSwiftLinkCLI
//


import Foundation
import ArgumentParser
import PathKit
import PythonLib
import PythonSwiftCore

import SwiftyJSON
import SwiftPrettyPrint
import WrapperPackageHandler

import PyCodable

fileprivate let json_dumps = pythonImport(from: "json", import_name: "dumps").pyPointer


extension JSON: ConvertibleFromPython {
    public init(_ object: PythonSwiftCore.PythonObject) {
        let dump = json_dumps(object.ptr)
        self.init(stringLiteral: (try? .init(object: dump)) ?? "")
    }
    
    public init?(_ ptr: PythonSwiftCore.PyPointer) {
        return nil
    }
    
    public init(object: PythonSwiftCore.PyPointer) throws {
        let dump: String = try .init(object: json_dumps.xINCREF(object))
        let data = dump.data(using: .utf8)!
        PyErr_Print()
        try self.init(data: data, options: .fragmentsAllowed)
    }
    
    
    
}

extension PythonSwiftLinkCLI.SwiftTools {
    
    
    struct Install: AsyncParsableCommand {
        
        @Flag var library: PythonSwiftLinkCLI.SwiftTools.Library
        //@Argument() var package: String
        @Argument() var packages: [String] = []
        
        
        func run() async throws {
            try await checkSwiftTools()
            
            guard let project = currentProject else { return }
            
            let folder_path: Path
            switch library {
                
            case .plyer:
                folder_path = SWIFT_TOOLS + "plyer"
            case .standard:
                folder_path = SWIFT_TOOLS + "standard"
            }
            //let folder = try FileWrapperEx(path: folder_path)
            //let folder = PWFileWrapper(path: folder_path)
 
            PythonHandler.shared.start(
                stdlib: APP_FOLDER.appendingPathComponent("python-stdlib").path,
                app_packages: PYTHON_EXTRA_MODULES,
                debug: true
            )
            project.xc_handler.load_project()
            try await packages.asyncForEach { package in
                let pack = folder_path + package
                let wrap_package = try getSwiftToolsPack(pack: pack)
                try await handleSwiftToolsPack(project, wrap_package)
                
                // Add builded wrappers.swift to xcode group "PythonSwiftWrappers"
                if let group = project.xc_handler.get_or_create_group("PythonSwiftWrappers") {

                    try project.wrapper_builds.forEach { p in
                        if p.lastComponent == ".DS_Store" { fatalError() }
                        try project.xc_handler.add_file(path: p, group: group)
                    }
                }
                
            }
     
            project.xc_handler.save()
            
            try project.updateWrapperImports()
            
            
            
            
        }
        
    }
}

func getSwiftToolsPack(pack: PathKit.Path) throws -> WrapPackage {
    let pack_init = (pack + "__init__.py")
    let code = try pack_init.read(.utf8)
    
    let kw = PyDict_New()
    
    //root py file will not include __file__ when using PyRun_String in that state
    PyDict_SetItem(kw, "__file__", pack_init.string.pyPointer)
    let fp = fopen(pack.string, "rb")
    
//    let result = PyRun_File(fp, pack.string, 257, kw, kw)
//    PyErr_Print()
    let result = PyRun_String(string: code, flag: .file, globals: kw, locals: kw)
    
    if result == nil {
        PyErr_Print()
        throw PythonError.attribute
    }

    let dump: PyPointer = PyDict_GetItem(kw, "package")(method: "dump")
    
    let package = try PyDecoder().decode(WrapPackage.self, from: dump)
    
//    print()
//    Pretty.prettyPrint(package)
//    print()
    return package
}

func handleSwiftToolsPack(_ project: PythonSwiftLink_Project, _ package: WrapPackage) async throws {
    print("handleSwiftToolsPack")

    
    
    
    
    let wrapper_builds = project.wrapper_builds
    
    if !wrapper_builds.exists {
        try wrapper_builds.mkdir()
    } else {
        guard wrapper_builds.isDirectory else { throw CocoaError(.fileWriteNoPermission)}
    }
    let pack_path = package.file
    
    let pack_sources = package.sources
    
    try await pack_sources.asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data ) in
        try! (wrapper_builds + "\(name).swift").write(swift)
        
        if let site = site_packages_folder {
            try! (site + "\(name).py").write(site_file)
        }
        
        try pack_sources.forEach { src in
            let wrap_src = (project.wrapper_sources + src.lastComponent)
            if wrap_src.exists { try wrap_src.delete() }
            try src.copy(wrap_src)
        }
        
        if let group = project.xc_handler.get_or_create_group("Sources") {
            try pack_sources.filter({$0.extension == "swift"}).forEach { swift in
                try project.xc_handler.add_file(path: swift, group: group)
            }
            
        }
    }
    
    
    let xc = project
    for dep in package.depends {
        
        if dep.file.exists {
            let dep_sources = dep.sources

            try await dep_sources.asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data) in
                
                // put the builded wrapper into wrapper_builds
                try (wrapper_builds + "\(name).swift").write(swift)
                
                // put the pure python version of the wrapper into site-packages
                if let site = site_packages_folder {
                    try (site + "\(name).py").write(swift)
                }
            }
            // Add all .swift from depend sources to project
            if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
                try dep_sources.filter({$0.extension == "swift"}).forEach { swift in
                    try xc.xc_handler.add_file(path: swift, group: group)
                }
                
            }
            
            try ProjectFile.updateDepends(add: dep.name)
        }
    }
}




fileprivate func handlePack(_ project: PythonSwiftLink_Project, _ pack: Path) async throws {
    let wrapper_builds = project.wrapper_builds
    
    if !wrapper_builds.exists {
        try wrapper_builds.mkdir()
    } else {
        guard wrapper_builds.isDirectory else { throw CocoaError(.fileWriteNoPermission)}
    }
    
    
    let pack_sources = pack + "sources"
    
    try await pack_sources.asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data ) in
        try! (wrapper_builds + "\(name).swift").write(swift)
        
        if let site = site_packages_folder {
            try! (site + "\(name).py").write(site_file)
        }
        
        try pack_sources.forEach { src in
            let wrap_src = (project.wrapper_sources + src.lastComponent)
            if wrap_src.exists { try wrap_src.delete() }
            try src.copy(wrap_src)
        }
    }
    
    let xc = project
    xc.xc_handler.load_project()
    
    if let config = pack.wrapPackage?.wrapPackageConfig {
        let proj_debs = project.projectFile.depends
        
        for dep in config.depends {
            print(dep)
            
            let dep_path = SWIFT_TOOLS + dep
            if dep_path.exists {
                
                //let deb_file = try FileWrapperEx(path: dep_path)
                
                try await dep_path.asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data) in
                    
                    try (wrapper_builds + "\(name).swift").write(swift)
                    
                    if let site = site_packages_folder {
                        try (site + "\(name).py").write(swift)
                    }
                }
                if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
                    try dep_path.filter({$0.extension == "swift"}).forEach { swift in
                        try xc.xc_handler.add_file(path: swift, group: group)
                    }
                    
                }
                
                try ProjectFile.updateDepends(add: dep)
            }
        }
    }
}

fileprivate func handlePack(_ project: PythonSwiftLink_Project, _ pack: FileWrapperEx) async throws {
    let wrapper_builds = project.wrapper_builds
    
    if !wrapper_builds.url.exist {
        try FileManager.default.createDirectory(at: wrapper_builds.url, withIntermediateDirectories: true)
    }
    let pack_sources = pack.sourceFiles
    try await pack_sources.asyncCompactForEach(handleWrapperFileEx) { (swift: FileWrapper, site_file: FileWrapper) in
        if let swift_name = swift.preferredFilename {
            try swift.write(to: (wrapper_builds + swift_name).url, originalContentsURL: nil)
        }
        
        if let site = site_packages_folder, let py_name = site_file.preferredFilename {
            try site_file.write(to: (site + py_name).url, originalContentsURL: nil)
        }
        
        try pack_sources.forEach { src in
            try src.file.write(to: (project.wrapper_sources + (src.preferredFilename ?? "")).url, originalContentsURL: nil)
        }
    }
    
    
    let xc = project
    xc.xc_handler.load_project()
    
    var depends_to_add = [String]()
    
    if let config = pack.wrapPackage?.wrapPackageConfig {
        let proj_debs = project.projectFile.depends
        
        for dep in config.depends {
            print(dep)
            //if proj_debs.contains(where: {$0.name == dep}) { continue }
            
            let dep_path = SWIFT_TOOLS + dep
            if dep_path.url.exist {
                
                let deb_file = try FileWrapperEx(path: dep_path)
                
                try await deb_file.asyncCompactForEach(handleWrapperFileEx) { (swift: FileWrapper, site_file: FileWrapper) in
                    
                    if let swift_name = swift.preferredFilename {
                        try swift.write(to: (wrapper_builds + swift_name).url, originalContentsURL: nil)
                    }
                    
                    if let site = site_packages_folder, let py_name = site_file.preferredFilename {
                        try site_file.write(to: (site + py_name).url, originalContentsURL: nil)
                    }
                    
                    if let site = site_packages_folder, let py_name = site_file.preferredFilename {
                        try site_file.write(to: (site + py_name).url, originalContentsURL: nil)
                    }
                }
                if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
                    try await deb_file.files(ofType: .swift).asyncForEach { swift in
                        
                        try xc.xc_handler.add_file(path: swift.path, group: group)
                    }
                    
                }
                
                
                try! ProjectFile.updateDepends(add: dep)
            }
        }
    }
    
    
    if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
        
        try FileManager.default.contentsOfDirectory(at: wrapper_builds.url, includingPropertiesForKeys: nil).forEach { url in
            if url.lastPathComponent == ".DS_Store" { return }
            try xc.xc_handler.add_file(path: url.Path, group: group)
        }
        
    }
    
    if let source_group = xc.xc_handler.get_or_create_group("Sources") {
        try await pack.targetFiles.asyncForEach { target in
            try xc.xc_handler.add_file(path: target.path, group: source_group, copy: true)
        }
    }
    
    
}



fileprivate func json_vs_py_decoder(_ dump: PyPointer) throws {
    //else { throw PythonError.unicode }
    print(PyDict_Size(dump))
    print("begining pydict test:")
    var start: DispatchTime
    var end: DispatchTime
    var nanoTime: UInt64
    var timeInterval: Double
    //pyPrint(dump)
    
    start = .now()
    let py_decoder = PyDecoder()
    try py_decoder.decode(WrapPackage.self, from: dump)
    end = .now()
    
    nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
    
    print("PyDictDecoder : total \(timeInterval) seconds")
    
    var jdump = json_dumps(dump.xINCREF)
    PyErr_Print()
    print(_Py_REFCNT(dump))
    start = .now()
    print(_Py_REFCNT(jdump))
    var buf = PythonUnicode_DATA(jdump.xINCREF)!
    var s = PyObject_Size(jdump)
    var data = Data(bytesNoCopy: buf, count: s, deallocator: .none)
    var decoder = JSONDecoder()
    try decoder.decode(WrapPackage.self, from: data)
    end = .now()
    
    nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
    
    print("JSONDecoder : total \(timeInterval) seconds")
    
    start = .now()
    jdump = json_dumps(dump)
    buf = PythonUnicode_DATA(jdump)!
    s = PyObject_Size(jdump)
    data = Data(bytesNoCopy: buf, count: s, deallocator: .none)
    decoder = JSONDecoder()
    try decoder.decode(WrapPackage.self, from: data)
    end = .now()
    
    nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
    
    print("JSONDecoder with jdump: total \(timeInterval) seconds")
}
