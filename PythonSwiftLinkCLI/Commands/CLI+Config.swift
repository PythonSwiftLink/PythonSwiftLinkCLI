//
//  CLI+Config.swift
//  PythonSwiftLinkCLI
//

import Foundation
import ArgumentParser
import PathKit


extension PythonSwiftLinkCLI {
    
    struct Config: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Config for Kivy-ios Folder",
            subcommands: [Run.self, SitePackages.self].sorted(by: {$0._commandName < $1._commandName})
        )
        
        struct SitePackages: AsyncParsableCommand {
            
            @Argument(transform: {Path.init($0)}) var site_path
            
            func run() async throws {
                try FolderSettings.update(withKey: .site_packages_path, value: site_path.absolute().string)
            }
        }
        
        struct Run: AsyncParsableCommand {
            //        @Argument() var source_path: String
            //        @Argument() var destination_folder: String
            //            @Flag(name: .shortAndLong, help: "Debug Mode")
            //            var debug = false
            
            //            @Option(help: "")
            //            var autodoc: String?
            
            
            
            func run() async throws {
                try run_setup()
            }
        }
    }
    
}


func run_setup() throws {
    PythonHandler.shared.start(stdlib: APP_FOLDER.appendingPathComponent("python-stdlib").path, app_packages: PYTHON_EXTRA_MODULES, debug: false)
    //                }
    
    let fm = FileManager.default
    let branch = AppVersion.release_state == .release ? "main" : "testing"
    
    //createFolder(name: SYSTEM_FILES)
    try SYSTEM_FILES.mkpath()
    let PythonSwiftLinkSupportFiles = SYSTEM_FILES + "PythonSwiftLinkSupportFiles"
    if PythonSwiftLinkSupportFiles.exists {
        try PythonSwiftLinkSupportFiles.delete()
    }
//    if fm.fileExists(atPath: PythonSwiftLinkSupportFiles.path) {
//        try fm.removeItem(at: PythonSwiftLinkSupportFiles)
//    }
    try git(
        clone: ["--branch", "main", "https://github.com/PythonSwiftLink/PythonSwiftLinkSupportFiles"],
        target: PythonSwiftLinkSupportFiles.string
    )
    let PythonSwiftCore = SYSTEM_FILES + "PythonSwiftCore"
    if PythonSwiftCore.exists {
        try PythonSwiftCore.delete()
    }
//    let PythonSwiftCore = SYSTEM_FILES.appendingPathComponent("PythonSwiftCore")
//    if fm.fileExists(atPath: PythonSwiftCore.path) {
//        try fm.removeItem(at: PythonSwiftCore)
//    }
    try git(
        clone: ["--branch",  "testing", "https://github.com/PythonSwiftLink/PythonSwiftCore"],
        target: PythonSwiftCore.string
    )
    let PythonLib = SYSTEM_FILES + "PythonLib"
    if PythonLib.exists {
        try PythonLib.delete()
    }
    
//    let PythonLib = SYSTEM_FILES.appendingPathComponent("PythonLib")
//    if fm.fileExists(atPath: PythonLib.path) {
//        try fm.removeItem(at: PythonLib)
//    }
    try git(
        clone: ["--branch", "main", "https://github.com/PythonSwiftLink/PythonLib.git"],
        target: PythonLib.string
    )
    let project_support_files = PythonSwiftLinkSupportFiles + ("project_support_files")
    let support_files_dst = SYSTEM_FILES + ("project_support_files")
    if support_files_dst.exists {
        try support_files_dst.delete()
    }
//    if fm.fileExists(atPath: support_files_dst.path) {
//        try fm.removeItem(at: support_files_dst)
//    }
    try project_support_files.move(support_files_dst)
    //try fm.moveItem(at: project_support_files, to: SYSTEM_FILES.appendingPathComponent("project_support_files"))
    if project_support_files.exists {
        try project_support_files.delete()
    }
//    if fm.fileExists(atPath: project_support_files.path) {
//        try fm.removeItem(at: project_support_files)
//    }
    }
