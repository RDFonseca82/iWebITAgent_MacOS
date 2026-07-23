import SwiftUI

struct EnrollmentView: View {
    @EnvironmentObject private var runtime: MobileRuntime
    @State private var idSync = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("IDSync", text: $idSync)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Associar dispositivo")
                } footer: {
                    Text("A associação troca o IDSync por uma credencial revogável guardada no Keychain.")
                }

                Button("Associar") {
                    Task {
                        await runtime.enroll(
                            idSync: idSync.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                }
                .disabled(idSync.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle("iWebIT")
        }
    }
}
