//
//  NetworkingManager.swift
//  MODA
//
//  Created by Admin on 25/02/2023.
//

import Foundation
import Combine

class NetworkingManager {
    
    static func download(url: String, parameters: [String: String] = [:]) async throws -> Data {
        var components = URLComponents(string: url)!
        components.queryItems = parameters.map({ (key, value) in
            URLQueryItem(name: key, value: value)
        })
        
        let request = URLRequest(url: components.url!)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return try handleResponse(data: data, response: response)
        } catch {
            throw error
        }
    }
    
    static func send(url: String, parameters: [String: String] = [:]) async throws {
        let url = URL(string: url)!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .fragmentsAllowed)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let _ = try handleResponse(data: data, response: response)
        } catch {
            throw error
        }
    }
    
    static func send(url: String, jsonData: [String:Any]) async throws -> String {
        let url = URL(string: url)!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formURLEncoded(from: jsonData)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let sortedData = try handleResponse(data: data, response: response)
            
            return String(data: sortedData, encoding: .utf8) ?? "NULL"
        } catch {
            throw error
        }
    }
    
    static func send(url: String, multipart: MultipartRequest) async throws {
        let url = URL(string: url)!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let _ = try handleResponse(data: data, response: response)
        } catch {
            throw error
        }
    }
    
    static func handleResponse(data: Data?, response: URLResponse?) throws -> Data {
        guard
            let data = data,
            let response = response as? HTTPURLResponse,
              response.statusCode >= 200 && response.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
    
    static func formURLEncoded(from parameters: [String: Any]) -> Data {
        var components: [String] = []
        for (key, value) in parameters {
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            components.append("\(encodedKey)=\(encodedValue)")
        }
        return components.joined(separator: "&").data(using: .utf8)!
    }
}
