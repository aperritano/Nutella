//
//  String.swift
//  Test
//
//  Created by Gianluca Venturini & Anthony Perritano
import Foundation

extension String {
    subscript (i: Int) -> String {
        return String(Array(self.characters)[i])
    }
    
    // Chack if the passed string contains the actual string (starting from the beginning)
    func isSubinitialStringOf(_ string: String) -> Bool {
        var s1 = Array(self.characters)
        var s2 = Array(string.characters)
        
        if(s1.count == 0) {
            return true
        }
        
        if(s1.count > s2.count) {
            return false
        }
        
        if min(s1.count, s2.count)-1 >= 0 {
            for i in 0...min(s1.count,s2.count)-1 {
                if(s1[i] != s2[i]) {
                    return false
                }
            }
            return true
        }
        else {
            return false
        }
    }
}
