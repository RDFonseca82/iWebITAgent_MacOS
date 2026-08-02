import SwiftUI
import UIKit

struct ProtectedDiagnosticsView: View {
    @EnvironmentObject private var runtime: MobileRuntime
    @State private var idSync = ""
    @State private var report: MobileDiagnosticsReport?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let report {
                DiagnosticsReportView(
                    report: report,
                    isRefreshing: isLoading,
                    refresh: load
                )
            } else {
                Form {
                    Section {
                        SecureField("IDSYNC", text: $idSync)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button(isLoading ? "A validar…" : "Abrir diagnóstico") {
                            load()
                        }
                        .disabled(isLoading || idSync.isDiagnosticCodeBlank)
                    } header: {
                        Text("Acesso protegido")
                    } footer: {
                        Text("Introduza o IDSYNC usado para associar este dispositivo. O código não é guardado em texto nem incluído nos logs.")
                    }

                    if let errorMessage {
                        Section {
                            Text(errorMessage).foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Diagnóstico")
    }

    private func load() {
        isLoading = true
        errorMessage = nil
        Task {
            if let result = await runtime.diagnostics(idSync: idSync) {
                report = result
            } else {
                errorMessage = "IDSYNC inválido ou não foi possível criar o diagnóstico."
            }
            isLoading = false
        }
    }
}

private struct DiagnosticsReportView: View {
    let report: MobileDiagnosticsReport
    let isRefreshing: Bool
    let refresh: () -> Void

    private var sections: [String] {
        report.items.reduce(into: []) { result, item in
            if !result.contains(item.section) {
                result.append(item.section)
            }
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Gerado")
                    Spacer()
                    Text(report.generatedAt, style: .time)
                        .foregroundColor(.secondary)
                }
                Button(isRefreshing ? "A atualizar…" : "Atualizar diagnóstico") {
                    refresh()
                }
                .disabled(isRefreshing)
            }

            ForEach(sections, id: \.self) { section in
                Section(section) {
                    ForEach(report.items.filter { $0.section == section }) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.label).font(.caption).foregroundColor(.secondary)
                            Text(item.value)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Logs") {
                NavigationLink(destination: AgentLogsView(
                    entries: report.logs,
                    formattedLogs: report.formattedLogs
                )) {
                    Text("Consultar logs do agente")
                }
            }
        }
    }
}

private struct AgentLogsView: View {
    let entries: [AgentLogEntry]
    let formattedLogs: String
    @State private var copied = false

    var body: some View {
        List {
            Section {
                Button(copied ? "Logs copiados" : "Copiar logs") {
                    UIPasteboard.general.string = formattedLogs
                    copied = true
                    Task {
                        await AgentLogger.shared.log(
                            category: "diagnostics",
                            action: "logs-copied",
                            message: "Logs copiados pelo utilizador."
                        )
                    }
                }
            }

            if entries.isEmpty {
                Section {
                    Text("Ainda não existem logs.").foregroundColor(.secondary)
                }
            } else {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(entry.level.rawValue.uppercased())
                                .font(.caption.bold())
                                .foregroundColor(color(for: entry.level))
                            Spacer()
                            Text(entry.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(entry.category).\(entry.action)")
                            .font(.subheadline.bold())
                        Text(entry.message)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .navigationTitle("Logs do agente")
    }

    private func color(for level: AgentLogLevel) -> Color {
        switch level {
        case .debug: return .secondary
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

#if DEBUG
struct AppStoreScreenshotDiagnosticsView: View {
    var body: some View {
        DiagnosticsReportView(
            report: Self.report,
            isRefreshing: false,
            refresh: {}
        )
        .navigationTitle("Diagnóstico")
    }

    private static let report: MobileDiagnosticsReport = {
        let now = Date()
        let entries = [
            AgentLogEntry(
                id: UUID(),
                timestamp: now.addingTimeInterval(-20),
                level: .info,
                category: "sync",
                action: "success",
                message: "Snapshot sincronizado com sucesso."
            ),
            AgentLogEntry(
                id: UUID(),
                timestamp: now.addingTimeInterval(-90),
                level: .info,
                category: "notifications",
                action: "token-registered",
                message: "Token APNs sincronizado com o backend."
            )
        ]
        return MobileDiagnosticsReport(
            generatedAt: now,
            items: [
                DiagnosticItem(section: "Agente", label: "Versão", value: "2.0.0 (204)"),
                DiagnosticItem(section: "Agente", label: "Servidor", value: "agent.iwebit.app"),
                DiagnosticItem(section: "Sincronização", label: "Último resultado", value: "sucesso"),
                DiagnosticItem(section: "Sincronização", label: "Token de notificações", value: "registado"),
                DiagnosticItem(section: "Dispositivo", label: "Plataforma", value: UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"),
                DiagnosticItem(section: "Dispositivo", label: "Modelo", value: UIDevice.current.model),
                DiagnosticItem(section: "Rede", label: "Transporte", value: "Wi-Fi"),
                DiagnosticItem(section: "Rede", label: "Ligação disponível", value: "sim"),
                DiagnosticItem(section: "Permissões", label: "Notificações", value: "autorizadas"),
                DiagnosticItem(section: "Logs", label: "Registos disponíveis", value: String(entries.count))
            ],
            logs: entries,
            formattedLogs: "[INFO] sync.success — Snapshot sincronizado com sucesso."
        )
    }()
}
#endif
struct ProtectedLogoutSection: View {
    @EnvironmentObject private var runtime: MobileRuntime
    @State private var idSync = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        Section("Desassociar dispositivo") {
            SecureField("IDSYNC", text: $idSync)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(isWorking ? "A validar…" : "Desassociar e terminar sessão") {
                isWorking = true
                errorMessage = nil
                Task {
                    let signedOut = await runtime.signOut(idSync: idSync)
                    if !signedOut {
                        errorMessage = "IDSYNC inválido. O dispositivo não foi desassociado."
                    }
                    isWorking = false
                }
            }
            .foregroundColor(.red)
            .disabled(isWorking || idSync.isDiagnosticCodeBlank)

            if let errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
            Text("O logout apaga as credenciais, a confiança do servidor e o verificador IDSYNC deste dispositivo.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private extension String {
    var isDiagnosticCodeBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
