//
//  ViewController.swift
//  sampleapp
//
//  Created by Roger Molas on 4/4/22.
//

import UIKit
import Photos
import MBProgressHUD

class ViewController: UIViewController  {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var inputLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    
    var imagePicker =  UIImagePickerController()

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
    
    //MARK: - Image processing
    func process(image: UIImage) {
        self.prcessing(flag: true)
        ImageProcessing.shared.read(image: image) { expression, error in
            self.prcessing(flag: false)
            guard error == nil else {
                self.alert(title: error!)
                return
            }
            self.inputLabel.text = expression
            let expn = NSExpression(format:expression!)
            let total = expn.expressionValue(with: nil, context: nil)
            self.totalLabel.text = "\(total ?? 0)"
        }
    }
    
    //MARK: - Image Source
    @IBAction func addFile(sender: UIButton) {
        FileSourceManager.shared.addSource(target: sender, owner: self) {
            self.openCamera()
        } cameraRollAction: {
            self.openPhotoLibrary()
        } fileAction: {
            self.openFilePicker()
        }
    }
    
    private func openCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch (status) {
        case .denied, .restricted, .notDetermined:
            UIAlertController.init(
                title: "Unable to access the Camera",
                message: "Please enable access to device settings") { action in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    UIApplication.shared.open(url)
            }.show(owner: self)

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
    
    private func alert(title: String, message: String? = nil) {
        DispatchQueue.main.async {
            UIAlertController.init(title: title, message: message).show(owner: self)
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
              self.imageView.image = image
              inputLabel.text = ""
              totalLabel.text = ""
              process(image: image)
          } catch {
              alert(title: "Error", message: "File can't be read")
          }
    }
}

