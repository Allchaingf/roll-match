//
//  MainTabView.swift
//  RollMatch
//
//  Custom 5-tab shell: Walls • Rolls • Match • Cuts • Reports.
//  Holds the shared "current wall" selection used by the Rolls/Match/Cuts hubs.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    @State private var tab: Tab = .walls
    @State private var selectedWallID: UUID?

    enum Tab: Int, CaseIterable {
        case walls, rolls, match, cuts, reports
        var title: String {
            switch self {
            case .walls: return "Walls"
            case .rolls: return "Rolls"
            case .match: return "Match"
            case .cuts: return "Cuts"
            case .reports: return "Reports"
            }
        }
        var icon: String {
            switch self {
            case .walls: return "rectangle.split.3x1"
            case .rolls: return "function"
            case .match: return "square.grid.3x3.topleft.filled"
            case .cuts: return "scissors"
            case .reports: return "doc.text"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RMBackground()
            Group {
                switch tab {
                case .walls: WallsHubView(selectedWallID: $selectedWallID, goToTab: { tab = $0 })
                case .rolls: RollsHubView(selectedWallID: $selectedWallID)
                case .match: MatchHubView(selectedWallID: $selectedWallID)
                case .cuts: CutsHubView(selectedWallID: $selectedWallID)
                case .reports: ReportsHubView()
                }
            }
            .padding(.bottom, 4)

            tabBar
        }
        .onAppear(perform: ensureSelection)
        .onChange(of: store.walls.count) { _ in ensureSelection() }
    }

    private func ensureSelection() {
        if selectedWallID == nil || store.wall(by: selectedWallID!) == nil {
            selectedWallID = store.walls.first?.id
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button(action: {
                    settings.haptic(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { tab = t }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: t.icon)
                            .font(.system(size: 19, weight: .bold))
                        Text(t.title)
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundColor(tab == t ? RM.bg : RM.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        Group {
                            if tab == t {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(settings.accentGradient)
                                    .shadow(color: RM.orangeGlow, radius: 8, y: 3)
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(RM.bgSoft)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(RM.divider, lineWidth: 1))
                .shadow(color: RM.shadow, radius: 14, y: -2)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}

// MARK: - Wall selector bar (shared by Rolls/Match/Cuts hubs)

struct WallSelectorBar: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedWallID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACTIVE WALL")
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(RM.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.walls) { w in
                        RMChip(label: w.title,
                               icon: w.status.icon,
                               selected: selectedWallID == w.id) {
                            selectedWallID = w.id
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Empty state used when no wall is selected

struct NoWallState: View {
    var message: String = "Create a wall in the Walls tab to begin."
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(RM.textMuted)
            Text("No wall selected")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(RM.textHead)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(RM.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Hub scaffold (shared chrome for the tab hubs)

struct HubScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    var body: some View {
        NavigationView {
            ZStack {
                RMBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: title, subtitle: subtitle)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        content
                        Spacer().frame(height: 96) // clear the tab bar
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
