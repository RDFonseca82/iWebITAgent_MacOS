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
    static var fullsync: String
    
    @AppInfoProperty("devicelocation")
    static var devicelocation: String
    
    @AppInfoProperty("reboot")
    static var reboot: String
    
    @AppInfoProperty("shutdown")
    static var shutdown: String
    
    @AppInfoProperty("timesync")
    static var timesync: String
    
    @AppInfoProperty("timealive")
    static var timealive: String
    
    @AppInfoProperty("nexttimesync")
    static var nexttimesync: String
    
    @AppInfoProperty("nexttimealive")
    static var nexttimealive: String
    
    @AppInfoProperty("firstrun")
    static var firstrun: String
    
    @AppInfoProperty("allprepared")
    static var allprepared: String
    
    @AppInfoProperty("net")
    static var net: String
    
    @AppInfoProperty("manualupdate")
    static var manualupdate: String
    
    @AppInfoProperty("dolog")
    static var dolog: String
    
    static func isLoggedIn() -> Bool {
        return idsync.isNotBlank() && idsync != "IDSYNC" && idsync != "?"
    }
}

@propertyWrapper
struct AppInfoProperty {
    private let key: String

    init(_ key: String) {
        self.key = key
    }

    var wrappedValue: String {
        get {
            AppInfoManager.shared.getValue(key: key)
        }
        set {
            AppInfoManager.shared.setValue(key: key, value: newValue)
        }
    }
}
