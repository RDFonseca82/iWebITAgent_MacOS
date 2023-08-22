//
//  FormatDate.swift
//  MODA
//
//  Created by Admin on 14/03/2023.
//

import Foundation

struct FormatDt {
    static let dtF = DateFormatter()
    static let defaultDate = Date()
    
    static func toDate(stringData: String?, pattern: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        guard let stringData = stringData else { return nil }
        dtF.dateFormat = pattern
        return dtF.date(from: stringData)
    }
    
    static func formatDateToHuman(_ dt: Date) -> String {
        let ts = Int(Date().timeIntervalSince(dt))

        let days = Int(ts / (24 * 60 * 60))

        if days > 365 {
            let calc = days / 365
            let sufix = calc == 1 ? "ano" : "anos"
            return "há \(calc) \(sufix)"
        } else if days > 30 {
            let calc = days / 30
            let sufix = calc == 1 ? "mês" : "meses"
            return "há \(calc) \(sufix)"
        } else if days > 14 {
            let calc = days / 14
            let sufix = calc == 1 ? "semana" : "semanas"
            return "há \(calc) \(sufix)"
        } else if days > 0 {
            let sufix = days == 1 ? "dia" : "dias"
            return "há \(days) \(sufix)"
        }

        let segundos = ts % 60
        let minutes = ts / 60 % 60
        let hours = ts / 3600

        if hours > 0 {
            let sufix = hours == 1 ? "hora" : "horas"
            return "há \(hours) \(sufix)"
        } else if minutes > 0 {
            let sufix = minutes == 1 ? "minuto" : "minutos"
            return "há \(minutes) \(sufix)"
        } else {
            let sufix = segundos == 1 ? "segundo" : "segundos"
            return "há \(segundos) \(sufix)"
        }
    }
}
