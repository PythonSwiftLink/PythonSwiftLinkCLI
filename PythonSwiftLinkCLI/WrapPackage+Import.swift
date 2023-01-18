//
//  WrapPackage+Load.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 15/01/2023.
//

import Foundation
import PythonSwiftCore
import PythonLib
import PathKit
import PyCodable

extension WrapPackage {
    
    static func fromPath(_ pack: PathKit.Path) throws -> Self {
        let pack_init = (pack + "__init__.py")
        let code = try pack_init.read(.utf8)
        
        let kw = PyDict_New()
        DEBUG_PRINT(pack)
        PyDict_SetItem(kw, "__file__", pack_init.string.pyPointer)
        
        let result = PyRun_String(string: code, flag: .file, globals: kw, locals: kw)
        
        if result == nil {
            PyErr_Print()
            throw PythonError.attribute
        }
        
        let dump: PyPointer = PyDict_GetItem(kw, "package")
        
        let package = try PyDecoder().decode(WrapPackage.self, from: dump)
        
        return package
    }
    
}

