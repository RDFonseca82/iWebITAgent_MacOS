//
//  Color.swift
//  MODA
//
//  Created by Admin on 25/02/2023.
//

import Foundation
import SwiftUI

extension Color {
    
    static let theme = ColorTheme()
    static let darkYellow = Color(red: 0.88, green: 0.67, blue: 0)
    static let darkRed = Color(red: 0.65, green: 0, blue: 0)
    static let lightBlue = Color(red: 0.68, green: 0.85, blue: 0.90)
}


struct ColorTheme {
    
    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
    let surface = Color("SurfaceColor")
    let onBackground = Color("OnBackgroundColor")
    let disabled = Color("DisabledColor")
    let secondary = Color("SecondaryColor")
    let darkGray = Color("DarkGrayColor")
    
}
