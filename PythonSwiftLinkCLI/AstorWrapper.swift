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
    
    
    //let visit_cls = pythonImport(from: "pure_py_parser", import_name: "ImportVisitor").pyObject
    
//    PythonHandler.shared.start(stdlib: EXE_PATH.appendingPathComponent("python-stdlib").path, app_packages: EXE_PATH.appendingPathComponent("python-extra").path, debug: false)
//
    //guard let ast = Ast.py_cls?.pyObject else { return }
    let result = test_parse(string).pyPointer
    if result == nil {
        PyErr_Print()
        throw PythonError.call
    }
    //result.incref()
    let output = try String(object: result)
    print()
    print(output)
    
    return .init(regularFileWithContents: output.data(using: .utf8) ?? .init())
//    let parse = ast.parse.pyPointer
//
//    let result = parse(string!).pyObject
//
//    let visit = visit_cls().pyObject.visit
//
//    visit(result.xINCREF)
//
//    //let _dump = ast.dump(result)
//
//    //pyPrint(_dump.pyPointer)
//
//    let unparse = ast.unparse.pyPointer
////
////    let result = parse(string!)
////
//    unparse(result.xINCREF)
    
    
}
