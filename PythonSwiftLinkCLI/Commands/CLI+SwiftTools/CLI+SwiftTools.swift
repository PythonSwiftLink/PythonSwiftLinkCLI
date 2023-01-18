//
//  CLI+SwiftTools.swift
//  PythonSwiftLinkCLI
//


import Foundation
import ArgumentParser
import PathKit


extension PythonSwiftLinkCLI {
    
    struct SwiftTools: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "SwiftTools packages",
            subcommands: [Install.self, Remove.self, List.self, Info.self].sorted(by: {$0._commandName < $1._commandName})
        )
        
        enum Library: Int, EnumerableFlag, Decodable {
            case plyer
            case standard
        }
        
       
        
        
        struct Remove: AsyncParsableCommand {
            
            @Flag() var library: Library
            @Argument() var package: String
            
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
                let folder = try FileWrapperEx(path: folder_path)
                
                guard let pack = folder.get(file: package) else { return }
                
                let wrapper_builds = project.wrapper_builds
                
                
                
            }
        }
        struct Info: AsyncParsableCommand {
            
            @Flag() var library: Library
            @Argument() var package: String
            
            func run() async throws {
                try await checkSwiftTools()
            }
        }
        
        struct List: AsyncParsableCommand {
            
            @Flag() var library: Library
            
            func run() async throws {
                print("list:")
                try await checkSwiftTools()
            }
        }
    }
}
