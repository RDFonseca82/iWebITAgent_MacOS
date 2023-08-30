//
//  Resource.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 30/08/2023.
//

import Foundation



class Resource {
    var data: Data?
    var statusCode: Int?
    var noInternet: Bool = false
    
    init(data: Data) {
        self.data = data
        
    }
    init(statusCode: Int) {
        self.statusCode = statusCode
        self.noInternet = false
        
    }
    init(noInternet: Bool) {
        self.noInternet = noInternet
        
    }
}

class Success: Resource {
    override init(data: Data) {
        super.init(data: data)
        
    }
}

class RError: Resource {
    override init(statusCode: Int) {
        super.init(statusCode: statusCode)
        
    }
    override init(noInternet: Bool) {
        super.init(noInternet: noInternet)
        
    }
    
}
