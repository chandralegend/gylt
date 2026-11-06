import ActivityKit
import WidgetKit
import SwiftUI
import GYLTCore

/// The Lock Screen and island are always dark, so they use the dark-mode lavender.
private let lavender = Color(hex: 0xB9A6F5)

/// The session timer on the Lock Screen and in the Dynamic Island. The countdown is drawn by the system, so it keeps ticking with the app closed.
/// Same voice as the app: the promise's own illustration, a serif line, lavender progress, no red.
struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Theme.ink)
                .activitySystemActionForegroundColor(lavender)
                .widgetURL(url(context.attributes))
        } dynamicIsland: { context in
            let state = context.state
            let art = Art.forPromise(context.attributes.commitmentId)
            return DynamicIsland {
                // Leading and trailing sit beside the camera cutout; the bottom region carries the words. Nothing sits in .center,
                // which would start below the cutout and leave a gap above the heading.
                DynamicIslandExpandedRegion(.leading) {
                    ArtView(art: art)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.leading, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if state.phase != .finished { CountdownText(state: state, size: 30).padding(.trailing, 2) }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Self.meta(state.phase)).font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(Theme.peach)
                        Text(state.phase == .finished ? "Did you do it?" : context.attributes.title)
                            .font(.statement(22)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
                        SessionBar(state: state).padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image("logo-mark").resizable().scaledToFit().frame(width: 22, height: 22)
            } compactTrailing: {
                CountdownText(state: state, size: 13).frame(maxWidth: 52)
            } minimal: {
                Image("logo-mark").resizable().scaledToFit().frame(width: 20, height: 20)
            }
            .widgetURL(url(context.attributes))
            .keylineTint(lavender)
        }
    }

    static func meta(_ phase: SessionActivityAttributes.ContentState.Phase) -> String {
        switch phase {
        case .running: "IN PROGRESS"
        case .paused: "PAUSED"
        case .finished: "TIME'S UP"
        }
    }

    private func url(_ a: SessionActivityAttributes) -> URL? { URL(string: "gylt://open/\(a.occurrenceId.uuidString)") }
}

private struct LockScreenView: View {
    let attributes: SessionActivityAttributes
    let state: SessionActivityAttributes.ContentState

    var body: some View {
        // Everything that has to be read sits in the left column, on the ink. The picture only fills the right.
        VStack(alignment: .leading, spacing: 4) {
            Text(SessionLiveActivity.meta(state.phase)).font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(Theme.peach)
            Text(state.phase == .finished ? "Did you do it?" : attributes.title)
                .font(.statement(22)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
            if state.phase != .finished { CountdownText(state: state, size: 36, alignment: .leading).frame(maxWidth: 150, alignment: .leading) }
            Spacer(minLength: 6)
            SessionBar(state: state)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, y: 1)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .background {
            // The picture lives on the right and fades into the ink, so the words sit on a quiet field and the figure never sits behind them.
            GeometryReader { g in
                ZStack(alignment: .trailing) {
                    Theme.ink
                    ArtView(art: Art.forPromise(attributes.commitmentId))
                        .frame(width: g.size.width * 0.66)
                        .mask(LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: UnitPoint(x: 0.5, y: 0.5)))
                    LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.3)], startPoint: UnitPoint(x: 0.5, y: 0.55), endPoint: .bottom)
                }
            }
        }
    }
}

/// The countdown. Running: system-drawn and live. Paused: frozen at what is left.
private struct CountdownText: View {
    let state: SessionActivityAttributes.ContentState
    let size: CGFloat
    var alignment: TextAlignment = .trailing

    var body: some View {
        Group {
            switch state.phase {
            case .running: Text(timerInterval: Date.now...max(state.endsAt, Date.now.addingTimeInterval(1)), countsDown: true)
            case .paused: Text(Self.clock(state.remaining))
            case .finished: Text("00:00")
            }
        }
        .font(.numeral(size)).monospacedDigit().multilineTextAlignment(alignment).foregroundStyle(.white)
        .minimumScaleFactor(0.7).lineLimit(1)
    }

    static func clock(_ seconds: Double) -> String {
        let n = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", n / 60, n % 60)
    }
}

private struct SessionBar: View {
    let state: SessionActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.phase == .running {
                ProgressView(timerInterval: state.window, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
            } else {
                ProgressView(value: state.fraction)
            }
        }
        .progressViewStyle(.linear).tint(lavender)
    }
}
