import SwiftUI
import GYLTCore

@main
struct GYLTApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model: AppModel

    init() {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        // The App Group container is shared with the Screen Time extensions; fall back to the app's own folder if it is unavailable.
        let shared = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)
        let store = FileStateStore(url: (shared ?? base).appendingPathComponent("GYLT/state.json"))
        _model = State(initialValue: AppModel(store: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView().environment(model)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var m = model
        TabView(selection: $m.selectedTab) {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "house.fill") }.tag(AppModel.Tab.today)
            NavigationStack { PlanView() }
                .tabItem { Label("Promises", systemImage: "checklist") }.tag(AppModel.Tab.plan)
            NavigationStack { CoachView() }
                .tabItem { Label("Coach", systemImage: "bubble.left.fill") }.tag(AppModel.Tab.coach)
            NavigationStack { YouView() }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }.tag(AppModel.Tab.you)
        }
        .tint(Theme.accent)
        .overlay(alignment: .top) { ToastView() }
        .overlay {
            if !model.settings.onboardingCompleted { OnboardingView().transition(.opacity) }
        }
        .animation(Motion.easeOut, value: model.settings.onboardingCompleted)
        .sheet(item: $m.sheet) { sheet in SheetHost(sheet: sheet) }
        .fullScreenCover(item: $m.flow) { flow in FlowView(flow: flow) }
        .task {
            while !Task.isCancelled {
                model.heartbeat()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { model.send(.materialize); model.reconcileScreenTime(); Task { await model.refreshNotificationStatus(); await model.syncNotifications() } } }
        .onChange(of: colorScheme, initial: true) { _, scheme in model.systemScheme = scheme }
    }
}

struct ToastView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        ZStack {
            if let text = model.toast {
                Text(text).font(.text(.subheadline, weight: .medium)).foregroundStyle(Theme.paper)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Capsule().fill(Theme.ink))
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
                    .padding(.horizontal, 20).padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityAddTraits(.isStaticText)
                    .onAppear { UIAccessibility.post(notification: .announcement, argument: text) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .animation(Motion.spring, value: model.toast)
    }
}
