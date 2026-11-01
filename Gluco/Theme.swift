import SwiftUI

struct GlassModifier: ViewModifier {
    var radius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.06)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
    }
}

extension View {
    func glass(radius: CGFloat = 24) -> some View { modifier(GlassModifier(radius: radius)) }
}

struct GlucoBackground: View {
    var body: some View {
        ZStack {
            GlucoColors.background
            Circle().fill(Color(hex: 0x1D3A5C)).frame(width: 520).blur(radius: 120).offset(x: -140, y: -360)
            Circle().fill(Color(hex: 0x123D33)).frame(width: 460).blur(radius: 120).offset(x: 190, y: 40)
            Circle().fill(Color(hex: 0x2A1D4D)).frame(width: 440).blur(radius: 120).offset(x: -170, y: 420)
        }
        .ignoresSafeArea()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                LinearGradient(colors: [GlucoColors.blue, GlucoColors.blueDark], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: GlucoColors.blueDark.opacity(0.4), radius: 12, y: 6)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct Chip: View {
    let text: String
    var color: Color = .white

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color == .white ? Color.white.opacity(0.8) : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.14)))
            .overlay(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1))
    }
}

struct ScreenTitle: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 30, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}

enum AppTab: CaseIterable {
    case home, entries, stats, profile

    var title: String {
        switch self {
        case .home: return "Цукор"
        case .entries: return "Записи"
        case .stats: return "Статистика"
        case .profile: return "Профіль"
        }
    }

    var icon: String {
        switch self {
        case .home: return "drop.fill"
        case .entries: return "list.bullet"
        case .stats: return "chart.bar.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

struct GlassTabBar: View {
    @Binding var tab: AppTab

    var body: some View {
        HStack {
            ForEach(AppTab.allCases, id: \.self) { t in
                Button {
                    tab = t
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon).font(.system(size: 20))
                        Text(t.title).font(.system(size: 11))
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(tab == t ? Color.white : Color.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 66)
        .glass(radius: 33)
        .padding(.horizontal, 16)
    }
}
