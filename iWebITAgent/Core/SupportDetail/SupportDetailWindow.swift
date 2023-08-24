//
//  SupportDetailWindow.swift
//  iWebITAgent
//
//  Created by Admin on 16/08/2023.
//

import SwiftUI

struct SupportDetailWindow: View {
    @State private var window: NSWindow?
    
    @EnvironmentObject var globalVm: GlobalViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Detalhes")
                .font(.system(size: 35, weight: .semibold))
                .foregroundColor(.theme.onBackground)
                .padding([.leading, .top], 10)
                .padding(.bottom, -3)
            Divider()
                .offset(y: 8)
            ScrollView {
                VStack(spacing: 12) {
                    Text(globalVm.selectedSupport.nome ?? "-")
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.lightBlue)
                    
                    Text(formatMessageDate())
                        .foregroundColor(.gray)
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(globalVm.selectedSupport.deviceSupport ?? "-")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
            }
        }
        .background(WindowAccessor(window: $window, initialTitle: "Detalhes", shouldCenter: false))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                
            }
        }
    }
    
    func formatMessageDate() -> String {
        let calendar = Calendar.autoupdatingCurrent
        let date = globalVm.selectedSupport.deviceSupportDate
        
        let member1 = FormatDt.shared.formatDateToHuman(date)
        
        let dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let year = dateComponents.year ?? 2000
        let month = dateComponents.month ?? 1
        let day = dateComponents.day ?? 1
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        
        let monthString = FormatDt.shared.months[month-1]
        let hourString = String(hour).count == 1 ? "0\(hour)" : "\(hour)"
        let minuteString = String(minute).count == 1 ? "0\(minute)" : "\(minute)"
        
        let member2 = "\(day) de \(monthString) de \(year), \(hourString):\(minuteString)"
        
        return "\(member1) (\(member2))"
    }
}
