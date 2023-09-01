//
//  DateExtension.swift
//  iWebITService
//
//  Created by Admin on 01/09/2023.
//

import Foundation



extension Date {
    func toString(pattern: String = "dd/MM/yyyy HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}
