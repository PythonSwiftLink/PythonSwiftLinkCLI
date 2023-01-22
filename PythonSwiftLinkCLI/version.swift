//
//  version.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation

extension Bundle {
    public var appName: String           { getInfo("CFBundleName")  }
    public var displayName: String       { getInfo("CFBundleDisplayName")}
    public var language: String          { getInfo("CFBundleDevelopmentRegion")}
    public var identifier: String        { getInfo("CFBundleIdentifier")}
    public var copyright: String         { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }
    
    public var appBuild: String          { getInfo("CFBundleVersion") }
    public var appVersionLong: String    { getInfo("CFBundleShortVersionString") }
    //public var appVersionShort: String { getInfo("CFBundleShortVersion") }
    
    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}


enum ReleaseState: Int, Comparable {
    static func < (lhs: ReleaseState, rhs: ReleaseState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case alpha
    case beta
    case release
}



let release_state: ReleaseState = .alpha



public struct versionTuple {
    let major: Int
    let minor: Int
    let micro: Int
    let release_state: ReleaseState
    let alpha_beta_ver: Int!
}


extension String {
    func contains(_ release: ReleaseState) -> Bool{
        self.contains("-\(release.rawValue)")
    }
}

extension versionTuple {
    
    var string: String {
        "\(AppVersion.major).\(AppVersion.minor).\(AppVersion.micro)"
    }
    
    func compareVersionWithString(string: String) -> Bool {
        let split_string = string.split(separator: "-").first!
        let string_ver = split_string.split(separator: ".").map{Int($0)!}
        if self.major < string_ver[0] {return true}
        if self.minor < string_ver[1] {return true}
        if self.micro < string_ver[2] {return true}
        
        if string.contains(.alpha) {
            if self.release_state < .alpha { return true }
        }
        
        if string.contains(.beta) {
            if self.release_state < .beta { return true }
        }
        
//        if string.contains(.release) {
//            if self.release_state < .release { return true }
//        }
        
        return false
    }
    
    static func == (lhs: versionTuple, rhs: versionTuple) -> Bool {
        if lhs.major < rhs.major { return true}
        if lhs.minor < rhs.minor { return true}
        if lhs.micro < rhs.major { return true}
        return false
        }
}


public let AppVersion = versionTuple(major: 0, minor:3, micro: 0, release_state: .alpha, alpha_beta_ver: 0)

