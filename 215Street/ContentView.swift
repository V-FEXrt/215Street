//
//  ContentView.swift
//  215Street
//
//  Created by Ashley Coleman on 12/9/20.
//

import SwiftUI
import DirectoryWatcher

struct Item: Identifiable {
    let id = UUID()
    var path: URL
    let image: String?
    var isDirectory = false
    var children: [Item]?
    
    func name() -> String {
        return path.lastPathComponent
    }
}

struct Footer: View {
    @Binding var addFileTapped: Bool
    
    @Binding var hasEncryptionKey: Bool
    
    var body: some View {
        VStack {
            if !hasEncryptionKey {
                Text("Encryption key not found.").foregroundColor(.red)
                Text("Please upload file named 'key.bin'").foregroundColor(.red)
            }
            HStack {
                Button("Add File") { addFileTapped = true }.padding()
    //            Spacer()
    //            Button("Support App") { }.padding()
            }
        }

    }
}

struct ListItem: View {
    @State var item: Item
    let tagStore = TagStore()
    
    let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    
    var body: some View {
        HStack {
            if let img = item.image {
                if item.isDirectory {
                    Image(systemName: img)
                } else {
                    if let uiImage = UIImage(contentsOfFile: img) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .clipped()
                    }
                }
            }
            
            Text(item.name())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if (item.isDirectory) { return }
            guard let documentsUrl = documentsUrl else { return }
            let encryptionKey = documentsUrl.appendingPathComponent("key.bin")
            
            if !FileManager.default.fileExists(atPath: encryptionKey.path) {
                return
            }
            
            
            if tagStore.amiitool == nil {
                
                tagStore.start(key_retail: documentsUrl.appendingPathComponent("key.bin").path)
            }
            
            tagStore.load(item.path)
            tagStore.scan()
        }
    }
}


struct ContentView: View {
    @State private var items: [Item] = []
    @State private var shouldShowDocumentPicker = false
    @State private var hasEncryptionKey = false
    
    @State private var watcher: DirectoryDeepWatcher?
    
    var body: some View {
        VStack {
            List(items, children: \.children) { row in
                ListItem(item: row)
            }
            Footer(addFileTapped: $shouldShowDocumentPicker, hasEncryptionKey: $hasEncryptionKey)
        }
        .onAppear(perform: onAppear)
        .sheet(isPresented: $shouldShowDocumentPicker) {
            DocumentPicker()
        }
    }
    
    private func onAppear() {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        items = LoadFilesUnderDirectory(directory: documentsUrl)
        let encryptionKey = documentsUrl.appendingPathComponent("key.bin")
        hasEncryptionKey = FileManager.default.fileExists(atPath: encryptionKey.path)
        
        watcher = DirectoryDeepWatcher.watch(documentsUrl)
        
        watcher?.onFolderNotification = { _ in
            items = LoadFilesUnderDirectory(directory: documentsUrl)
            hasEncryptionKey = FileManager.default.fileExists(atPath: encryptionKey.path)
        }
    }
    
    private func LoadFilesUnderDirectory(directory: URL) -> [Item] {
        let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        let filter = (contents ?? []).filter({ (item) -> Bool in
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return isDir || item.pathExtension == "bin"
        }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        
        return filter.map({
            if (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false {
                return Item(path: $0, image: "folder", isDirectory: true, children: LoadFilesUnderDirectory(directory: $0))
            } else {
                // key.bin is treated as a special item
                if ($0.lastPathComponent == "key.bin") {
                    // set isDirectory to true as a lazy hack to make it not-tappable
                    return Item(path: $0, image: "key", isDirectory: true)
                }
                
                let parent = $0.deletingLastPathComponent().absoluteURL
                let filename = $0.deletingPathExtension().lastPathComponent
                let jpg = parent.appendingPathComponent(filename).appendingPathExtension("jpg")
                let png = parent.appendingPathComponent(filename).appendingPathExtension("png")
                var img: String? = nil
                
                if (try? jpg.checkPromisedItemIsReachable()) ?? false {
                    img = jpg.path
                }
                
                if (try? png.checkPromisedItemIsReachable()) ?? false {
                    img = png.path
                }
                
                return Item(path: $0, image: img)
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
