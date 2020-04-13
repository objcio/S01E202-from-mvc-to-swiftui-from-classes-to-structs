import Foundation

final class Store: ObservableObject {
	static private let documentDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
	static let shared = Store(url: documentDirectory)
	
	let baseURL: URL?
	var placeholder: URL?
    var rootFolder: Item = Item(folder: "") {
        willSet {
            objectWillChange.send()
        }
        didSet {
            save()
        }
    }
	
	init(url: URL?) {
		self.baseURL = url
		self.placeholder = nil
		
		if let u = url,
			let data = try? Data(contentsOf: u.appendingPathComponent(.storeLocation)),
			let folder = try? JSONDecoder().decode(Item.self, from: data)
		{
			self.rootFolder = folder
		}
	}
	
//	func fileURL(for recording: Item) -> URL? {
//		return baseURL?.appendingPathComponent(recording.uuid.uuidString + ".m4a") ?? placeholder
//	}
	
	// << mvc-save
	func save() {
		if let url = baseURL, let data = try? JSONEncoder().encode(rootFolder) {
			try! data.write(to: url.appendingPathComponent(.storeLocation))
			// error handling ommitted
		}
	}
	// >> mvc-save
	
//	func item(atUUIDPath path: [UUID]) -> Item? {
//		return rootFolder.item(atUUIDPath: path[0...])
//	}
//
//	func removeFile(for recording: Recording) {
//		if let url = fileURL(for: recording), url != placeholder {
//			_ = try? FileManager.default.removeItem(at: url)
//		}
//	}
}

fileprivate extension String {
	static let storeLocation = "store.json"
}
