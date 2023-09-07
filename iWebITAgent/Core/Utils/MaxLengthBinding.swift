//
//  MaxLengthBinding.swift
//  iWebITAgent
//
//  Created by Admin on 23/08/2023.
//

import SwiftUI

extension Binding where Value == String {
    func max(_ limit: Int) -> Self {
        if self.wrappedValue.count > limit {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(limit))
            }
        }
        return self
    }
    func noNewLine() -> Self {
        DispatchQueue.main.async {
            self.wrappedValue = self.wrappedValue.replacingOccurrences(of: "\n", with: "")
        }
        return self
    }
}
