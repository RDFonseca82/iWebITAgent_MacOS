import SwiftUI

struct AppInfo: Codable {
    @AppInfoProperty("uniqueid")
    static var uniqueid: String
    
    @AppInfoProperty("idsync")
    static var idsync: String
    
    @AppInfoProperty("idcompany")
    static var idcompany: String
    
    @AppInfoProperty("companyname")
    static var companyname: String
    
    @AppInfoProperty("agentversion")
    static var agentversion: String
    
    @AppInfoProperty("fullsync")
    static var fullsync: Bool
    
    @AppInfoProperty("devicelocation")
    static var devicelocation: Bool
    
    @AppInfoProperty("reboot")
    static var reboot: Bool
    
    @AppInfoProperty("shutdown")
    static var shutdown: Bool
    
    @AppInfoProperty("timesync")
    static var timesync: String
    
    @AppInfoProperty("timealive")
    static var timealive: String
    
    @AppInfoProperty("nexttimesync")
    static var nexttimesync: String
    
    @AppInfoProperty("nexttimealive")
    static var nexttimealive: String
    
    @AppInfoProperty("dolog")
    static var dolog: Bool
}

@propertyWrapper
struct AppInfoProperty<T> {
    private let key: String

    init(_ key: String) {
        self.key = key
    }

    var wrappedValue: T {
        get {
            AppInfoManager.shared.getValue(key: key) as! T
        }
        set {
            AppInfoManager.shared.setValue(key: key, value: newValue)
        }
    }
}
