//
//  main.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 26/12/2022.
//

import Foundation

import PythonSwiftLinkParser
import ArgumentParser
import PathKit
import WrapperPackageHandler

extension String {
    var fileWrapper: FileWrapper? {
        guard let data = self.data(using: .utf8) else { return nil }
        return .init(regularFileWithContents: data)
    }
}
//let EXE_PATH = URL(fileURLWithPath: Bundle.main.executablePath ?? "").deletingLastPathComponent()
let EXE_PATH = Bundle.main.executableURL!.deletingLastPathComponent()

let ROOT_PATH = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let SYSTEM_FILES = ROOT_PATH.appendingPathComponent("system_files")


var env_var = "dont suck?"

func handleWrapperFile(file: FileWrapper, destination_folder: Path , python_init: Bool) async throws -> (swift: FileWrapper, site_file: FileWrapper) {
    let filename = Path(file.filename ?? "none").lastComponentWithoutExtension
    print("input: \(filename)")
    var _file: FileWrapper
    
    if file.isSymbolicLink {
        _file = try .init(url: file.symbolicLinkDestinationURL!)
    } else {
        _file = file
    }
    
    // init Python
    if python_init {
        PythonHandler.shared.start(
            stdlib: EXE_PATH.appendingPathComponent("python-stdlib").path,
            app_packages: EXE_PATH.appendingPathComponent("python-extra").path,
            debug: false
        )
    }
    
    guard let data = _file.regularFileContents, let source_code = String(data: data, encoding: .utf8) else { throw Foundation.CocoaError(.fileReadInapplicableStringEncoding) }
    //let src = source_path
    let py_file = try generatePurePyFile(data: data)
    py_file.preferredFilename = "\(filename).py"
//    let source = try String(contentsOf: src)// else { return }
//    guard let _filename = src.lastPathComponent.split(separator: ".").first else { return }
//    let filename = String(_filename)
    let name = Path(filename).lastComponentWithoutExtension
    
    let dst =  destination_folder + "\(name).swift"
    print("output: \(dst)")
    
    
    //create wrap module from .py
    let module = await WrapModule(fromAst: filename, string: source_code)
    // store .pyswift_code to file
    //try module.pyswift_code.write(to: dst.url, atomically: true, encoding: .utf8)
    if let wrapper = module.pyswift_code.fileWrapper {
        wrapper.preferredFilename = "\(filename).swift"
        return (wrapper,py_file)
    }
    throw CocoaError(.fileReadCorruptFile)
}


func handleWrapper(src: FileWrapper, destination_folder: URL , python_init: Bool) async throws {
    
    
    
    
    
    func handleFolder(folder: FileWrapper, dst: URL) {
        if let pack = folder.wrapPackage {
            print(pack.wrapPackageConfig?.name)
            print(folder.sourceFiles.compactMap(\.filename))
            print(folder.targetFiles.compactMap(\.filename))
            if let s = folder.sourceFiles.first {
                //generatePurePyFile(data: s.regularFileContents)
            }
            return
        }
        for (key,file) in folder.fileWrappers ?? [:] {
            if file.isDirectory { handleFolder(folder: file, dst: dst)}
            else if file.isRegularFile { continue }
        }
//        guard let fname = folder.filename, let files = folder.fileWrappers else { return }
//        if files.keys.contains("package.json") {
//
//        }
        
    }
    
    func handleFile(_file: FileWrapper, dst: URL ) async throws {
        guard
            let fname = _file.filename,
            let fdata = _file.regularFileContents,
            let source = String(data: fdata, encoding: .utf8)
        else { return }
        
        guard let _filename = fname.split(separator: ".").first else { return }
        let filename = String(_filename)
        let dst =  destination_folder.appendingPathComponent("\(filename).swift")
        print("output: \(dst.path)")
        //create wrap module from .py
        let module = await WrapModule(fromAst: filename, string: source)
        // store .pyswift_code to file
        try module.pyswift_code.write(to: dst, atomically: true, encoding: .utf8)
    }
    
    
    if python_init {
        PythonHandler.shared.start(
            stdlib: EXE_PATH.appendingPathComponent("python-stdlib").path,
            app_packages: EXE_PATH.appendingPathComponent("python-extra").path,
            debug: false
        )
    }
    
    switch src {
    case let f where f.isDirectory == true:
        handleFolder(folder: f, dst: destination_folder)
    case let f where f.isRegularFile == true:
        fatalError()
    
    default:
        return
    }
}

let app_ver = 0.1
let app_build = 1000

var currentProject: PythonSwiftLink_Project? = nil

@main
struct PythonSwiftLinkCLI: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "PythonSwiftLinkCLI - version: \(app_ver) build: \(app_build)",
        version: "\(app_ver)",
        subcommands: [Build.self, Setup.self, Project.self, SwiftTools.self].sorted(by: {$0._commandName < $1._commandName})
    )
    
    
    @Option(name: .shortAndLong ,transform: { src -> PythonSwiftLink_Project? in
        let p = PythonSwiftLink_Project.init(path: .init(src))
        currentProject = p
        return p
    }) var project
    
}


extension PythonSwiftLinkCLI {
    
    struct Build: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Build Wrapper Files",
            subcommands: [File.self],
            defaultSubcommand: File.self
            
        )
        
        struct File: AsyncParsableCommand {
            @Argument() var source_path: String
            @Argument() var destination_folder: String
//            @Flag(name: .shortAndLong, help: "Debug Mode")
//            var debug = false
            
//            @Option(help: "")
//            var autodoc: String?
            
            func run() async throws {
                //try await handleWrapperFile(file: <#T##FileWrapper#>, destination_folder: <#T##Path#>, python_init: <#T##Bool#>)
                //try await handleWrapperFile(source_path: .init(fileURLWithPath: source_path), destination_folder: .init(fileURLWithPath: destination_folder), python_init: true)
            }
        }
        
    }
    
    
    struct Project: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Mod Xcode Project",
            subcommands: [AddWrapper.self, Setup.self, Update.self, ResyncWrappers.self].sorted(by: {$0._commandName < $1._commandName}),
            defaultSubcommand: Setup.self
            
        )
        
        struct Setup: AsyncParsableCommand {
            @Argument() var project_path: String
            //        @Argument() var destination_folder: String
            //            @Flag(name: .shortAndLong, help: "Debug Mode")
            //            var debug = false
            
            //            @Option(help: "")
            //            var autodoc: String?
            
            func run() async throws {
                //PythonHandler.shared.start(stdlib: EXE_PATH.appendingPathComponent("python-stdlib").path, app_packages: nil, debug: false)
                let src = URL(fileURLWithPath: project_path)
                print("project input: \(src.path)")
                guard let _filename = src.lastPathComponent.split(separator: ".").first else { return }
                let filename = String(_filename).replacingOccurrences(of: "-ios", with: "")
                
                let handler = PythonSwiftLink_Project(url: src, name: filename)
                try await handler.mod_newXCProj(system_files: SYSTEM_FILES)
                
                try ProjectFile(name: String(_filename), depends: []).write(src.appendingPathComponent("project.json"))
            }
        }
        
        struct Update: AsyncParsableCommand {
            
            @Argument() var project: String
            
            func run() async throws {
                try PythonSwiftLink_Project.updateWrapperImports(path: project)
            }
        }
        
        struct AddWrapper: AsyncParsableCommand {
            
            @Argument() var source: String
            @Argument() var project: String
            
            func run() async throws {
                
                
                
                
                try await handleWrapper(src: .init(url: .init(fileURLWithPath: source)), destination_folder: .init(fileURLWithPath: ""), python_init: true)
                
                
                return
                let _file = Path(source).lastComponentWithoutExtension
                
                let _project = Path(FileManager.default.currentDirectoryPath) + project
                let dst = _project + "wrapper_sources/\(_file).py"
                try await copyItem(forced: source, to: dst.string)
                let builds = _project + "wrapper_builds"
                //try await handleWrapperFile(source_path: dst.url, destination_folder: builds.url, python_init: true)
                let xc = PythonSwiftLink_Project(url: ROOT_PATH.appendingPathComponent(project), name: project.replacingOccurrences(of: "-ios", with: ""))
                xc.xc_handler.load_project()
                if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
                    try xc.xc_handler.add_file(path: builds + "\(_file).swift", group: group)
                }
                xc.xc_handler.save()
                
                //try PythonSwiftLink_Project.updateWrapperImports(path: project)
            }
        }
        
        struct ResyncWrappers: AsyncParsableCommand {
            
            //@Argument() var source: String
            @Argument(transform: {Path($0)}) var project
            //@Option(transform: {Path($0)}) var root
            
            func run() async throws {
                let proj_dir: URL = project.url
                
//                if let root = root {
//                    proj_dir = .init(fileURLWithPath: root).appendingPathComponent(project)
//                } else {
//                    proj_dir = ROOT_PATH.appendingPathComponent(project)
//                }
                
                let test_inputs = FileWrapper(directoryWithFileWrappers: [:])
                let test_outputs = FileWrapper(directoryWithFileWrappers: [:])
                let test_export = FileWrapper(directoryWithFileWrappers: ["inputs":test_inputs, "pure_pys": test_outputs])
                
                
                PythonHandler.shared.start(
                    stdlib: EXE_PATH.appendingPathComponent("python-stdlib").path,
                    app_packages: EXE_PATH.appendingPathComponent("python-extra").path,
                    debug: false
                )
                let wrapper_builds = proj_dir.appendingPathComponent("wrapper_builds")
                
                //let source_files = try FileManager.default.contentsOfDirectory(at: proj_dir.appendingPathComponent("wrapper_sources"), includingPropertiesForKeys: nil)
                let source_files = try FileWrapper(url: proj_dir.appendingPathComponent("wrapper_sources") )
                
                try await (source_files.fileWrappers ?? [:]).asyncForEach { (key: String, value: FileWrapper) in
                    if Path(key).extension == "py" {
                        print(key)
                        let (swift, py) = try await handleWrapperFile(file: value, destination_folder: wrapper_builds.Path, python_init: false)
                        test_inputs.addFileWrapper(value)
                        test_outputs.addFileWrapper(py)
                    }
                }
                let out_url = Path("/Users/musicmaker/pyswift_test_export").url
                test_export.preferredFilename = "pyswift_test_export"
                try test_export.write(to: out_url, originalContentsURL: out_url)
                return
//                try await source_files.asyncForEach { url in
//                    if url.lastPathComponent == ".DS_Store" { return }
//                    try await handleWrapperFile(file: <#T##FileWrapper#>, destination_folder: <#T##Path#>, python_init: <#T##Bool#>)
//                    try await handleWrapperFile(source_path: url, destination_folder: wrapper_builds, python_init: false)
//                }
                let xc = PythonSwiftLink_Project(path: project)
                //let xc = PythonSwiftLink_Project(url: proj_dir, name: project.replacingOccurrences(of: "-ios", with: ""))
                xc.xc_handler.load_project()
            
                if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
                    
                    try FileManager.default.contentsOfDirectory(at: wrapper_builds, includingPropertiesForKeys: nil).forEach { url in
                        if url.lastPathComponent == ".DS_Store" { return }
                        try xc.xc_handler.add_file(path: url.Path, group: group)
                    }
                    
                }
                
                xc.xc_handler.save()
            }
        }
    }
    
    struct Setup: AsyncParsableCommand {
//        @Argument() var source_path: String
//        @Argument() var destination_folder: String
        //            @Flag(name: .shortAndLong, help: "Debug Mode")
        //            var debug = false
        
        //            @Option(help: "")
        //            var autodoc: String?
        
        func run() async throws {
            PythonHandler.shared.start(stdlib: EXE_PATH.appendingPathComponent("python-stdlib").path, app_packages: nil, debug: false)
            //                }
            let fm = FileManager.default
            let branch = AppVersion.release_state == .release ? "main" : "testing"

            createFolder(name: SYSTEM_FILES.path)
            let PythonSwiftLinkSupportFiles = SYSTEM_FILES.appendingPathComponent("PythonSwiftLinkSupportFiles")
            if fm.fileExists(atPath: PythonSwiftLinkSupportFiles.path) {
                try fm.removeItem(at: PythonSwiftLinkSupportFiles)
            }
            try git(
                clone: ["--branch", "main", "https://github.com/PythonSwiftLink/PythonSwiftLinkSupportFiles"],
                target: PythonSwiftLinkSupportFiles.path
            )
            
            let PythonSwiftCore = SYSTEM_FILES.appendingPathComponent("PythonSwiftCore")
            if fm.fileExists(atPath: PythonSwiftCore.path) {
                try fm.removeItem(at: PythonSwiftCore)
            }
            try git(
                clone: ["--branch",  "testing", "https://github.com/PythonSwiftLink/PythonSwiftCore"],
                target: PythonSwiftCore.path
            )
            
            let PythonLib = SYSTEM_FILES.appendingPathComponent("PythonLib")
            if fm.fileExists(atPath: PythonLib.path) {
                try fm.removeItem(at: PythonLib)
            }
            try git(
                clone: ["--branch", "main", "https://github.com/PythonSwiftLink/PythonLib.git"],
                target: PythonLib.path
            )
            let project_support_files = PythonSwiftLinkSupportFiles.appendingPathComponent("project_support_files")
            let support_files_dst = SYSTEM_FILES.appendingPathComponent("project_support_files")
            if fm.fileExists(atPath: support_files_dst.path) {
                try fm.removeItem(at: support_files_dst)
            }
            try fm.moveItem(at: project_support_files, to: SYSTEM_FILES.appendingPathComponent("project_support_files"))
            if fm.fileExists(atPath: project_support_files.path) {
                try fm.removeItem(at: project_support_files)
            }
        }
    }
    
    struct SwiftTools: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "SwiftTools packages",
            subcommands: [Install.self, Remove.self, List.self, Info.self].sorted(by: {$0._commandName < $1._commandName})
        )

        enum Library: Int, EnumerableFlag, Decodable {
            case plyer
            case standard
        }
        
        struct Install: AsyncParsableCommand {
            
            @Flag var library: SwiftTools.Library
            @Argument() var package: String
            
            func run() async throws {
                
            }
        }
        struct Remove: AsyncParsableCommand {
            
            @Flag() var library: Library
            @Argument() var package: String
            
            func run() async throws {
                
            }
        }
        struct Info: AsyncParsableCommand {
            
            @Flag() var library: Library
            @Argument() var package: String
            
            func run() async throws {
                
            }
        }
        
        struct List: AsyncParsableCommand {
            
            @Flag() var library: Library
            
            func run() async throws {
                
            }
        }
    }
}

//PythonSwiftLinkCLI.main()
