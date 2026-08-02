import SwiftUI
import UIKit

struct MobileRootView: View {
    var body: some View {
#if DEBUG
        if let destination = AppStoreScreenshotMode.destination {
            AppStoreScreenshotRootView(destination: destination)
        } else {
            standardNavigation
        }
#else
        standardNavigation
#endif
    }

    private var standardNavigation: some View {
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

#if DEBUG
private enum AppStoreScreenshotMode {
    static var destination: Destination? {
        guard ProcessInfo.processInfo.arguments.contains("--app-store-screenshots") else {
            return nil
        }
        guard let argument = ProcessInfo.processInfo.arguments.first(where: {
            $0.hasPrefix("--screenshot=")
        }) else {
            return .overview
        }
        return Destination(rawValue: String(argument.dropFirst("--screenshot=".count))) ?? .overview
    }
}

private struct AppStoreScreenshotRootView: View {
    let destination: Destination

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationView {
                List(Destination.allCases) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .foregroundStyle(item == destination ? Color.accentColor : Color.primary)
                }
                .navigationTitle("iWebIT")

                screenshotDestination
            }
            .navigationViewStyle(.columns)
        } else {
            NavigationView {
                screenshotDestination
            }
            .navigationViewStyle(.stack)
        }
    }

    @ViewBuilder
    private var screenshotDestination: some View {
        if destination == .diagnostics {
            AppStoreScreenshotDiagnosticsView()
        } else {
            destination.view
        }
    }
}
#endif

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
                Link(
                    "Política de privacidade",
                    destination: URL(string: "https://intranet.iwebit.app/privacypolicy.php")!
                )
            }
            ProtectedLogoutSection()
        }
        .navigationTitle("Definições")
    }
}