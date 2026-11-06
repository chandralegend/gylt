import ManagedSettings
import ManagedSettingsUI
import UIKit

/// What a paused app shows. It names the promise and says when the app opens again. Always dark, always one way out.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration { make() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { make() }

    private func make() -> ShieldConfiguration {
        let lavender = UIColor(red: 0.725, green: 0.651, blue: 0.961, alpha: 1)
        let ink = UIColor(red: 0.086, green: 0.078, blue: 0.114, alpha: 1)
        let cream = UIColor(red: 0.965, green: 0.941, blue: 0.902, alpha: 1)
        let soft = UIColor(red: 0.671, green: 0.647, blue: 0.722, alpha: 1)

        let lease = ShieldLeaseFile.read()
        let promise = lease?.promiseTitle?.lowercased()
        var subtitle = promise.map { "You set this time aside for your \($0). Let’s keep that promise." } ?? "You set this time aside for yourself. Let’s keep that promise."
        if let lease {
            let f = DateFormatter(); f.dateFormat = "h:mm a"
            subtitle += "\n\nOpens again around \(f.string(from: lease.expiresAt)), or as soon as you finish."
        }
        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: ink,
            icon: shieldImage(),
            title: .init(text: "This can wait.", color: cream),
            subtitle: .init(text: subtitle, color: soft),
            primaryButtonLabel: .init(text: promise.map { "Back to my \($0)" } ?? "Back", color: ink),
            primaryButtonBackgroundColor: lavender,
            secondaryButtonLabel: .init(text: "End this pause", color: soft)
        )
    }

    private func shieldImage() -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .semibold)
        return UIImage(systemName: "hourglass", withConfiguration: config)?
            .withTintColor(UIColor(red: 0.725, green: 0.651, blue: 0.961, alpha: 1), renderingMode: .alwaysOriginal)
    }
}
