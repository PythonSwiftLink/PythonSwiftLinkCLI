//
//  CreateVenv.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 27/12/2022.
//

import Foundation
import PythonLib
import PythonSwiftCore

//fileprivate let Venv_EnvBuilder: PythonObject = pythonImport(from: "venv", import_name: "EnvBuilder")!
func createPythonVenv() {
    let current = FileManager.default.currentDirectoryPath
    let Venv_EnvBuilder: PythonObject = pythonImport(from: "venv", import_name: "EnvBuilder")!
    let builder = Venv_EnvBuilder(with_pip: true).pyObject
    print(builder.ptr, "\(FileManager.default.currentDirectoryPath)/venv")
    builder.create("\(FileManager.default.currentDirectoryPath)/venv")
}
