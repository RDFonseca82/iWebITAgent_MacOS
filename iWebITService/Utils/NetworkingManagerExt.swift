//
//  NetworkingManagerExt.swift
//  iWebITService
//
//  Created by Admin on 06/09/2023.
//

import Foundation


extension NetworkingManager {
    static func download(url: String, parameters: [String: String] = [:]) throws -> Data {
        guard var components = URLComponents(string: url),
              components.scheme?.lowercased() == "https" else {
            throw URLError(.appTransportSecurityRequiresSecureConnection)
        }
        components.queryItems = parameters.map({ (key, value) in
            URLQueryItem(name: key, value: value)
        })
        
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        
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
            
            if semaphore.wait(timeout: .now() + 25) == .timedOut { throw URLError(.timedOut) }
            
            if let error = error {
                throw error
            }
            
            return try handleResponseS(data: data, response: response)
        } catch {
            AppInfo.net = "0"
            throw error
        }
    }
    
    static func send(url: String, jsonPayload: Data) throws {
        guard let url = URL(string: url), url.scheme?.lowercased() == "https" else {
            throw URLError(.appTransportSecurityRequiresSecureConnection)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonPayload
        
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
            
            if semaphore.wait(timeout: .now() + 25) == .timedOut { throw URLError(.timedOut) }
            
            if let error = error {
                throw error
            }
            let sortedData = try handleResponseS(data: data, response: response)
            
            log(sortedData.toString() ?? "NULL")
        } catch {
            AppInfo.net = "0"
            throw error
        }
    }
    
    static func send(url: String, data: [String:Any]) throws {
        guard let url = URL(string: url), url.scheme?.lowercased() == "https" else {
            throw URLError(.appTransportSecurityRequiresSecureConnection)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = formURLEncoded(from: data)
        
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
            
            if semaphore.wait(timeout: .now() + 25) == .timedOut { throw URLError(.timedOut) }
            
            if let error = error {
                throw error
            }
            let sortedData = try handleResponseS(data: data, response: response)
            
            log(sortedData.toString() ?? "NULL")
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
            if let _response = response as? HTTPURLResponse {
                log("RESPONSE STATUS CODE: \(_response.statusCode)", important: true)
            } else {
                log("ERROR CASTING HTTPURLResponse", important: true)
            }
            throw URLError(.badServerResponse)
        }
        AppInfo.net = "1"
        return data
    }
}
