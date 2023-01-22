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
import SwiftPrettyPrint
import SwiftyJSON

let update_plist_ptr = pythonImport(from: "plist_editor", import_name: "update_plist").pyPointer

extension PySwiftProject {
    
    func update_plist(plist: PathKit.Path, keys: String) {
//        PyObject_Vectorcall(update_plist_ptr, [plist.string.pyPointer, keys.replacingOccurrences(of: "'", with: "\"").pyPointer], 2, nil)
        do {
            try plist.write(updatePlist(plistData: plist.read(), keys: keys))
        }
        catch let error {
            print(error.localizedDescription)
        }
    }
    
    
}



private func updatePlist(plistData: Data, keys: String) throws  -> Data {
    let keys = keys.replacingOccurrences(of: "'", with: "\"")
    guard
        var plistDict = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: nil) as? [String: Any],
        let jdata = keys.data(using: .utf8),
        let keysDict = try! JSONSerialization.jsonObject(with: jdata, options: []) as? [String: Any]
    else { return plistData }
    
    plistDict.merge(keysDict) { (_, new) in new }
    
    return try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
}
