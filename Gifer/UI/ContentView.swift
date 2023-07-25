//
//  ContentView.swift
//  Gifer
//
//  Created by Yanun on 2023/7/14.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.injected) private var container
    @State private var isSelectFiles = false
    @State private var isSelectExportPath = false
    @State private var urls = [URL]([])
    @State private var exportPath = URL?(nil)
    @State private var progressing = false
    @State private var complete = true
    @State private var map = Dictionary<String, CGFloat>()
    @State private var tasked = Set<String>()
    
    var body: some View {
        ZStack {
            mainInterface()
                .blur(radius: progressing ? 5 : 0)
            progressInterface()
                .opacity(!progressing && complete ? 0 : 1)
        }
        .onReceive(container.appstate.convertProgress) { receiveProgress($0) }
        .onReceive(container.appstate.converting) {
            if $0 {
                progressing = true
                complete = false
            } else {
                progressing = false
            }
        }
    }
    
    @ViewBuilder
    private func mainInterface() -> some View {
        VStack {
            selectFileButton()
            selectedList()
            selectExportDirButton()
            converButton()
        }
        .padding()
    }
    
    @ViewBuilder
    private func progressInterface() -> some View {
        ZStack {
            Color.section
            VStack(spacing: 30) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        ForEach(urls, id: \.self) { url in
                            let id = url.encodeID
                            if let progress = map[id] {
                                ProgressRow(id: id, progress: progress)
                            } else {
                                ProgressRow(id: id, progress: 0)
                            }
                        }
                    }
                }
                Button {
                    complete = true
                    urls = []
                    map = [:]
                } label: {
                    Text("Done")
                }
                .disabled(progressing)
            }
            .padding()

        }
    }
    
    @ViewBuilder
    private func selectFileButton() -> some View {
        Button {
            isSelectFiles = true
        } label: {
            Text("Select Files")
        }
        .fileImporter(isPresented: $isSelectFiles, allowedContentTypes: [.movie, .quickTimeMovie], allowsMultipleSelection: true) { result in
            guard let urls = try? result.get() else {
                print("get result error")
                return
            }
            self.urls.append(contentsOf: urls)
        }
    }
    
    @ViewBuilder
    private func selectedList () -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            ForEach(urls, id: \.self) { url in
                Text(url.description)
            }
        }
        .frame(minWidth: 500, minHeight: 100)
        .background()
        .cornerRadius(7)
    }
    
    @ViewBuilder
    private func selectExportDirButton() -> some View {
        VStack {
            Button {
                selectExprotDir()
            } label: {
                Text("Select Export Path")
            }
            Text(exportPath?.description ?? ".")
        }
    }
    
    @ViewBuilder
    private func converButton() -> some View {
        Button {
            convert()
        } label: {
            Text("CONVERT")
        }
    }
}

extension ContentView {
    func convert() {
        guard let export = exportPath else {
            print("invalid export path")
            return
        }
        
        if urls.isEmpty {
            print("empty seleted video")
            return
        }
        
        container.interactor.pushConverting(true)
        
        tasked = []
        for u in urls {
            if tasked.contains(u.encodeID) { continue }
            tasked.insert(u.encodeID)
            Task {
                await createGIF(from: u, exportTo: export, updateProgress: { id, prg in
                    container.interactor.pushConvertProgress((id, prg))
                })
            }
        }
    }
    
    func selectExprotDir() {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose single directory | Our Code World";
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseFiles          = false
        dialog.canChooseDirectories    = true
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            guard let result = dialog.url else {
                print("get result error")
                return
            }
            exportPath = result
        }
    }
    
    func receiveProgress(_ m: (String, CGFloat)) {
        map[m.0] = m.1
        var count = map.count
        for elem in map {
            if elem.value == -1 || elem.value == 2 {
                count -= 1
            }
        }
        if count == 0 {
            container.interactor.pushConverting(false)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
