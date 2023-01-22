//
//  AstorWrapper.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 10/01/2023.
//

import Foundation
import PyAstParser
import PythonSwiftCore
import PythonLib

let test_parse = pythonImport(from: "pure_py_parser", import_name: "testParse").pyPointer

func generatePurePyFile(data: Data?) throws -> FileWrapper {
    guard let data = data, let string = String(data: data, encoding: .utf8) else { throw PythonError.unicode }

    let result = test_parse(string).pyPointer
    if result == nil {
        PyErr_Print()
        throw PythonError.call
    }
    //result.incref()
    let output = try String(object: result)

    return .init(regularFileWithContents: output.data(using: .utf8) ?? .init())
 
}


func generatePurePyFile(data: Data?) throws -> Data {
    guard let data = data, let string = String(data: data, encoding: .utf8) else { throw PythonError.unicode }
    
    let result = test_parse(string).pyPointer
    if result == nil {
        PyErr_Print()
        throw PythonError.call
    }

    let output = try String(object: result)

    return  output.data(using: .utf8) ?? .init()
    
}





