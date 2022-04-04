//
//  ViewController.swift
//  sampleapp
//
//  Created by Roger Molas on 4/4/22.
//

import UIKit
import Vision
import Photos
import MBProgressHUD

class ViewController: UIViewController  {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var inputLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    
    var imagePicker =  UIImagePickerController()
    
    lazy var request: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: self.requestHandler)
        request.recognitionLevel = .accurate
        return request
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

#if GREEN_CR
        self.view.backgroundColor = .green
#elseif GREEN_FILE
        self.view.backgroundColor = .green
#else
        self.view.backgroundColor = .red
#endif

    }
    
    func parse(string:String) {
        self.prcessing(flag: false)
        let pattern = #"((^|\s)-)?(\d*\.\d+|\d+)[\+\-\*\/]((^|\s)-)?(\d*\.\d+|\d+)"#
        let results = string.match(pattern: pattern)
        guard let expression = results.first?.first else {
            alert(title: "No expression Found!",
                  message: "Found: \(string)")
            return
        }
        DispatchQueue.main.async {
            self.inputLabel.text = expression
            let expn = NSExpression(format:expression)
            let total = expn.expressionValue(with: nil, context: nil)
            self.totalLabel.text = "= \(total ?? 0)"
        }
    }
    
    private func process(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let requests = [request]
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error {
                print("Error: \(error)")
                self.prcessing(flag: false)
            }
        }
    }
    
    private func requestHandler(request: VNRequest?, error: Error?) {
        if let error = error {
            alert(title: "Error", message: error.localizedDescription)
            return
        }
        guard let results = request?.results, results.count > 0 else {
            alert(title: "Error", message: "No text was found.")
            return
        }
        
        for result in results {
            var results = ""
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1) {
                    results.append(text.string)
                }
                self.parse(string: results)
            }
        }
    }
    
    //MARK: - Image Source
    @IBAction func addFile(sender: UIButton) {
        let actionSheet = UIAlertController(title: "Add File",
                                      message: "Please select file source",
                                      preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default) { action in
            self.openCamera()
        }
        let library = UIAlertAction(title: "Camera Roll", style: .default) { action in
            self.openPhotoLibrary()
        }
        let filePicker = UIAlertAction(title: "File System", style: .default) { action in
            self.openFilePicker()
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
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds
            actionSheet.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func openCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch (status) {
        case .denied, .restricted, .notDetermined:
            self.alert(title: "Unable to access the Camera",
                       message: "Please enable access to device settings")
        case .authorized:
            if(UIImagePickerController .isSourceTypeAvailable(.camera)) {
                imagePicker.sourceType = .camera
                imagePicker.delegate = self
                imagePicker.modalPresentationStyle = .fullScreen
                present(imagePicker, animated: true, completion: nil)
            } else {
                self.alert(title: "Camera Not Found", message: nil)
            }
        @unknown default:
            self.alert(title: "Camera Not Found", message: nil)
        }
    }
    
    private func openPhotoLibrary() {
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func openFilePicker() {
        let types: [UTType] = [UTType.png,UTType.jpeg]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true, completion: nil)
    }
    
    private func alert(title: String, message: String?) {
        DispatchQueue.main.async {
            self.prcessing(flag: false)
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func prcessing(flag: Bool) {
        DispatchQueue.main.async {
            if flag {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }
}

//MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let imageFile = info[.originalImage] as? UIImage else {
            alert(title: "Error", message: "File can't be read")
            return
        }
        self.prcessing(flag: true)
        self.imageView.image = imageFile
        inputLabel.text = ""
        totalLabel.text = ""
        process(image: imageFile)
        picker.dismiss(animated: true, completion: nil)
    }
}

//MARK: - UIDocumentPickerDelegate
extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
          let file = urls[0]
          do {
              let data = try Data.init(contentsOf: file.absoluteURL)
              guard let image = UIImage(data: data) else {
                  alert(title: "Error", message: "File can't be read")
                  return
              }
              self.prcessing(flag: true)
              self.imageView.image = image
              inputLabel.text = ""
              totalLabel.text = ""
              process(image: image)
          } catch {
              alert(title: "Error", message: "File can't be read")
          }
    }
}

