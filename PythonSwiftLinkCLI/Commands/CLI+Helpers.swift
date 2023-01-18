//
//  ClI+Helpers.swift
//  PythonSwiftLinkCLI
//


import Foundation
import ArgumentParser
import PathKit


extension PythonSwiftLinkCLI {
    struct Helpers: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Helpers to make life easier.",
            subcommands: [Wizzard.self].sorted(by: {$0._commandName < $1._commandName})
            //defaultSubcommand: Setup.self
            
        )

        struct Wizzard: AsyncParsableCommand {
            
            @Argument() var path: Path
            
            
            
            func run() async throws {
                
                try await checkSwiftTools()
                PythonHandler.shared.defaultRunning.toggle()
                
                let package = try WrapContainer.fromPath(path)
                try await package.build()
            }
        }
        
    }
}
