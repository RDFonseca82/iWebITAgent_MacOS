import SwiftUI
import UIKit

struct MobileRootView: View {
    var body: some View {
        NavigationView {
            List(Destination.allCases) { destination in
                NavigationLink(destination: destination.view) {
                    Label(destination.title, systemImage: destination.systemImage)
                }
            }
            .navigationTitle("iWebIT")

            DeviceOverviewView()
        }
        .navigationViewStyle(.columns)
    }
}

private enum Destination: String, CaseIterable, Identifiable {
    case overview
    case incidents
    case support
    case diagnostics
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Dispositivo"
        case .incidents: return "Ocorrências"
        case .support: return "Suporte"
        case .diagnostics: return "Diagnóstico"
        case .settings: return "Definições"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "laptopcomputer.and.iphone"
        case .incidents: return "list.bullet.rectangle"
        case .support: return "questionmark.bubble"
        case .diagnostics: return "stethoscope"
        case .settings: return "gearshape"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .overview: DeviceOverviewView()
        case .incidents: LiveIncidentsView()
        case .support: LiveSupportRequestView()
        case .diagnostics: ProtectedDiagnosticsView()
        case .settings: MobileSettingsView()
        }
    }
}

private struct DeviceOverviewView: View {
    var body: some View {
        List {
            Section("Estado") {
                DetailRow(label: "Plataforma", value: UIDevice.current.systemName)
                DetailRow(label: "Versão", value: UIDevice.current.systemVersion)
                DetailRow(label: "Modelo", value: UIDevice.current.model)
            }
            Section("Sincronização") {
                Label("Ligação autenticada por dispositivo", systemImage: "lock.shield")
            }
        }
        .navigationTitle("Dispositivo")
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

private struct MobileSettingsView: View {
    @EnvironmentObject private var runtime: MobileRuntime

    var body: some View {
        Form {
            Section("Capacidades neste dispositivo") {
                Text("A app sincroniza apenas informação disponibilizada pelas APIs públicas do iOS/iPadOS.")
                Text("Reinício, encerramento, remoção de outras apps e screenshots silenciosos não estão disponíveis.")
                Button("Sincronizar localização agora") {
                    Task { await runtime.synchronizeLocationNow() }
                }
                .disabled(runtime.isSynchronizing)
                if let message = runtime.locationSyncMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Section("Privacidade") {
                Text("A app identifica a origem e o estado de cada categoria sincronizada.")
                Link("Política de privacidade", destination: URL(string: "https://www.iwebit.app/privacypolicy.php")!)
            }
            ProtectedLogoutSection()
        }
        .navigationTitle("Definições")
    }
}