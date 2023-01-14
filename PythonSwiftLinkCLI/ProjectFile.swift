import Foundation
import PathKit

public class ProjectFile: Codable {
    
    
    
    public class Depend: Codable {
        
        let name: String
        var used_by: [String]
        
        init(name: String, ref: String?) {
            self.name = name
            self.used_by = []
            if let ref = ref {
                used_by.append(ref)
            }
            
        }
    }
    
    
    
    let name: String
    
    var depends: [Depend]
    
    
    internal init(name: String, depends: [ProjectFile.Depend]) {
        self.name = name
        self.depends = depends
    }
}



extension ProjectFile {
    func data() throws -> Data {
        try JSONEncoder().encode(self)
    }
    func write(_ url: URL) throws {
        try data().write(to: url)
    }
    
    func write() throws {
        if let p_url = currentProject?.path_url {
            try data().write(to: p_url.appendingPathComponent("project.json"))
        }
        
    }
    static func updateDepends(add deb: String) throws {
        if let file = currentProject?.projectFile {
            if let first = file.depends.first(where: {$0.name == deb}) {
                //first.ref_count += 1
            } else {
                file.depends.append(.init(name: deb, ref: nil))
            }
            
            try file.write()
        }
    }
    
    static func updateDepends(del deb: String) throws {
        if let file = currentProject?.projectFile {
            if let index = file.depends.firstIndex(where: {$0.name == deb}) {
                
                let deb = file.depends[index]
//                deb.ref_count -= 1
//                if deb.ref_count <= 0 {
//                    file.depends.remove(at: index)
//                }
                try file.write()
            }
            
            
        }
    }
    
    static func updateDepends(add url: URL, deb: String) throws {
        guard let file = url.projectFile else { return }
        if let first = file.depends.first(where: {$0.name == deb}) {
            //first.ref_count += 1
        } else {
            file.depends.append(.init(name: deb, ref: nil))
        }
        try file.write(url)
    }
}

extension URL {
    var projectFile : ProjectFile? {
        if let data = try? Data(contentsOf: self) {
            return try? JSONDecoder().decode(ProjectFile.self, from: data)
        }
        return nil
    }
}

class FolderSettings: Codable {
    
    static func load(url: URL) throws -> FolderSettings {
        print(url)
        var file: FileWrapper
        if url.exist {
            file = try FileWrapper(url: url)
        } else {
            file = .init()
            file.preferredFilename = "settings.json"
            let settings = FolderSettings()
            return settings
        }
        let settings = try file.folderSettings()
//        if let site = settings.site_packages_path {
//            site_packages_folder = site.Path
//        }
        return settings
        
    }
    
    var root: URL?
    
    var site_packages_path: URL?
    
    enum Keys: CodingKey {
        case root
        case site_packages_path
    }
    
    init() {
        root = nil
        site_packages_path = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<FolderSettings.Keys> = try decoder.container(keyedBy: FolderSettings.Keys.self)
        
        self.root = try container.decodeIfPresent(URL.self, forKey: FolderSettings.Keys.root)
        self.site_packages_path = try container.decodeIfPresent(URL.self, forKey: FolderSettings.Keys.site_packages_path)
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<FolderSettings.Keys> = encoder.container(keyedBy: FolderSettings.Keys.self)
        
        try container.encode(self.root, forKey: FolderSettings.Keys.root)
        try container.encode(self.site_packages_path, forKey: FolderSettings.Keys.site_packages_path)
    }
    
    static public func update(withKey key: FolderSettings.Keys, value: String) throws {
        let url = ROOT_PATH.appendingPathComponent("settings.json")
        let settings = try Self.load(url: url)
        
        switch key {
            
        case .root:
            settings.root = .init(fileURLWithPath: value)
        case .site_packages_path:
            settings.site_packages_path = .init(fileURLWithPath: value)
        }
        
        try settings.fileWrapper().write(to: url, originalContentsURL: nil)
        
    }
}

extension FolderSettings {
    func fileWrapper() throws -> FileWrapper {
        .init(regularFileWithContents: try JSONEncoder().encode(self))
    }
    
    
}

extension FileWrapper {
    func folderSettings() throws -> FolderSettings {
        if let data = regularFileContents {
            return try JSONDecoder().decode(FolderSettings.self, from: data)
        }
        throw CocoaError(.fileReadCorruptFile)
    }
}
