import Foundation
import LocalAuthentication

/// Wraps Face ID / Touch ID and Device Passcode unlock checks.
enum BiometricGate {
    static var isAvailable: Bool {
        isBiometricsAvailable
    }

    static var isBiometricsAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static var isDeviceOwnerAuthAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    static var biometricName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "biometrie"
        }
    }

    /// Attempts device owner authentication. When biometrics are preferred and available,
    /// biometrics are evaluated first; otherwise the device passcode is required.
    static func authenticate(
        reason: String = "Ontgrendel je digitale kloon",
        preferBiometrics: Bool = true
    ) async -> Bool {
        let context = LAContext()
        let policy: LAPolicy = (preferBiometrics && isBiometricsAvailable)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            // If device authentication is not configured on the device at all (e.g. headless simulator),
            // allow unlock only if no device passcode/biometrics are set up on the host.
            if !isDeviceOwnerAuthAvailable {
                return true
            }
            return false
        }

        do {
            return try await context.evaluatePolicy(policy, localizedReason: reason)
        } catch {
            return false
        }
    }
}