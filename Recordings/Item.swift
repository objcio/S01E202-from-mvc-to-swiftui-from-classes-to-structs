import Foundation

struct Item: Identifiable, Codable, Hashable {
	let id: UUID
	var name: String
    var contents: [Item]?
    
    init(id: UUID = UUID(), folder name: String, contents: [Item] = []) {
        self.id = id
        self.name = name
        self.contents = contents
    }
    
    init(id: UUID = UUID(), recording name: String) {
        self.id = id
        self.name = name
        self.contents = nil
    }
}

extension Item {
    
    mutating func add(_ item: Item) {
        contents!.append(item)
        contents!.sort { $0.name < $1.name }
    }

    mutating func remove(_ item: Item) {
        contents!.removeAll { $0.id == item.id }
    }
    
    var isFolder: Bool {
        contents != nil
    }
}
