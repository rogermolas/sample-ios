//
//  UIAlertViewController.swift
//  sampleapp
//
//  Created by Roger Molas on 5/2/22.
//

import Foundation
import UIKit

extension UIAlertController {
    
    private convenience init(title: String, msg: String? = nil, action:((UIAlertAction) -> Void)? = nil) {
        self.init(title: "", message: "", preferredStyle: .alert)

        // Set title and message with the custom font
        let titleFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        self.setValue(NSAttributedString(string: title, attributes: [.font : titleFont]),
                      forKey: "attributedTitle")
        
        if let message = message {
            let msgFont = UIFont.systemFont(ofSize: 13)
            self.setValue(NSAttributedString(string: message, attributes: [.font : msgFont]),
                          forKey: "attributedMessage")
        }
        
        self.addAction(UIAlertAction(title: "OK", style: .default, handler: action))
    }
    
    convenience init(title: String, message: String? = nil) {
        self.init(title: title, msg: message)
    }
    
    convenience init(title: String, message: String? = nil, handler: ((UIAlertAction) -> Void)? = nil) {
        self.init(title: title, msg: message, action: handler)
    }
    
    func show(owner: UIViewController, completion: CompletionHandler? = nil) {
        owner.present(self, animated: true, completion: completion)
    }
}

