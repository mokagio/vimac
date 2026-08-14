import SwiftUI

@MainActor
@Observable
final class SettingsNavigation {
    var pane: SettingsPane = .general
}

struct SettingsView: View {
    @Bindable var model: SettingsModel
    @Bindable var navigation: SettingsNavigation

    var body: some View {
        NavigationSplitView {
            List(selection: $navigation.pane) {
                ForEach(SettingsPane.allCases) { pane in
                    SettingsPaneLabel(pane: pane)
                        .tag(pane)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(190)
            // Six fixed panes have no reason to be collapsed out of the way.
            .toolbar(removing: .sidebarToggle)
        } detail: {
            detail
                .frame(minWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detail: some View {
        switch navigation.pane {
        case .general: GeneralSettingsView(model: model)
        case .bindings: BindingsSettingsView(model: model)
        case .hintMode: HintModeSettingsView(model: model)
        case .scrollMode: ScrollModeSettingsView(model: model)
        case .experimental: ExperimentalSettingsView(model: model)
        case .about: AboutSettingsView()
        }
    }
}
