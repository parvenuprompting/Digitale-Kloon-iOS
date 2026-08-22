import SwiftUI

struct LockView: View {
    @EnvironmentObject private var security: SecurityState
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Digitale Kloon")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text("Je kluis is vergrendeld")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }

                if security.useBiometrics && BiometricGate.isAvailable {
                    Button {
                        authenticate()
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "faceid")
                                .font(.system(size: 40))
                            Text("Ontgrendel met \(BiometricGate.biometricName)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accent)
                    .foregroundStyle(Color.backgroundPrimary)
                    .disabled(isAuthenticating)
                    .padding(.top, 16)
                } else {
                    Button {
                        authenticate()
                    } label: {
                        Label("Ontgrendel kluis", systemImage: "key.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accent)
                    .foregroundStyle(Color.backgroundPrimary)
                    .disabled(isAuthenticating)
                }
            }
            .padding(.horizontal, 40)
        }
        .task {
            // Auto-attempt unlock on cold start when biometrics are enabled.
            guard security.useBiometrics, BiometricGate.isAvailable else { return }
            authenticate()
        }
    }

    private func authenticate() {
        guard !isAuthenticating else { return }
        Task {
            isAuthenticating = true
            let success = await BiometricGate.authenticate(preferBiometrics: security.useBiometrics)
            isAuthenticating = false
            if success {
                security.didUnlock()
            }
        }
    }
}