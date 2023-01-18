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

//import PyCodable

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
            PythonHandler.shared.defaultRunning.toggle()
            
            let folder_path: Path
            switch library {
                
            case .plyer:
                folder_path = SWIFT_TOOLS + "plyer"
            case .standard:
                folder_path = SWIFT_TOOLS + "standard"
            }

//            PythonHandler.shared.start(
//                stdlib: APP_FOLDER.appendingPathComponent("python-stdlib").path,
//                app_packages: PYTHON_EXTRA_MODULES,
//                debug: true
//            )
            project.load_project()

            try await packages.asyncForEach { pack in try await WrapPackage.fromPath(folder_path + pack).build(target: project) }
     
            project.save()
            
            try project.updateWrapperImports()
            
            
            
            
        }
        
    }
}







//fileprivate func handlePack(_ project: PythonSwiftLink_Project, _ pack: Path) async throws {
//    let wrapper_builds = project.wrapper_builds
//
//    if !wrapper_builds.exists {
//        try wrapper_builds.mkdir()
//    } else {
//        guard wrapper_builds.isDirectory else { throw CocoaError(.fileWriteNoPermission)}
//    }
//
//
//    let pack_sources = pack + "sources"
//
//    try await pack_sources.asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data ) in
//        try! (wrapper_builds + "\(name).swift").write(swift)
//
//        if let site = site_packages_folder {
//            try! (site + "\(name).py").write(site_file)
//        }
//
//        try pack_sources.forEach { src in
//            let wrap_src = (project.wrapper_sources + src.lastComponent)
//            if wrap_src.exists { try wrap_src.delete() }
//            try src.copy(wrap_src)
//        }
//    }
//
//    let xc = project
//    xc.xc_handler.load_project()
//
//    if let config = pack.wrapPackage?.wrapPackageConfig {
//        let proj_debs = project.projectFile.depends
//
//        for dep in config.depends {
//            print(dep)
//
//            let dep_path = SWIFT_TOOLS + dep
//            if dep_path.exists {
//
//                //let deb_file = try FileWrapperEx(path: dep_path)
//
//                try await dep_path.asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data) in
//
//                    try (wrapper_builds + "\(name).swift").write(swift)
//
//                    if let site = site_packages_folder {
//                        try (site + "\(name).py").write(swift)
//                    }
//                }
//                if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
//                    try dep_path.filter({$0.extension == "swift"}).forEach { swift in
//                        try xc.xc_handler.add_file(path: swift, group: group)
//                    }
//
//                }
//
//                try ProjectFile.updateDepends(add: dep)
//            }
//        }
//    }
//}

//fileprivate func handlePack(_ project: PythonSwiftLink_Project, _ pack: FileWrapperEx) async throws {
//    let wrapper_builds = project.wrapper_builds
//
//    if !wrapper_builds.url.exist {
//        try FileManager.default.createDirectory(at: wrapper_builds.url, withIntermediateDirectories: true)
//    }
//    let pack_sources = pack.sourceFiles
//    try await pack_sources.asyncCompactForEach(handleWrapperFileEx) { (swift: FileWrapper, site_file: FileWrapper) in
//        if let swift_name = swift.preferredFilename {
//            try swift.write(to: (wrapper_builds + swift_name).url, originalContentsURL: nil)
//        }
//
//        if let site = site_packages_folder, let py_name = site_file.preferredFilename {
//            try site_file.write(to: (site + py_name).url, originalContentsURL: nil)
//        }
//
//        try pack_sources.forEach { src in
//            try src.file.write(to: (project.wrapper_sources + (src.preferredFilename ?? "")).url, originalContentsURL: nil)
//        }
//    }
//
//
//    let xc = project
//    xc.xc_handler.load_project()
//
//    var depends_to_add = [String]()
//
//    if let config = pack.wrapPackage?.wrapPackageConfig {
//        let proj_debs = project.projectFile.depends
//
//        for dep in config.depends {
//            print(dep)
//            //if proj_debs.contains(where: {$0.name == dep}) { continue }
//
//            let dep_path = SWIFT_TOOLS + dep
//            if dep_path.url.exist {
//
//                let deb_file = try FileWrapperEx(path: dep_path)
//
//                try await deb_file.asyncCompactForEach(handleWrapperFileEx) { (swift: FileWrapper, site_file: FileWrapper) in
//
//                    if let swift_name = swift.preferredFilename {
//                        try swift.write(to: (wrapper_builds + swift_name).url, originalContentsURL: nil)
//                    }
//
//                    if let site = site_packages_folder, let py_name = site_file.preferredFilename {
//                        try site_file.write(to: (site + py_name).url, originalContentsURL: nil)
//                    }
//
//                    if let site = site_packages_folder, let py_name = site_file.preferredFilename {
//                        try site_file.write(to: (site + py_name).url, originalContentsURL: nil)
//                    }
//                }
//                if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
//                    try await deb_file.files(ofType: .swift).asyncForEach { swift in
//
//                        try xc.xc_handler.add_file(path: swift.path, group: group)
//                    }
//
//                }
//
//
//                try! ProjectFile.updateDepends(add: dep)
//            }
//        }
//    }
//
//
//    if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
//
//        try FileManager.default.contentsOfDirectory(at: wrapper_builds.url, includingPropertiesForKeys: nil).forEach { url in
//            if url.lastPathComponent == ".DS_Store" { return }
//            try xc.xc_handler.add_file(path: url.Path, group: group)
//        }
//
//    }
//
//    if let source_group = xc.xc_handler.get_or_create_group("Sources") {
//        try await pack.targetFiles.asyncForEach { target in
//            try xc.xc_handler.add_file(path: target.path, group: source_group, copy: true)
//        }
//    }
//
//
//}


import PyCodable
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
    _ = try py_decoder.decode(WrapPackage.self, from: dump)
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
    _ = try decoder.decode(WrapPackage.self, from: data)
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
    _ = try decoder.decode(WrapPackage.self, from: data)
    end = .now()
    
    nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
    
    print("JSONDecoder with jdump: total \(timeInterval) seconds")
}
