//
//  FileSourceManager.swift
//  sampleapp
//
//  Created by Roger Molas on 5/2/22.
//

import Foundation
import UIKit

class FileSourceManager {
    static let shared = FileSourceManager()
    
    func addSource(target:UIButton,
                   owner: UIViewController,
                   cameraAction: @escaping CompletionHandler,
                   cameraRollAction: @escaping CompletionHandler,
                   fileAction: @escaping CompletionHandler) {
        let actionSheet = UIAlertController(title: "Add File",
                                      message: "Please select file source",
                                      preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default) { action in
            cameraAction()
        }
        let library = UIAlertAction(title: "Camera Roll", style: .default) { action in
            cameraRollAction()
        }
        let filePicker = UIAlertAction(title: "File System", style: .default) { action in
            fileAction()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
#if GREEN_CR
        actionSheet.addAction(library)
#elseif GREEN_FILE
        actionSheet.addAction(filePicker)
#elseif RED_CAMERA
        actionSheet.addAction(camera)
#else
        actionSheet.addAction(library)
#endif
        actionSheet.addAction(cancel)
        
        // iPad
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            actionSheet.popoverPresentationController?.sourceView = target
            actionSheet.popoverPresentationController?.sourceRect = target.bounds
            actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        owner.present(actionSheet, animated: true, completion: nil)
    }
}
