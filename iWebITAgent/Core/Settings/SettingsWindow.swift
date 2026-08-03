import SwiftUI
import AppKit

private enum DiagnosticsPage {
    case overview
    case logs
    case activity
}

private struct AgentActivityRecord: Identifiable {
    let id: String
    let name: String
    let status: String
    let timestamp: String

    var statusLabel: String {
        switch status {
        case "running": return "EM EXECUÇÃO"
        case "completed": return "CONCLUÍDO"
        case "failed": return "ERRO"
        default: return "INATIVO"
        }
    }

    var color: Color {
        switch status {
        case "running": return .green
        case "completed": return .blue
        case "failed": return .red
        default: return .gray
        }
    }
}

private final class AgentDiagnosticsMonitor: ObservableObject {
    @Published var availableLogs: [String] = []
    @Published var selectedLog = "log_service.log"
    @Published var logText = "A procurar ficheiros de log…"
    @Published var isPaused = false
    @Published var activities: [AgentActivityRecord] = []
    @Published var currentActivity: AgentActivityRecord?
    @Published var serviceIsActive = false
    @Published var publicIPAddress = "Ainda não consultado"
    @Published var lastUpdated = Date()

    private var timer: Timer?
    private let knownLogs = [
        "log_service.log",
        "log_iwebit.log",
        "log_systray.log",
        "install_health.log",
        "install_log.log",
        "old_log_service.log",
        "old_log_iwebit.log",
        "old_log_systray.log"
    ]
    private let activityDefinitions = [
        ("full_sync", "Sincronização completa"),
        ("min_sync", "Sincronização mínima"),
        ("device_info", "Informação do dispositivo"),
        ("company_info", "Informação da empresa"),
        ("files", "Sincronização de ficheiros"),
        ("startup", "Inicialização")
    ]

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        guard let directory = FilesManager.shared.getApplicationSupportDirectory() else {
            logText = "Não foi possível localizar a pasta de dados do agente."
            serviceIsActive = false
            return
        }

        let existing = knownLogs.filter {
            FileManager.default.fileExists(atPath: directory.appendingPathComponent($0).path)
        }
        availableLogs = existing

        if !existing.contains(selectedLog), let first = existing.first {
            selectedLog = first
        }

        if !isPaused, !selectedLog.isEmpty {
            let selectedURL = directory.appendingPathComponent(selectedLog)
            logText = readTail(of: selectedURL, maximumBytes: 512 * 1024)
        }

        let serviceURL = directory.appendingPathComponent("log_service.log")
        let oldServiceURL = directory.appendingPathComponent("old_log_service.log")
        let serviceLog = readTail(of: oldServiceURL, maximumBytes: 512 * 1024)
            + "\n"
            + readTail(of: serviceURL, maximumBytes: 1024 * 1024)
        updateActivity(from: serviceLog, fileURL: serviceURL)
        lastUpdated = Date()
    }

    func selectLog(_ name: String) {
        selectedLog = name
        refresh()
    }

    func copyVisibleLog() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logText, forType: .string)
    }

    func refreshPublicIPAddress() {
        guard let url = URL(string: "https://api64.ipify.org") else { return }
        publicIPAddress = "A consultar…"
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            let value: String
            if let data = data,
               let response = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !response.isEmpty {
                value = response
            } else {
                value = error == nil ? "Indisponível" : "Erro ao consultar"
            }
            DispatchQueue.main.async {
                self?.publicIPAddress = value
            }
        }.resume()
    }

    private func readTail(of url: URL, maximumBytes: UInt64) -> String {
        guard FileManager.default.fileExists(atPath: url.path),
              let handle = try? FileHandle(forReadingFrom: url) else {
            return "O ficheiro ainda não foi criado."
        }
        defer { handle.closeFile() }

        let size = handle.seekToEndOfFile()
        let start = size > maximumBytes ? size - maximumBytes : 0
        handle.seek(toFileOffset: start)
        let data = handle.readDataToEndOfFile()
        var text = String(decoding: data, as: UTF8.self)

        if start > 0, let firstNewLine = text.firstIndex(of: "\n") {
            text = String(text[text.index(after: firstNewLine)...])
        }
        return text.isEmpty ? "O ficheiro está vazio." : text
    }

    private func updateActivity(from text: String, fileURL: URL) {
        var latest: [String: AgentActivityRecord] = [:]

        for line in text.components(separatedBy: .newlines).reversed() {
            guard let markerRange = line.range(of: "ACTIVITY|") else { continue }
            let marker = String(line[markerRange.lowerBound...])
            let cleanMarker = marker.components(separatedBy: " || ").first ?? marker
            let parts = cleanMarker.components(separatedBy: "|")
            guard parts.count >= 4 else { continue }

            let id = parts[1]
            guard latest[id] == nil else { continue }
            latest[id] = AgentActivityRecord(
                id: id,
                name: parts[3],
                status: parts[2],
                timestamp: String(line.prefix(19))
            )
        }

        activities = activityDefinitions.map { definition in
            latest[definition.0] ?? AgentActivityRecord(
                id: definition.0,
                name: definition.1,
                status: "inactive",
                timestamp: "—"
            )
        }

        currentActivity = activities.first(where: { $0.status == "running" })

        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modifiedAt = attributes[.modificationDate] as? Date {
            serviceIsActive = Date().timeIntervalSince(modifiedAt) < 370
        } else {
            serviceIsActive = false
        }
    }
}

struct SettingsWindow: View {
    @Environment(\.openURL) private var openURL

    @StateObject private var monitor = AgentDiagnosticsMonitor()
    @State private var accessCode = ""
    @State private var isUnlocked = false
    @State private var validationMessage: String?
    @State private var page: DiagnosticsPage = .overview

    var body: some View {
        Group {
            if isUnlocked {
                unlockedContent
            } else {
                accessGate
            }
        }
        .fillMaxSize()
        .background(Color.theme.background)
        .onDisappear {
            accessCode = ""
            isUnlocked = false
            validationMessage = nil
            page = .overview
        }
    }

    private var accessGate: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield")
                .font(.system(size: 46))
                .foregroundColor(.theme.accent)

            Text("Definições protegidas")
                .font(.system(size: 28, weight: .semibold))

            Text("Introduza o IDSYNC deste agente para abrir as definições.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            SecureField("IDSYNC", text: $accessCode, onCommit: unlockSettings)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 280)

            if let validationMessage = validationMessage {
                Text(validationMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 13))
            }

            Button("Abrir definições", action: unlockSettings)
                .disabled(accessCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    @ViewBuilder
    private var unlockedContent: some View {
        switch page {
        case .overview:
            overview
        case .logs:
            logsView
        case .activity:
            activityView
        }
    }

    private var overview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageTitle(
                    title: "Definições",
                    subtitle: "Informações do agente e ferramentas de diagnóstico."
                )

                settingsCard(title: "Informações da Empresa", icon: "building.2") {
                    HStack(spacing: 14) {
                        valueField(title: "Nome da Empresa", value: AppInfo.companyname)
                        valueField(title: "ID da Empresa", value: AppInfo.idcompany, width: 150)
                    }
                }

                settingsCard(title: "Informações Técnicas", icon: "desktopcomputer") {
                    VStack(spacing: 12) {
                        valueField(
                            title: "Versão do Agente",
                            value: "\(Constants.AGENT_VERSION) (\(Constants.AGENT_BUILD))"
                        )
                        valueField(title: "ID da Sincronização", value: AppInfo.idsync)
                        valueField(title: "ID do Dispositivo", value: AppInfo.uniqueid)
                        HStack(spacing: 14) {
                            valueField(
                                title: "Ligação à Internet",
                                value: AppInfo.net == "1" ? "Disponível" : "Indisponível"
                            )
                            valueField(
                                title: "Estado do Serviço",
                                value: monitor.serviceIsActive ? "Ativo" : "Sem atividade recente"
                            )
                            valueField(
                                title: "IP público (Internet)",
                                value: monitor.publicIPAddress
                            )
                        }
                    }
                }

                settingsCard(title: "Ferramentas de Diagnóstico", icon: "gearshape.2") {
                    HStack(spacing: 12) {
                        diagnosticButton(
                            title: "Ver Logs",
                            icon: "doc.text.magnifyingglass"
                        ) {
                            monitor.refresh()
                            page = .logs
                        }

                        diagnosticButton(
                            title: "Monitor de Atividades",
                            icon: "waveform.path.ecg"
                        ) {
                            monitor.refresh()
                            page = .activity
                        }

                        Button {
                            openURL(Constants.privacyPolicyUrl)
                        } label: {
                            Label("Política de Privacidade", systemImage: "hand.raised")
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var logsView: some View {
        VStack(spacing: 0) {
            diagnosticsToolbar(title: "Logs em tempo real")

            HStack(spacing: 12) {
                Picker("Ficheiro", selection: Binding(
                    get: { monitor.selectedLog },
                    set: { monitor.selectLog($0) }
                )) {
                    ForEach(monitor.availableLogs, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .frame(maxWidth: 280)

                Spacer()

                Button(monitor.isPaused ? "Retomar" : "Pausar") {
                    monitor.isPaused.toggle()
                    if !monitor.isPaused { monitor.refresh() }
                }

                Button("Copiar") {
                    monitor.copyVisibleLog()
                }

                Button {
                    monitor.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Atualizar agora")
            }
            .padding(14)
            .background(Color.primary.opacity(0.035))

            ReadOnlyLogTextView(text: monitor.logText, followTail: !monitor.isPaused)
                .background(Color(NSColor.textBackgroundColor))
        }
        .padding(24)
    }

    private var activityView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                diagnosticsToolbar(title: "Monitor de Atividades")

                HStack(spacing: 12) {
                    statusSummary(
                        title: "Serviço principal",
                        value: monitor.serviceIsActive ? "ATIVO" : "SEM ATIVIDADE",
                        color: monitor.serviceIsActive ? .green : .orange
                    )
                    statusSummary(
                        title: "Atividade atual",
                        value: monitor.currentActivity?.name ?? "Em espera",
                        color: monitor.currentActivity == nil ? .blue : .green
                    )
                    statusSummary(
                        title: "Última leitura",
                        value: Self.shortTime.string(from: monitor.lastUpdated),
                        color: .blue
                    )
                }

                sectionLabel("FUNCIONALIDADES")

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 250), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(monitor.activities) { activity in
                        activityCard(activity)
                    }
                }

                sectionLabel("SINCRONIZAÇÃO")

                HStack(spacing: 12) {
                    scheduleCard(title: "Próxima Sync Completa", value: AppInfo.nexttimesync)
                    scheduleCard(title: "Próxima Sync Mínima", value: AppInfo.nexttimealive)
                }
            }
            .padding(24)
        }
    }

    private func pageTitle(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
            Text(subtitle)
                .foregroundColor(.secondary)
        }
    }

    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            content()
        }
        .padding(16)
        .background(Color.primary.opacity(0.045))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func valueField(title: String, value: String, width: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(Color.primary.opacity(0.055))
                .cornerRadius(7)
                .help(value)
        }
        .frame(width: width)
        .frame(maxWidth: width == nil ? .infinity : width)
    }

    private func diagnosticButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
    }

    private func diagnosticsToolbar(title: String) -> some View {
        HStack {
            Button {
                page = .overview
            } label: {
                Label("Voltar", systemImage: "chevron.left")
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
            Text(title)
                .font(.system(size: 22, weight: .semibold))
            Spacer()

            Color.clear.frame(width: 58, height: 1)
        }
        .padding(.bottom, 8)
    }

    private func statusSummary(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.system(size: 12, weight: .semibold))
            }
            Spacer()
        }
        .padding(13)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.045))
        .cornerRadius(9)
    }

    private func activityCard(_ activity: AgentActivityRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(activity.color).frame(width: 8, height: 8)
                Text(activity.name)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(activity.statusLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(activity.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(activity.color.opacity(0.12))
                    .cornerRadius(8)
            }

            HStack {
                Text("Última alteração")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(activity.timestamp)
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .padding(13)
        .background(Color.primary.opacity(0.045))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(activity.color.opacity(0.55), lineWidth: 1)
        )
        .cornerRadius(9)
    }

    private func scheduleCard(title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
        .frame(maxWidth: .infinity)
        .padding(13)
        .background(Color.primary.opacity(0.045))
        .cornerRadius(9)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func unlockSettings() {
        let candidate = accessCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard candidate == AppInfo.idsync else {
            validationMessage = "IDSYNC incorreto."
            log("SETTINGS ACCESS DENIED", important: true)
            return
        }

        validationMessage = nil
        accessCode = ""
        isUnlocked = true
        monitor.refresh()
        monitor.refreshPublicIPAddress()
        log("SETTINGS ACCESS GRANTED", important: true)
    }

    private static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

private struct ReadOnlyLogTextView: NSViewRepresentable {
    let text: String
    let followTail: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            if followTail {
                textView.scrollToEndOfDocument(nil)
            }
        }
    }
}
