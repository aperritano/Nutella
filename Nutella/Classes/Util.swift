//
//  Util.swift
//  Nutella
//
//  Created by Anthony Perritano on 9/28/16.
//  Copyright © 2016 ltg.evl.uic.edu. All rights reserved.
//

import Foundation

extension String {
    
    func fileName() -> String {
        
        if let fileNameWithoutExtension = NSURL(fileURLWithPath: self).deletingPathExtension?.lastPathComponent {
            return fileNameWithoutExtension
        } else {
            return ""
        }
    }
    
    func fileExtension() -> String {
        
        if let fileExtension = NSURL(fileURLWithPath: self).pathExtension {
            return fileExtension
        } else {
            return ""
        }
    }
}
