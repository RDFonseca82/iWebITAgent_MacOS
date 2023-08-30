//
//  PrepareSync.swift
//  iWebITAgent-macOS
//
//  Created by Admin on 29/08/2023.
//

import Foundation


func prepareAndSendSync(typeSync: String = "0", extraData: [String: Any]? = nil) {
    var data = [String: Any]()
    if typeSync == "1" {
        print("DOING FULL SYNC")
        data = getWmiObjects(wmiFullSyncList)
        
    } else if typeSync == "2" {
        print("DOING MIN SYNC")
        data = getWmiObjects(wmiMinSyncList)
        
    } else {
        print("SENDING SWITCH VARIABLE")
        guard let extraData = extraData else {
            print("ERROR")
            fatalError("Providing 0 as type sync requires extra data to be not null.")
            
        }
        data = extraData
        
    }
    if typeSync != "0" {
        data["TypeSync"] = typeSync
        
    }
    data["UniqueID"] = UniqueID
    data["IDSync"] = IDSync
    data["LastConnectDate"] = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
    data["AgentVersion"] = AgentVersion
    let eventsCount = (data["NTLogEvent"] as? [Any])?.count ?? 0
    if typeSync == "1" && eventsCount > 0 {
        data["EventWindows"] = "1"
        
    }
    let values = [
        "json": try! JSONSerialization.data(withJSONObject: data)
    ]
    let encodedItems = values.map { key, value in
        "\(key)=\(value)"
        
    }.map { item in
        item.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
    }
    if DoLog == "1" {
        let json = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        FileManager.default.createFile(atPath: VARS_SENT, contents: json, attributes: nil)
        
    }
    print("PREPARED TO SEND DATA")
    doUntil({
        let content = Data(encodedItems.joined(separator: "&").utf8)
        let result = sendRequest(method: "post", url: createOrSendDeviceInfoUrl, content: content)
        if result is Error {
            return true
            
        }
        print(try! String(data: result.data.content, encoding: .utf8))
        return false
        
    }, maxAttempts: 60)
    
}

