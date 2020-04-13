//
//  ContentView.swift
//  Recordings
//
//  Created by Florian Kugler on 20-03-2020.
//  Copyright © 2020 objc.io. All rights reserved.
//

import SwiftUI

func ??<A: View, B: View>(lhs: A?, rhs: B) -> some View {
    Group {
        if lhs != nil {
            lhs!
        } else {
            rhs
        }
    }
}

extension Binding where Value == Item {
    var destination: some View {
        Group {
            if wrappedValue.isFolder {
                FolderList(folder: self)
            } else {
                EmptyView()
//                PlayerWrapper(recording: self as! Recording)
            }
        }
    }
}

import Combine

@dynamicMemberLookup
final class Lazy<O: ObservableObject>: ObservableObject {
    var objectWillChange: O.ObjectWillChangePublisher {
        value.objectWillChange
    }
    var value: O {
        get {
            buildValueIfNeeded()
            return _value!
        }
    }

    private var _value: O? = nil
    private let build: () -> O
    
    init(_ build: @escaping () -> O) {
        self.build = build
    }
    
    func buildValueIfNeeded() {
        guard _value == nil else { return }
        _value = build()
    }
    
    subscript<Prop>(dynamicMember kp: ReferenceWritableKeyPath<O, Prop>) -> Prop {
        get {
            value[keyPath: kp]
        }
        set {
            value[keyPath: kp] = newValue
        }
    }
    
    subscript<Prop>(dynamicMember kp: KeyPath<O, Prop>) -> Prop {
        value[keyPath: kp]
    }
}

//extension Item {
//    var isDeleted: Bool { parent == nil }
//}

//struct PlayerWrapper: View {
//    @ObservedObject var recording: Recording
//
//    var body: some View {
//        Group {
//            if recording.isDeleted {
//                NoRecordingSelected()
//            } else {
//                PlayerView(recording: recording) ?? Text("Something went wrong.")
//            }
//        }
//    }
//}

//struct PlayerView: View {
//    let recording: Recording
//    @State private var name: String = ""
//    @State private var position: TimeInterval = 0
//    @ObservedObject private var player: Lazy<Player>
//
//    init?(recording: Recording) {
//        self.recording = recording
//        self._name = State(initialValue: recording.name)
//        guard let u = recording.fileURL else { return nil }
//        self.player = Lazy { Player(url: u)! } // todo
//    }
//
//    var playButtonTitle: String {
//        if player.isPlaying { return "Pause" }
//        else if player.isPaused { return "Resume" }
//        else { return "Play" }
//    }
//
//    var body: some View {
//        VStack(spacing: 20) {
//            HStack {
//                Text("Name")
//                TextField("Name", text: $name, onEditingChanged: { _ in
//                    self.recording.setName(self.name)
//                })
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//            }
//            HStack {
//                Text(timeString(0))
//                Spacer()
//                Text(timeString(player.duration))
//            }
//            Slider(value: $player.time, in: 0...player.duration)
//            Button(playButtonTitle) { self.player.value.togglePlay() }
//                .buttonStyle(PrimaryButtonStyle())
//            Spacer()
//        }
//        .padding()
//    }
//}

extension Item {
    var symbolName: String {
        self.isFolder ? "folder" : "waveform"
    }
}

extension Item {
    subscript(_ id: UUID) -> Item {
        get {
            contents!.first(where: { $0.id == id })!
        }
        set {
            let idx = contents!.firstIndex(where: { $0.id == id })!
            contents![idx] = newValue
        }
    }
}

struct FolderList: View {
    @Binding var folder: Item
    @State var presentsNewRecording = false
    @State var createFolder = false
    var body: some View {
        List {
            ForEach(folder.contents!) { item in
                NavigationLink(destination: self.$folder[item.id].destination) {
                    HStack {
                        Image(systemName: item.symbolName)
                            .frame(width: 20, alignment: .leading)
                        Text(item.name)
                    }
                }.isDetailLink(!item.isFolder)
            }.onDelete(perform: { indices in
                let items = indices.map { self.folder.contents![$0] }
                for item in items {
                    self.folder.remove(item)
                }
            })
        }
        .textAlert(isPresented: $createFolder, title: "Create Folder", placeholder: "Name", callback: { name in
            guard let n = name else { return }
            self.folder.add(Item(folder: n))
        })
        .navigationBarTitle("Recordings")
        .navigationBarItems(trailing: HStack {
            Button(action: {
                self.createFolder = true
            }, label: {
                Image(systemName: "folder.badge.plus")
            })
            Button(action: {
                self.presentsNewRecording = true
            }, label: {
                Image(systemName: "waveform.path.badge.plus")
            })
        })
//        .sheet(isPresented: $presentsNewRecording) {
//            RecordingView(folder: self.folder, isPresented: self.$presentsNewRecording)
//        }
    }
}

struct AlertWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let title: String
    let placeholder: String
    let callback: (String?) -> ()
    let content: Content
    
    init(isPresented: Binding<Bool>, title: String, placeholder: String, callback: @escaping (String?) -> (), content: Content) {
        self._isPresented = isPresented
        self.title = title
        self.placeholder = placeholder
        self.callback = callback
        self.content = content
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<AlertWrapper>) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: UIViewControllerRepresentableContext<AlertWrapper>) {
        uiViewController.rootView = content
        if isPresented && uiViewController.presentedViewController == nil {
            let vc = modalTextAlert(title: title, placeholder: placeholder, callback: { result in
                self.isPresented = false
                self.callback(result)
            })
            uiViewController.present(vc, animated: true)
        }
    }
}

extension View {
    func textAlert(isPresented: Binding<Bool>, title: String, placeholder: String = "", callback: @escaping (String?) -> ()) -> some View {
        AlertWrapper(isPresented: isPresented, title: title, placeholder: placeholder, callback: callback, content: self)
    }
}

//struct RecordingView: View {
//    let folder: Folder
//    @Binding var isPresented: Bool
//
//    private let recording = Recording(name: "", uuid: UUID())
//    @ObservedObject private var recorder: Lazy<Recorder>
//    @State private var isSaving: Bool = false
//    @State private var deleteOnCancel = true
//
//    init?(folder: Folder, isPresented: Binding<Bool>) {
//        self.folder = folder
//        self._isPresented = isPresented
//        guard let s = self.folder.store, let url = s.fileURL(for: self.recording) else { return nil }
//        self.recorder = Lazy { Recorder(url: url) }
//    }
//
//    func save(name: String?) {
//        if let n = name {
//            recording.setName(n)
//            folder.add(recording)
//            self.deleteOnCancel = false
//        }
//        isPresented = false
//    }
//
//    func cancel() {
//        recorder.value.stop()
//        guard self.deleteOnCancel else { return }
//        recording.deleted()
//    }
//
//    var body: some View {
//        VStack(spacing: 20) {
//            if recorder.error == .noPermission {
//                Text("Go to Settings.")
//            } else if recorder.error != nil {
//                Text("An error occurred.")
//            } else {
//                Text("Recording")
//                Text(timeString(recorder.currentTime))
//                    .font(.title)
//                Button("Stop") {
//                    self.recorder.value.stop()
//                    self.isSaving = true
//                }
//                .buttonStyle(PrimaryButtonStyle())
//            }
//        }
//        .padding()
//        .textAlert(isPresented: $isSaving, title: "Save Recording", placeholder: "Name", callback: { self.save(name: $0) })
//        .onDisappear {
//            self.cancel()
//        }
//    }
//}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.orange))
            
    }
}

struct NoRecordingSelected: View {
    let body = Text("No recording selected.")
}

struct ContentView: View {
    @ObservedObject var store = Store.shared
    var body: some View {
        NavigationView {
            FolderList(folder: $store.rootFolder)
            NoRecordingSelected()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
