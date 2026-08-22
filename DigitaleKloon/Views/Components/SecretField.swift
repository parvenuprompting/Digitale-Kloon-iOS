import SwiftUI

/// A single vault field row in read-only mode: label + value, with reveal and
/// copy actions for secret fields.
struct FieldDetailRow: View {
    let label: String
    let value: String
    let isSecret: Bool
    var copyClearSeconds: Int = 30
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 12) {
                if isSecret && !revealed {
                    Text("••••••••••••")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                        .textSelection(.disabled)
                } else {
                    Text(displayValue)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.textPrimary)
                        .textSelection(.enabled)
                        .privacySensitive(isSecret)
                }

                Spacer(minLength: 0)

                Button {
                    ClipboardService.copy(value, autoClearAfter: copyClearSeconds)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(Color.accent)
                }
                .buttonStyle(.plain)
                .disabled(value.isEmpty)

                if isSecret {
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            revealed.toggle()
                        }
                    } label: {
                        Image(systemName: revealed ? "eye.slash" : "eye")
                            .foregroundStyle(Color.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kloonCard(cornerRadius: 14)
    }

    private var displayValue: String {
        value.isEmpty ? "—" : value
    }
}

/// Password strength bar shown for secret fields while creating/editing.
struct StrengthBar: View {
    let password: String

    var body: some View {
        let level = PasswordStrength.level(of: password)
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < filledCount(level) ? level.color : Color.backgroundSecondary)
                    .frame(height: 4)
            }
        }
    }

    private func filledCount(_ level: PasswordStrength.Level) -> Int {
        level.rawValue + 1
    }
}