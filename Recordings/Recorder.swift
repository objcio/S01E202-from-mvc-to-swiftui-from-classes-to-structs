import Foundation
import AVFoundation

enum RecorderError: Error, Equatable {
    case noPermission
    case other
}

final class Recorder: NSObject, AVAudioRecorderDelegate, ObservableObject {
	private var audioRecorder: AVAudioRecorder?
	private var timer: Timer?
	let url: URL
    
    @Published var currentTime: TimeInterval = 0
    @Published var error: RecorderError? = nil
	
	init(url: URL) {
		self.url = url
		super.init()
		
		do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
			try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            self.error = .other
        }
        AVAudioSession.sharedInstance().requestRecordPermission() { allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.start(url)
                } else {
                    self.error = .noPermission
                }
            }
        }
	}
	
	private func start(_ url: URL) {
		let settings: [String: Any] = [
			AVFormatIDKey: kAudioFormatMPEG4AAC,
			AVSampleRateKey: 44100.0 as Float,
			AVNumberOfChannelsKey: 1
		]
		if let recorder = try? AVAudioRecorder(url: url, settings: settings) {
			recorder.delegate = self
			audioRecorder = recorder
			recorder.record()
			timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [unowned self] _ in
                self.currentTime = recorder.currentTime
			}
		} else {
            self.error = .other
		}
	}
	
	func stop() {
		audioRecorder?.stop()
		timer?.invalidate()
	}
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		if flag {
			stop()
		} else {
            self.error = .other
		}
	}
    
    deinit {
        print("Recorder deinit")
    }
}
