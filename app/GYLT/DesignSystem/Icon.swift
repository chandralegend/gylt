import SwiftUI

/// Interface icons are SF Symbols. The raw values are the names older saved promises stored, so they keep resolving.
enum Icon: String, CaseIterable {
    case arrowRight = "arrow-right", bed, calendar, camera, chartBar = "chart-bar", check
    case chevronRight = "chevron-right", clock, close, headphone, heart, home
    case humanRun = "human-run", lock, lockOpen = "lock-open", moon, pause, photo, play, plus
    case reload, shield, sliders, volume3 = "volume-3", volumeX = "volume-x", zap

    var symbol: String {
        switch self {
        case .arrowRight: "arrow.right"
        case .bed: "bed.double.fill"
        case .calendar: "calendar"
        case .camera: "camera"
        case .chartBar: "chart.bar.fill"
        case .check: "checkmark"
        case .chevronRight: "chevron.right"
        case .clock: "clock"
        case .close: "xmark"
        case .headphone: "headphones"
        case .heart: "heart"
        case .home: "house.fill"
        case .humanRun: "figure.walk"
        case .lock: "lock.fill"
        case .lockOpen: "lock.open.fill"
        case .moon: "moon.fill"
        case .pause: "pause.fill"
        case .photo: "photo"
        case .play: "play.fill"
        case .plus: "plus"
        case .reload: "arrow.counterclockwise"
        case .shield: "shield.fill"
        case .sliders: "slider.horizontal.3"
        case .volume3: "speaker.wave.2.fill"
        case .volumeX: "speaker.slash.fill"
        case .zap: "bolt.fill"
        }
    }
}

struct Symbol: View {
    let icon: Icon
    var size: CGFloat = 24
    var body: some View {
        Image(systemName: icon.symbol)
            .font(.system(size: size * 0.74, weight: .semibold))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
