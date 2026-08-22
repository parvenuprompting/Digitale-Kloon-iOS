import SwiftUI

struct PasswordGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    @State private var length = 20.0
    @State private var includeLowercase = true
    @State private var includeUppercase = true
    @State private var includeDigits = true
    @State private var includeSymbols = true
    @State private var generated = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Wachtwoord") {
                    HStack {
                        Text(generated.isEmpty ? "Druk op genereer" : generated)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                            .textSelection(.enabled)
                            .privacySensitive()

                        Spacer(minLength: 0)

                        Button {
                            generate()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(Color.accent)
                        }
                    }

                    if !generated.isEmpty {
                        StrengthBar(password: generated)
                        Text(PasswordStrength.level(of: generated).label)
                            .font(.caption)
                            .foregroundStyle(PasswordStrength.level(of: generated).color)
                    }
                }

                Section("Lengte: \(Int(length))") {
                    Slider(value: $length, in: 8...64, step: 1)
                        .tint(Color.accent)
                }

                Section("Tekenset") {
                    Toggle("Kleine letters (a-z)", isOn: $includeLowercase)
                    Toggle("Hoofdletters (A-Z)", isOn: $includeUppercase)
                    Toggle("Cijfers (0-9)", isOn: $includeDigits)
                    Toggle("Symbolen (!@#…)", isOn: $includeSymbols)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .foregroundStyle(Color.textPrimary)
            .navigationTitle("Wachtwoordgenerator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gebruik") {
                        onSelect(generated)
                        dismiss()
                    }
                    .disabled(generated.isEmpty)
                    .foregroundStyle(Color.accent)
                }
            }
            .onAppear { generate() }
        }
    }

    private func generate() {
        let options = PasswordGenerator.Options(
            length: Int(length),
            includeLowercase: includeLowercase,
            includeUppercase: includeUppercase,
            includeDigits: includeDigits,
            includeSymbols: includeSymbols
        )
        generated = PasswordGenerator.generate(options: options)
    }
}