//
//  service.swift
//  iWebITService
//
//  Created by Admin on 26/08/2023.
//

import SwiftUI

@main
struct Service {
    static func main() async throws {
        Constants.shared.LOG_FILE = Constants.shared.LOG_FILE.appendingPathComponent("log_service.log")
        Constants.shared.OLD_LOG_FILE = Constants.shared.OLD_LOG_FILE.appendingPathComponent("old_log_service.log")
        let alert = NSAlert()
        alert.messageText = "Agente iWebIT"
        alert.informativeText = "O serviço irá realizar uma sincronização completa."
        alert.addButton(withTitle: "Ok")
        alert.alertStyle = .informational
        alert.runModal()
//        await mainLoop()
    }
}
