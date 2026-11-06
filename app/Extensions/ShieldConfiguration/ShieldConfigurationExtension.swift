import ManagedSettings
import ManagedSettingsUI
import UIKit

/// The "The feed can wait." screen, 
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration { make() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { make() }

    private func make() -> ShieldConfiguration {
        let coral = UIColor(red: 0.933, green: 0.294, blue: 0.169, alpha: 1)
        let ink = UIColor(red: 0.055, green: 0.055, blue: 0.063, alpha: 1)
        let soft = UIColor(white: 0.65, alpha: 1)
        var subtitle = "You chose this time for yourself. Let’s keep that promise."
        if let lease = ShieldLeaseFile.read() {
            let f = DateFormatter(); f.dateFormat = "h:mm a"
            subtitle += "\nThis opens around \(f.string(from: lease.expiresAt)), or as soon as you finish."
        }
        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: ink,
            icon: shieldImage(),
            title: .init(text: "The feed can wait.", color: .white),
            subtitle: .init(text: subtitle, color: soft),
            primaryButtonLabel: .init(text: "Back to my walk", color: .white),
            primaryButtonBackgroundColor: coral,
            secondaryButtonLabel: .init(text: "End this session", color: soft)
        )
    }

    /// A plain shield glyph in the accent colour.
    private func shieldImage() -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .semibold)
        return UIImage(systemName: "shield.fill", withConfiguration: config)?.withTintColor(UIColor(red: 0.933, green: 0.294, blue: 0.169, alpha: 1), renderingMode: .alwaysOriginal)
    }
}
