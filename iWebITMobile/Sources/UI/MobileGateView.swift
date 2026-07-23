import SwiftUI

struct MobileGateView: View {
    @EnvironmentObject private var runtime: MobileRuntime

    var body: some View {
        switch runtime.phase {
        case .loading:
            ProgressView("A preparar ligação segura…")
        case .enrollmentRequired:
            EnrollmentView()
        case .ready:
            MobileRootView()
        case .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)
                Text("Não foi possível ligar")
                    .font(.title2.bold())
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Voltar à associação") {
                    runtime.signOut()
                }
            }
            .padding()
        }
    }
}
