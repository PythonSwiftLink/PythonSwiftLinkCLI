//
//  Extressable.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 17/01/2023.
//

import Foundation
import PathKit
import ArgumentParser



extension PathKit.Path: ExpressibleByArgument {
    
    public init?(argument: String) {
        self.init(argument)
    }
}
