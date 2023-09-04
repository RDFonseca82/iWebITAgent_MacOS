//
//  Toast.swift
//  MODA
//
//  Created by Admin on 08/04/2023.
//

import SwiftUI
import Combine

struct Toast: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var vm: SnackbarViewModel
    
    var body: some View {
        HStack {
            Text(vm.text)
                .padding(10)
                .frame(minWidth: 300, minHeight: 50, alignment: .leading)
        }
        .foregroundColor(.theme.background)
        .background(Color(white: colorScheme == .dark ? 0.6 : 0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 10)
        .onTapGesture {
            vm.close()
        }
    }
}

class SnackbarViewModel: ObservableObject {
    @Published var showing = false
    @Published var text = ""
    
    private var sortJob: Task<(), Never>? = nil

    func showSnackbar(text newText: String, timeMillis: UInt64 = 4000) {
        if newText.isEmpty { return }

        if newText == text && showing { return }

        sortJob?.cancel()

        sortJob = Task {
            if (showing) {
                await MainActor.run {
                    withAnimation {
                        showing = false
                    }
                }
                
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
            
            await MainActor.run {
                withAnimation {
                    text = newText
                    showing = true
                }
            }
            
            try? await Task.sleep(nanoseconds: UInt64(timeMillis*1_000_000))
            
            await MainActor.run {
                withAnimation {
                    showing = false
                }
            }
        }
    }

    func close() {
        withAnimation {
            showing = false
        }
    }
}



struct CustomSnackbarData {
    var showing: Bool = false
    var text: String = ""
}

