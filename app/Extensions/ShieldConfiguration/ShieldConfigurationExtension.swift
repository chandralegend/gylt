import ManagedSettings
import ManagedSettingsUI
import UIKit

/// The "The feed can wait." screen, in GYLT's pixel style.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration { make() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { make() }

    private func make() -> ShieldConfiguration {
        let coral = UIColor(red: 1.0, green: 0.396, blue: 0.282, alpha: 1)
        let ink = UIColor(red: 0.078, green: 0.078, blue: 0.071, alpha: 1)
        let soft = UIColor(white: 0.65, alpha: 1)
        var subtitle = "You chose this time for yourself. Let’s keep that promise."
        if let lease = ShieldLeaseFile.read() {
            let f = DateFormatter(); f.dateFormat = "h:mm a"
            subtitle += "\nThis opens around \(f.string(from: lease.expiresAt)), or as soon as you finish."
        }
        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: ink,
            icon: coachImage(),
            title: .init(text: "The feed can wait.", color: .white),
            subtitle: .init(text: subtitle, color: soft),
            primaryButtonLabel: .init(text: "Back to my walk", color: ink),
            primaryButtonBackgroundColor: coral,
            secondaryButtonLabel: .init(text: "End this session", color: soft)
        )
    }

    /// The pixel coach, drawn at a whole-number scale so every pixel stays square.
    private func coachImage() -> UIImage {
        let data = PixelData.coach
        let scale: CGFloat = 5
        let size = CGSize(width: CGFloat(data.width) * scale, height: CGFloat(data.height) * scale)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            for (y, row) in data.rows.enumerated() {
                for (x, ch) in row.enumerated() {
                    guard let hex = data.palette[ch] else { continue }
                    UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1).setFill()
                    ctx.fill(CGRect(x: CGFloat(x) * scale, y: CGFloat(y) * scale, width: scale, height: scale))
                }
            }
        }
    }
}
