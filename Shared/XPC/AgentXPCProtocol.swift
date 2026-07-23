import Foundation

@objc protocol AgentXPCProtocol {
    func fetchState(withReply reply: @escaping (Data?, NSError?) -> Void)
    func requestSynchronization(full: Bool, withReply reply: @escaping (NSError?) -> Void)
    func storePushToken(_ token: Data, withReply reply: @escaping (NSError?) -> Void)
}

enum AgentXPCConfiguration {
    static let machServiceName = "app.iwebit.agent.xpc"
    static let allowedTeamID = "R8VHDNRMJJ"
    static let allowedBundleIdentifiers = [
        "com.rdfonseca.iWebIT",
        "com.rdfonseca.iWebITSysTray",
        "app.iwebit.agent",
        "app.iwebit.mobile"
    ]
}
