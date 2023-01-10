import Foundation


struct ProjectFile: Codable {
    let name: String
    
    var depends: [String]
}



extension ProjectFile {
    func data() throws -> Data {
        try JSONEncoder().encode(self)
    }
    func write(_ url: URL) throws {
        try data().write(to: url)
    }
    
    
}
