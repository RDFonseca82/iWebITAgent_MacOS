import SwiftUI
import iWebITCore

struct LiveIncidentsView: View {
    @EnvironmentObject private var runtime: MobileRuntime

    var body: some View {
        List(runtime.tickets) { ticket in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(ticket.subject)
                        .font(.headline)
                    Spacer()
                    Text(ticket.status.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(ticket.latestMessage)
                    .lineLimit(2)
                Text(ticket.updatedAt, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if runtime.tickets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 44))
                    Text("Sem ocorrências")
                        .font(.headline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .refreshable {
            await runtime.loadTickets()
        }
        .navigationTitle("Ocorrências")
    }
}

struct LiveSupportRequestView: View {
    @EnvironmentObject private var runtime: MobileRuntime
    @State private var name = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var sent = false

    var body: some View {
        Form {
            TextField("Nome", text: $name)
                .textContentType(.name)
            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text("Mensagem")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $message)
                    .frame(minHeight: 140, maxHeight: 240)
            }

            Button {
                Task { await submit() }
            } label: {
                if isSending {
                    ProgressView()
                } else {
                    Text("Enviar pedido")
                }
            }
            .disabled(isSending || name.isBlank || message.isBlank)

            if sent {
                Label("Pedido enviado", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Suporte")
    }

    private func submit() async {
        isSending = true
        sent = false
        errorMessage = nil
        do {
            try await runtime.createTicket(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                message: message.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            name = ""
            message = ""
            sent = true
        } catch {
            errorMessage = "Não foi possível enviar o pedido."
        }
        isSending = false
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension SupportTicketStatus {
    var label: String {
        switch self {
        case .open: return "Aberto"
        case .waitingForUser: return "A aguardar utilizador"
        case .waitingForSupport: return "A aguardar suporte"
        case .resolved: return "Resolvido"
        case .closed: return "Fechado"
        }
    }
}
