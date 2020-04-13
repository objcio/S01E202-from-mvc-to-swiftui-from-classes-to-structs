import Foundation
import UIKit

private let formatter: DateComponentsFormatter = {
	let formatter = DateComponentsFormatter()
	formatter.unitsStyle = .positional
	formatter.zeroFormattingBehavior = .pad
	formatter.allowedUnits = [.hour, .minute, .second]
	return formatter
}()

func timeString(_ time: TimeInterval) -> String {
	return formatter.string(from: time)!
}

func modalTextAlert(title: String, accept: String = .ok, cancel: String = .cancel, placeholder: String, callback: @escaping (String?) -> ()) -> UIAlertController {
    let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    alert.addTextField { $0.placeholder = placeholder }
    alert.addAction(UIAlertAction(title: cancel, style: .cancel) { _ in
        callback(nil)
    })
    alert.addAction(UIAlertAction(title: accept, style: .default) { [tf = alert.textFields?.first] _ in
        callback(tf?.text)
    })
    return alert
}

fileprivate extension String {
	static let ok = NSLocalizedString("OK", comment: "")
	static let cancel = NSLocalizedString("Cancel", comment: "")
}
