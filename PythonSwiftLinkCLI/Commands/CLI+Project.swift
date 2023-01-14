//
//  CLI+Project.swift
//  PythonSwiftLinkCLI
//

import Foundation
import ArgumentParser
import PathKit


extension PythonSwiftLinkCLI {
    
    struct Project: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Mod Xcode Project",
            subcommands: [Setup.self, Update.self, ResyncWrappers.self].sorted(by: {$0._commandName < $1._commandName})
            //defaultSubcommand: Setup.self
            
        )
        
        struct Setup: AsyncParsableCommand {
            
            
            func run() async throws {
                guard let project = currentProject else {
                    print("no project selected")
                    print("add flag -p <name of project>")
                    return
                }
                
                try await project.mod_newXCProj(system_files: SYSTEM_FILES)

                try ProjectFile(name: String(project.name), depends: []).write()
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
                
                guard let project = currentProject else { return }
                
                
                try await handleWrapper(src: .init(url: .init(fileURLWithPath: source)), destination_folder: .init(fileURLWithPath: ""), python_init: true)
                
                let _file = Path(source).lastComponentWithoutExtension
                
                let dst = project.wrapper_sources + "\(_file).py"
                try await copyItem(forced: source, to: dst.string)
                let builds = project.wrapper_builds
                //try await handleWrapperFile(source_path: dst.url, destination_folder: builds.url, python_init: true)
                project.xc_handler.load_project()
                if let group = project.xc_handler.get_or_create_group("PythonSwiftWrappers") {
                    try project.xc_handler.add_file(path: builds + "\(_file).swift", group: group)
                }
                project.xc_handler.save()
                
                //try PythonSwiftLink_Project.updateWrapperImports(path: project)
            }
        }
        
        struct ResyncWrappers: AsyncParsableCommand {
            
            
            func run() async throws {
                guard let project = currentProject else { return }
                //let _proj_dir = project.xc_handler.project_dir
                
                PythonHandler.shared.start(
                    stdlib: APP_FOLDER.appendingPathComponent("python-stdlib").path,
                    app_packages: PYTHON_EXTRA_MODULES,
                    debug: false
                )
                let wrapper_builds = project.wrapper_builds
                
                if !FileManager.default.fileExists(atPath: wrapper_builds.string) {
                    try FileManager.default.createDirectory(at: wrapper_builds.url, withIntermediateDirectories: true)
                }
                let source_files = try FileWrapper(url: project.wrapper_sources.url )
                
                try await source_files.asyncCompactForEach(handleWrapperFile) { (swift: FileWrapper, site_file: FileWrapper) in
                    
                    if let swift_name = swift.preferredFilename {
                        try swift.write(to: (wrapper_builds + swift_name).url, originalContentsURL: nil)
                    }
                    
                    if let site = site_packages_folder, let py_name = site_file.preferredFilename {
                        try site_file.write(to: (site + py_name).url, originalContentsURL: nil)
                    }
                }
                
                let xc = project
                xc.xc_handler.load_project()
                
                if let group = xc.xc_handler.get_or_create_group("PythonSwiftWrappers") {
                    
                    try FileManager.default.contentsOfDirectory(at: wrapper_builds.url, includingPropertiesForKeys: nil).forEach { url in
                        if url.lastPathComponent == ".DS_Store" { return }
                        try xc.xc_handler.add_file(path: url.Path, group: group)
                    }
                    
                }
                
                xc.xc_handler.save()
                
                try xc.updateWrapperImports()
            }
        }
    }
    
    
}
