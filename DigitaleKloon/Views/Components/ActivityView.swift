import SwiftUI
import UIKit

/// UIKit share sheet wrapper so we can present a generated file (the encrypted
/// backup) from SwiftUI.
struct ActivityView: UIViewControllerRepresentable {
    let urls: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: urls, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}