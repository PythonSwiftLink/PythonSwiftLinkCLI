//
//  WrapContainer+Import.swift
//  PythonSwiftLinkCLI
//

import Foundation
import PythonSwiftCore
import PythonLib
import PathKit
import PyCodable

extension WrapContainer {
    
    static func fromPath(_ pack: PathKit.Path) throws -> WrapContainer {
        let pack_init = (pack)
        let code = try pack_init.read(.utf8)
        
        let kw = PyDict_New()
        DEBUG_PRINT(pack)

        let result = PyRun_String(string: code, flag: .file, globals: kw, locals: kw)
        
        if result == nil {
            PyErr_Print()
            throw PythonError.attribute
        }

        let package = try PyDecoder().decode(WrapContainer.self, from: kw)
        
        kw.decref()
        
        return package
    }
    
}
