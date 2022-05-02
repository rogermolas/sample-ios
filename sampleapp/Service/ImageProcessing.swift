//
//  ImageProcessing.swift
//  sampleapp
//
//  Created by Roger Molas on 5/2/22.
//

import Foundation
import UIKit
import Vision

public typealias CompletionHandler = (() -> Swift.Void)
public typealias ResultHandler = ((_ expression: String?, _ error: String?) -> Swift.Void)

class ImageProcessing {
    
    static let shared = ImageProcessing()
    
    var resultHandler:ResultHandler? = nil
    
    lazy var request: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: self.requestHandler)
        request.recognitionLevel = .accurate
        return request
    }()
    

    func read(image: UIImage, resultHandler: @escaping ResultHandler) {
        self.resultHandler = resultHandler
        self.process(image: image)
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
                self.resultHandler!(nil, "\(error.localizedDescription)")
            }
        }
    }
    
    private func requestHandler(request: VNRequest?, error: Error?) {
        if let error = error {
            self.resultHandler!(nil, error.localizedDescription)
            return
        }
        guard let results = request?.results, results.count > 0 else {
            self.resultHandler!(nil, "No text was found.")
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
    
    private func parse(string: String) {
        print("RAW RESULTS: \(string)")
        
        let pattern = #"((^|\s)-)?(\d*\.\d+|\d+)[\+\-\*\/]((^|\s)-)?(\d*\.\d+|\d+)"#
        let results = string.match(pattern: pattern)
        guard let expression = results.first?.first else {
            self.resultHandler!(nil, "No expression Found!")
            return
        }
        DispatchQueue.main.async {
            self.resultHandler!(expression, nil)
        }
    }
}
