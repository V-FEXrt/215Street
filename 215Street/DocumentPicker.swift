import SwiftUI
import MobileCoreServices

struct DocumentPicker: UIViewControllerRepresentable {
    func makeCoordinator() -> DocumentPickerCoordinator {
        return DocumentPickerCoordinator()
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let controller : UIDocumentPickerViewController
        
        if #available(iOS 14, *) {
            controller = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        } else {
            controller = UIDocumentPickerViewController(documentTypes: [String(kUTTypeData)], in: .import)
        }
        controller.delegate = context.coordinator
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) { }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        for url in urls {
            if let data = try? Data(contentsOf: url) {
                let dst = documentsUrl.appendingPathComponent(url.lastPathComponent)
                
                do {
                    try data.write(to: dst)
                } catch {
                    
                }
            }
        }
    }
}
