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



//let EXE_PATH = URL(fileURLWithPath: Bundle.main.executablePath ?? "").deletingLastPathComponent()
let EXE_PATH = Bundle.main.executableURL!.deletingLastPathComponent()

let ROOT_PATH = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let SYSTEM_FILES = ROOT_PATH.appendingPathComponent("system_files")

func handleWrapperFile(source_path: URL, destination_folder: URL , python_init: Bool) async throws {
    let src = source_path
    print("input: \(src.path)")
    let source = try String(contentsOf: src)// else { return }
    guard let _filename = src.lastPathComponent.split(separator: ".").first else { return }
    let filename = String(_filename)
    let dst =  destination_folder.appendingPathComponent("\(filename).swift")
    print("output: \(dst.path)")
    
    // init Python
    if python_init {
        PythonHandler.shared.start(
            stdlib: EXE_PATH.appendingPathComponent("python-stdlib").path,
            app_packages: nil,
            debug: false
        )
    }
    //create wrap module from .py
    let module = await WrapModule(fromAst: filename, string: source)
    // store .pyswift_code to file
    try module.pyswift_code.write(to: dst, atomically: true, encoding: .utf8)
}
let app_ver = 0.1
let app_build = 1000

@main
struct PythonSwiftLinkCLI: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "PythonSwiftLinkCLI - version: \(app_ver) build: \(app_build)",
        version: "\(app_ver)",
        subcommands: [Build.self, Setup.self, Project.self].sorted(by: {$0._commandName < $1._commandName})
    )
    
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
                
                try await handleWrapperFile(source_path: .init(fileURLWithPath: source_path), destination_folder: .init(fileURLWithPath: destination_folder), python_init: true)
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
                let _file = Path(source).lastComponentWithoutExtension
                
                let _project = Path(FileManager.default.currentDirectoryPath) + project
                let dst = _project + "wrapper_sources/\(_file).py"
                try await copyItem(forced: source, to: dst.string)
                let builds = _project + "wrapper_builds"
                try await handleWrapperFile(source_path: dst.url, destination_folder: builds.url, python_init: true)
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
            @Argument() var project: String
            
            func run() async throws {
                let proj_dir = ROOT_PATH.appendingPathComponent(project)
                
                
                
                
                
                PythonHandler.shared.start(
                    stdlib: EXE_PATH.appendingPathComponent("python-stdlib").path,
                    app_packages: nil,
                    debug: false
                )
                let wrapper_builds = proj_dir.appendingPathComponent("wrapper_builds")
                
                let source_files = try FileManager.default.contentsOfDirectory(at: proj_dir.appendingPathComponent("wrapper_sources"), includingPropertiesForKeys: nil)
                
                try await source_files.asyncForEach { url in
                    try await handleWrapperFile(source_path: url, destination_folder: wrapper_builds, python_init: false)
                }
                
                let xc = PythonSwiftLink_Project(url: proj_dir, name: project.replacingOccurrences(of: "-ios", with: ""))
                xc.xc_handler.load_project()
            
                if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
                    
                    try FileManager.default.contentsOfDirectory(at: wrapper_builds, includingPropertiesForKeys: nil).forEach { url in
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
}

//PythonSwiftLinkCLI.main()
