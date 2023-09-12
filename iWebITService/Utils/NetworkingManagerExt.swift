//
//  NetworkingManagerExt.swift
//  iWebITService
//
//  Created by Admin on 06/09/2023.
//

import Foundation


extension NetworkingManager {
    static func download(url: String, parameters: [String: String] = [:]) throws -> Data {
        var components = URLComponents(string: url)!
        components.queryItems = parameters.map({ (key, value) in
            URLQueryItem(name: key, value: value)
        })
        
        let request = URLRequest(url: components.url!)
        
        do {
            var data: Data?
            var response: URLResponse?
            var error: Error?
            
            let semaphore = DispatchSemaphore(value: 0)
            
            URLSession.shared.dataTask(with: request, completionHandler: {
                data = $0
                response = $1
                error = $2
                semaphore.signal()
            }).resume()
            
            _ = semaphore.wait(timeout: .distantFuture)
            
            if let error = error {
                throw error
            }
            
            return try handleResponseS(data: data, response: response)
        } catch {
            AppInfo.net = "0"
            throw error
        }
    }
    
    static func send(url: String, jsonData: [String:Any]) throws {
        let url = URL(string: url)!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formURLEncoded(from: jsonData)
        
        do {
            var data: Data?
            var response: URLResponse?
            var error: Error?
            
            let semaphore = DispatchSemaphore(value: 0)
            
            URLSession.shared.dataTask(with: request, completionHandler: {
                data = $0
                response = $1
                error = $2
                semaphore.signal()
            }).resume()
            
            _ = semaphore.wait(timeout: .distantFuture)
            
            if let error = error {
                throw error
            }
            let sortedData = try handleResponseS(data: data, response: response)
            
            print(String(data: sortedData, encoding: .utf8) ?? "NULL")
        } catch {
            AppInfo.net = "0"
            throw error
        }
    }
    
    static func handleResponseS(data: Data?, response: URLResponse?) throws -> Data {
        guard
            let data = data,
            let response = response as? HTTPURLResponse,
              response.statusCode >= 200 && response.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
        AppInfo.net = "1"
        return data
    }
}
