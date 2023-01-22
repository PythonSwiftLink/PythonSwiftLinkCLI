//
//  CodeTemplates.swift
//  KivySwiftLink-GUI
//
//  Created by MusicMaker on 02/06/2022.
//

import Foundation




func newWrapperTemplate0(cls_name: String) -> String {
    return """
    from swift_types import *
    
    @wrapper
    class \(cls_name):
        
        def new(self, arg: int): ...
    
    """
}

func newPythonMainFile(admob_mode: Bool) -> String {
    return """
    //
    //  PythonMain.swift
    //
    
    import Foundation
    
    class PythonMain {
        
        static let shared = PythonMain()
        
        \(if: admob_mode, "let admob_handler = AdmobHandler.shared")
        
        private init() {
    
        }
    }
    
    """
}

func PythonSwiftImportList_Template(wrappers: [String]) -> String {
    let wrapper_lines = wrappers.map {w in "( makeCString(from: \"\(w)\"), PyInit_\(w) )"}
    return """
    
    let PythonSwiftImportList: [PySwiftModuleImport] = [
        \(wrapper_lines.joined(separator: ",\n\t"))
    ]
    """
}
//
//func newPythonMainFile(project: KSLProjectData) -> String {
//    let admob_mode = project.addons.contains(where: {$0.type == "admob"})
//    return """
//    //
//    //  PythonMain.swift
//    //
//
//    import Foundation
//
//    class PythonMain {
//
//        static let shared = PythonMain()
//
//        \(if: admob_mode, "let admob_handler = AdmobHandler.shared")
//
//        private init() {
//
//        }
//    }
//
//    """
//}


let AdmobHandlerCode = """
from swift_types import *


@wrapper
class AdmobHandler:
    
    class Callbacks:
        
        def banner_did_load(self, w: float, h: float): ...
    
    def init_ads_class(self): ...
    
    def banner_ad(self, enabled: bool): ...
    
    def static_banner_ad(self, enabled: bool): ...
    
    def fullscreen_ad(self): ...
"""
