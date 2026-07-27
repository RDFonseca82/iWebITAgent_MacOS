import SwiftUI
import iWebITCore

struct MacStoreGateView: View {
    @EnvironmentObject private var runtime: MacStoreRuntime

    var body: some View {
        Group {
            switch runtime.phase {
            case .loading:
                ProgressView("A preparar o iWebIT Agent…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .enrollmentRequired:
                MacStoreEnrollmentView()
            case .ready:
                MacStoreRootView()
            case let .failed(message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                    Text("Não foi possível iniciar")
                        .font(.title2)
                    Text(message)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    HStack {
                        Button("Tentar novamente") {
                            Task { await runtime.retry() }
                        }
                        Button("Usar outro ID") {
                            runtime.signOut()
                        }
                    }
                }
                .padding(32)
            }
        }
    }
}

private struct MacStoreEnrollmentView: View {
    @EnvironmentObject private var runtime: MacStoreRuntime
    @State private var idSync = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "desktopcomputer.and.arrow.down")
                .font(.system(size: 52))
                .foregroundColor(.accentColor)
            Text("iWebIT Agent para macOS")
                .font(.largeTitle)
            Text("Edição segura da App Store para sincronização, suporte e notificações.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            TextField("ID de sincronização", text: $idSync)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 360)
            Button("Associar este Mac") {
                Task { await runtime.enroll(idSync: idSync) }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(idSync.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Text("As credenciais do dispositivo ficam protegidas no Porta‑chaves deste Mac.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MacStoreRootView: View {
    var body: some View {
        TabView {
            MacStoreOverviewView()
                .tabItem { Label("Sincronização", systemImage: "arrow.triangle.2.circlepath") }
            MacStoreTicketsView()
                .tabItem { Label("Ocorrências", systemImage: "list.bullet.rectangle") }
            MacStoreSupportView()
                .tabItem { Label("Suporte", systemImage: "lifepreserver") }
            MacStoreSettingsView()
                .tabItem { Label("Definições", systemImage: "gearshape") }
        }
        .padding(12)
    }
}

private struct MacStoreOverviewView: View {
    @EnvironmentObject private var runtime: MacStoreRuntime

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Este Mac")
                    .font(.largeTitle)
                GroupBox(label: Label("Estado", systemImage: "checkmark.shield")) {
                    VStack(alignment: .leading, spacing: 10) {
                        statusRow("Plataforma", value: "macOS")
                        statusRow("Notificações", value: runtime.notificationAuthorization)
                        statusRow(
                            "Última sincronização",
                            value: runtime.lastSuccessfulSyncAt.map(formatDate) ?? "ainda não concluída"
                        )
                        if let message = runtime.syncMessage {
                            Text(message)
                                .foregroundColor(.secondary)
                        }
                        Button(runtime.isSynchronizing ? "A sincronizar…" : "Sincronizar agora") {
                            Task { await runtime.synchronize() }
                        }
                        .disabled(runtime.isSynchronizing)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox(label: Label("Dados sincronizados", systemImage: "externaldrive.connected.to.line.below")) {
                    Text("Identificação atribuída pelo servidor, nome e modelo do Mac, versão do macOS, arquitetura, processadores, memória, nome de rede, versão da app e estado das notificações.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
                GroupBox(label: Label("Limites desta edição", systemImage: "lock.shield")) {
                    Text("A edição da App Store não executa comandos remotos, não recolhe localização, inventário de aplicações ou serviços, e não instala atualizações fora da App Store. Para administração avançada continua disponível o agente completo em .pkg.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
            }
            .padding(22)
        }
    }

    private func statusRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct MacStoreTicketsView: View {
    @EnvironmentObject private var runtime: MacStoreRuntime

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ocorrências")
                    .font(.largeTitle)
                Spacer()
                Button("Atualizar") {
                    Task { await runtime.loadTickets() }
                }
            }
            if runtime.tickets.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Sem ocorrências disponíveis")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(runtime.tickets) { ticket in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(ticket.subject).font(.headline)
                            Spacer()
                            Text(ticket.status.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(ticket.latestMessage)
                            .lineLimit(3)
                        Text(formatDate(ticket.updatedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
            if let message = runtime.supportMessage {
                Text(message).foregroundColor(.secondary)
            }
        }
        .padding(22)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct MacStoreSupportView: View {
    @EnvironmentObject private var runtime: MacStoreRuntime
    @State private var subject = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var resultMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Contactar suporte")
                .font(.largeTitle)
            TextField("Assunto", text: $subject)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("Descrição")
                .font(.headline)
            TextEditor(text: $message)
                .font(.body)
                .frame(minHeight: 180)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
            HStack {
                if let resultMessage {
                    Text(resultMessage).foregroundColor(.secondary)
                }
                Spacer()
                Button(isSending ? "A enviar…" : "Enviar pedido") {
                    send()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(
                    isSending ||
                    subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
            Spacer()
        }
        .padding(22)
    }

    private func send() {
        isSending = true
        resultMessage = nil
        Task {
            do {
                try await runtime.createTicket(name: subject, message: message)
                subject = ""
                message = ""
                resultMessage = "Pedido enviado."
            } catch {
                resultMessage = "Não foi possível enviar o pedido."
            }
            isSending = false
        }
    }
}

private struct MacStoreSettingsView: View {
    @EnvironmentObject private var runtime: MacStoreRuntime

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Definições")
                .font(.largeTitle)
            GroupBox(label: Label("Notificações", systemImage: "bell")) {
                HStack {
                    Text("Estado: \(runtime.notificationAuthorization)")
                    Spacer()
                    Button("Ativar ou atualizar") {
                        Task { await runtime.requestNotificationPermission() }
                    }
                }
                .padding(6)
            }
            GroupBox(label: Label("Atualizações", systemImage: "arrow.down.app")) {
                Text("Esta edição é atualizada automaticamente através da Mac App Store. O canal .pkg permanece reservado ao agente completo.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
            }
            Divider()
            Button("Desassociar este Mac") {
                runtime.signOut()
            }
            Spacer()
        }
        .padding(22)
    }
}
