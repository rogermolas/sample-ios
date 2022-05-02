//
//  String.swift
//  sampleapp
//
//  Created by Roger Molas on 4/4/22.
//

import Foundation

extension String {
    func match(pattern: String) -> [[String]] {
        let nsString = self as NSString
        return (try? NSRegularExpression(pattern: pattern, options: []))?.matches(in: self, options: [], range: NSMakeRange(0, nsString.length)).map { match in
            (0..<match.numberOfRanges).map {
                match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0))
            }
        } ?? []
    }
}
