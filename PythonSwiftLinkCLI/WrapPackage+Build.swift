//
//  File.swift
//  
//
//  Created by MusicMaker on 15/01/2023.
//

import Foundation

import PathKit
import PythonLib
//extension WrapPackage {
//    public func build(project: )
//}

extension WrapPackage {
    
    
    func build(target: PySwiftProject) async throws {
        
        let project = target
        
        let wrapper_builds = project.wrapper_builds
        
        if !wrapper_builds.exists {
            try wrapper_builds.mkdir()
        } else {
            guard wrapper_builds.isDirectory else { throw CocoaError(.fileWriteNoPermission)}
        }
        
        //let pack_sources = file.sources
        
        try await sources.asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data ) in
            try! (wrapper_builds + "\(name).swift").write(swift)
            
            if let site = site_packages_folder {
                try! (site + "\(name).py").write(site_file)
            }
            
        }

        
        if let group = project.get_or_create_group("Sources") {
            try sources.filter({$0.extension == "swift"}).forEach { swift in
                try project.add_file(path: swift, group: group)
            }
            
        }
        
        for dep in dependencies {

            if dep.file.exists {
                let dep_sources = dep.sources
                
                
                
                try await dep_sources.asyncCompactForEach(handleWrapperFilePW) { (name: String, swift: Data, site_file: Data) in
                    
                    // put the builded wrapper into wrapper_builds
                    try (wrapper_builds + "\(name).swift").write(swift)
                    
                    // put the pure python version of the wrapper into site-packages
                    if let site = site_packages_folder {
                        try (site + "\(name).py").write(swift)
                    }
                    
                    
                    
                }
                if let group = project.get_or_create_group("PythonSwiftWrappers") {
                    
                    try dep_sources.filter({$0.extension == "swift"}).forEach { swift in
                        
                        try project.add_file(path: swift, group: group)
                    }
                    
                }
                
                try ProjectFile.updateDepends(add: dep.name)
                
            }
        }
        
        
        
        if let group = project.get_or_create_group("PythonSwiftWrappers") {
            
            try project.wrapper_builds.forEach { p in
                if p.lastComponent == ".DS_Store" { fatalError() }
                try project.add_file(path: p, group: group)
            }
        }
        
        if plist_keys != "{}" {
            project.update_plist(plist: project.plist, keys: plist_keys)
        }
        
        
    } // build
    
    
    
    
}

