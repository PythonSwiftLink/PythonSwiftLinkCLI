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


func DEBUG_PRINT(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    print(items, separator: separator, terminator: terminator)
    #endif
}

extension String {
    var fileWrapper: FileWrapper? {
        guard let data = self.data(using: .utf8) else { return nil }
        return .init(regularFileWithContents: data)
    }
    
    
}
//let EXE_PATH = URL(fileURLWithPath: Bundle.main.executablePath ?? "").deletingLastPathComponent()

let EXE_PATH = Bundle.main.executableURL!.deletingLastPathComponent()

let APP_FOLDER = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first!.appendingPathComponent("PythonSwiftLinkCLI")

//var ROOT_PATH = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var ROOT_PATH = Path.current
//var SYSTEM_FILES: URL {  ROOT_PATH.appendingPathComponent("system_files") }
var SYSTEM_FILES: Path {  ROOT_PATH + "system_files" }
var SWIFT_TOOLS: Path { SYSTEM_FILES + "SwiftTools" }

var env_var = "dont suck?"


var site_packages_folder: Path? {
    if let project = currentProject {
        
        return try? FolderSettings.load(url: (project.project_dir.parent() + "settings.json").url ).site_packages_path?.Path
    }
    return try? FolderSettings.load(url: (ROOT_PATH + "settings.json").url ).site_packages_path?.Path
}



func handleWrapperFile(key: String, value: FileWrapper) async throws -> (swift: FileWrapper, site_file: FileWrapper)? {
    if Path(key).extension == "py" {
        return try await handleWrapperFile(file: value)
    }
    return nil
}

func handleWrapperFileEx(key: String, value: FileWrapperEx) async throws -> (swift: FileWrapper, site_file: FileWrapper)? {
    if Path(key).extension == "py" {
        return  try await handleWrapperFile(file: value.file)
        //return (FileWrapperEx(file: result.swift), FileWrapperEx(file: result.site_file))
    }
    return nil
}


var PYTHON_EXTRA_MODULES : [String] {
    [
        APP_FOLDER.appendingPathComponent("python-extra").path,
        (SWIFT_TOOLS + "src" ).string
    ]
}

//func handleWrapperFileEx(key: String, value: Path) async throws -> (swift: Data, site_file: Data)? {
//    if Path(key).extension == "py" {
//        return  try await handleWrapperFilePW(file: value)
//        //return (FileWrapperEx(file: result.swift), FileWrapperEx(file: result.site_file))
//    }
//    return nil
//}

func handleWrapperFileEx(file: FileWrapperEx) async throws -> (swift: FileWrapper, site_file: FileWrapper) {
    try await handleWrapperFile(file: file.file)
}


func handleWrapperFilePW(file: Path) async throws -> (name: String,swift: Data, site_file: Data)? {
    //DEBUG_PRINT(file)
    guard file.extension == "py" else { return nil }
    let filename = file.lastComponentWithoutExtension

    guard let data = try? file.read() , let source_code = String(data: data, encoding: .utf8) else { throw Foundation.CocoaError(.fileReadInapplicableStringEncoding) }
    let py_file: Data = try generatePurePyFile(data: data)
    let module = await WrapModule(fromAst: filename, string: source_code, swiftui: SWIFTUI_MODE)

    if let wrapper = module.pyswift_code.data(using: .utf8) {
        return (filename,wrapper,py_file)
    }
    throw CocoaError(.fileReadCorruptFile)
    
    
}

func handleWrapperFile(file: FileWrapper) async throws -> (swift: FileWrapper, site_file: FileWrapper) {
    let filename = Path(file.filename ?? "none").lastComponentWithoutExtension
    DEBUG_PRINT("input: \(filename)")
    
    let _file: FileWrapper = file.isSymbolicLink ? try .init(url: file.symbolicLinkDestinationURL!) : file
    
    guard let data = _file.regularFileContents, let source_code = String(data: data, encoding: .utf8) else { throw Foundation.CocoaError(.fileReadInapplicableStringEncoding) }
    let py_file: FileWrapper = try generatePurePyFile(data: data)
    py_file.preferredFilename = "\(filename).py"

    let module = await WrapModule(fromAst: filename, string: source_code)

    if let wrapper = module.pyswift_code.fileWrapper {
        wrapper.preferredFilename = "\(filename).swift"
        return (wrapper,py_file)
    }
    throw CocoaError(.fileReadCorruptFile)
}


func handleWrapper(src: FileWrapper, destination_folder: URL , python_init: Bool) async throws {
    
    
    
    
    
    func handleFolder(folder: FileWrapper, dst: URL) {
//        if let pack = folder.wrapPackage {
//      
//            if let s = folder.sourceFiles.first {
//                //generatePurePyFile(data: s.regularFileContents)
//            }
//            return
//        }
//        for (key,file) in folder.fileWrappers ?? [:] {
//            if file.isDirectory { handleFolder(folder: file, dst: dst)}
//            else if file.isRegularFile { continue }
//        }
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
        DEBUG_PRINT("output: \(dst.path)")
        //create wrap module from .py
        let module = await WrapModule(fromAst: filename, string: source)
        // store .pyswift_code to file
        try module.pyswift_code.write(to: dst, atomically: true, encoding: .utf8)
    }
    
    func selectType(file: FileWrapper) {
        switch file {
        case let f where f.isDirectory == true:
            handleFolder(folder: f, dst: destination_folder)
        case let f where f.isRegularFile == true:
            DEBUG_PRINT(f.preferredFilename)
            fatalError()
        case let f where f.isSymbolicLink == true:
            DEBUG_PRINT(f.preferredFilename)
            fatalError()
        default:
            return
        }
    }
    
    if python_init {
        PythonHandler.shared.start(
            stdlib: APP_FOLDER.appendingPathComponent("python-stdlib").path,
            app_packages: PYTHON_EXTRA_MODULES,
            debug: false
        )
    }
    
    
}

let app_ver = "0.0.4"
let app_build = 1100

var currentProject: PySwiftProject? = nil
public var SWIFTUI_MODE = false
@main
struct PythonSwiftLinkCLI: AsyncParsableCommand {
    init() {
//        try await checkSwiftTools()
//        PythonHandler.shared.defaultRunning.toggle()
    }
    
    
    static let configuration = CommandConfiguration(
        abstract: "PythonSwiftLinkCLI - version: \(app_ver) build: \(app_build)",
        version: "\(app_ver)",
        subcommands: [Kivy.self, SwiftUi.self].sorted(by: {$0._commandName < $1._commandName})
    )
    
    
    
    
   
}


extension PythonSwiftLinkCLI {
    
    
    

    struct SwiftUi: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Wrapper tools for SwiftUI.",
            subcommands: [Update.self].sorted(by: {$0._commandName < $1._commandName})
            //defaultSubcommand: Setup.self
            
        )
        
        struct Update: AsyncParsableCommand {
            
            //@Argument() var project: String
            @Argument() var source: Path
            @Argument() var destination: Path
            @Argument() var py_path: Path
            
            func run() async throws {
                print("updating")
                SWIFTUI_MODE = true
                PythonHandler.shared.defaultRunning.toggle()
               
                try await source
                    //.filter({s in destination.contains(where: {b in s.lastComponentWithoutExtension == b.lastComponentWithoutExtension })})
                    .asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data) in
                        try (destination + "\(name).swift").write(swift)
                        
                        try (py_path + "\(name).py").write(site_file)
                        
                    }
                
                
                //try project.updateWrapperImports()
            }
        }
        
    }
    
    struct Kivy: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Wrapper tools for Kivy.",
            subcommands: [Config.self, Project.self, SwiftTools.self, Helpers.self].sorted(by: {$0._commandName < $1._commandName})
            //defaultSubcommand: Setup.self
            
        )
        @Option(name: .shortAndLong, transform: { p -> Path? in
            ROOT_PATH = .init(p)
            return ROOT_PATH
        }) var root
        
        @Option(name: .shortAndLong) var project: PySwiftProject?
        
        enum CodingKeys: CodingKey {
            case root
            case project
        }
        
        
    }
    
}

//PythonSwiftLinkCLI.main()
func checkSwiftTools()  async throws {
    let path = SWIFT_TOOLS
    if !path.exists {
        try path.mkpath()
         DEBUG_PRINT("swift tools missing cloning.....")
        try await gitAsync(clone: ["https://github.com/PythonSwiftLink/SwiftTools"], target: path.string)
    }
}
