//
//  Color+Hex.swift
//  Tinodios
//
//  Created by Djaka Permana on 15/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    public convenience init(hex: String) {
        
        guard let color = UIColor.colorFrom(hex: hex) else {
            self.init()
            return
        }
        
        self.init(red: color.red,
                  green: color.green,
                  blue: color.blue,
                  alpha: color.alpha)
    }

    // swiftlint:disable large_tuple
    private static func colorFrom(hex: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        
        guard hex.hasPrefix("#") else {
            print("Invalid RGB string, missing '#' as prefix")
            return nil
        }
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        let index = hex.index(hex.startIndex, offsetBy: 1)
        let hex = String(hex[index...])
        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        
        guard scanner.scanHexInt64(&hexValue) else {
            print("Scan hex error")
            return nil
        }
        
        switch (hex.count) {
            
        case 3:
            red = CGFloat((hexValue & 0xF00) >> 8) / 15.0
            green = CGFloat((hexValue & 0x0F0) >> 4) / 15.0
            blue = CGFloat(hexValue & 0x00F) / 15.0
            
        case 4:
            red = CGFloat((hexValue & 0xF000) >> 12) / 15.0
            green = CGFloat((hexValue & 0x0F00) >> 8) / 15.0
            blue = CGFloat((hexValue & 0x00F0) >> 4) / 15.0
            alpha = CGFloat(hexValue & 0x000F) / 15.0
            
        case 6:
            red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(hexValue & 0x0000FF) / 255.0
            
        case 8:
            red = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
            green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
            blue = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
            alpha = CGFloat(hexValue & 0x000000FF) / 255.0
            
        default:
            print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
            
        }
        
        return (red: red, green: green, blue: blue, alpha: alpha)
    }
    
}

