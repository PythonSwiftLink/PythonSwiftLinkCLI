//
//  PySwiftProject+Plist.swift
//  PythonSwiftLinkCLI
//
//  Created by MusicMaker on 16/01/2023.
//

import Foundation
import PythonLib
import PythonSwiftCore
import PathKit

let update_plist_ptr = pythonImport(from: "plist_editor", import_name: "update_plist").pyPointer

extension PySwiftProject {
    
    func update_plist(plist: PathKit.Path, keys: String) {
        PyObject_Vectorcall(update_plist_ptr, [plist.string.pyPointer, keys.replacingOccurrences(of: "'", with: "\"").pyPointer], 2, nil)
    }
    
    
}
