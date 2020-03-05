//
//  ClassExtensions.swift
//  swifttest
//
//  Created by Sam Novotny on 27/02/2020.
//

import Foundation

extension Int {
    func hex16() -> String {
        return(String(format: "%04x", self))
    }

    func hex8() -> String {
        return(String(format: "%02x", self))
    }
    
    private func binaryN(bits: Int) -> String {
        var str = String(self, radix: 2)
        if str.count < bits {
            let padding = String (repeating: "0", count: bits - str.count)
            str = padding + str
        }
        return str
    }
    
    func binaryByte() -> String {
        return binaryN(bits: 8)
    }
    
    func binaryWord() -> String {
        return binaryN(bits: 16)
    }
}
