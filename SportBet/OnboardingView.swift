import SwiftUI

private enum OnboardingPage {
    case intro
    case profile
    case notifications
}

private enum OnboardingSport: String, CaseIterable, Identifiable {
    case football
    case basketball
    case hockey

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .football: return "Football"
        case .basketball: return "Basketball"
        case .hockey: return "Hockey"
        }
    }

    var subtitleKey: LocalizedStringKey {
        switch self {
        case .football: return "EPL, La Liga, Champions League"
        case .basketball: return "NBA, EuroLeague, FIBA"
        case .hockey: return "NHL, KHL, IIHF"
        }
    }

    var compactSubtitleKey: LocalizedStringKey {
        switch self {
        case .football: return "Major Leagues"
        case .basketball: return "NBA & Euro"
        case .hockey: return "NHL & KHL"
        }
    }

    var icon: String {
        switch self {
        case .football: return "soccerball"
        case .basketball: return "basketball.fill"
        case .hockey: return "opticaldisc.fill"
        }
    }

    var tint: Color {
        switch self {
        case .football: return Color(hex: 0x249BFF)
        case .basketball: return Color(hex: 0xF4F4F4)
        case .hockey: return Color(hex: 0xD5D7DE)
        }
    }
}

struct OnboardingView: View {
    let onFinish: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("profile.displayName") private var storedDisplayName = ""
    @AppStorage("profile.region") private var storedRegion = ""
    @AppStorage("profile.favoriteSports") private var storedFavoriteSports = ""
    @AppStorage("notifications.liveMatchEvents") private var storedLiveMatchEvents = true
    @AppStorage("notifications.breakingNews") private var storedBreakingNews = true
    @AppStorage("notifications.videoHighlights") private var storedVideoHighlights = false

    @State private var page: OnboardingPage = .intro
    @State private var displayName = ""
    @State private var selectedRegion = ""
    @State private var selectedSports: Set<OnboardingSport> = [.football, .basketball]
    @State private var liveMatchEventsEnabled = true
    @State private var breakingNewsEnabled = true
    @State private var videoHighlightsEnabled = false

    private let regions = [
        "United States",
        "United Kingdom",
        "Spain",
        "Germany",
        "France",
        "Italy",
        "Canada"
    ]

    private var sortedSelectedSports: [OnboardingSport] {
        OnboardingSport.allCases.filter(selectedSports.contains)
    }

    private var regionTitle: String {
        selectedRegion.isEmpty ? "Select your region" : selectedRegion
    }

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        ZStack {
            OnboardingBackground()

            switch page {
            case .intro:
                introPage
            case .profile:
                profilePage
            case .notifications:
                notificationsPage
            }
        }
    }

    private var introPage: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x4B93FF), Color(hex: 0x2D67EE)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 50, height: 50)
                .shadow(color: Color(hex: 0x249BFF).opacity(0.35), radius: 22, y: 12)

                HStack(spacing: 2) {
                    Text("LiveScores")
                        .foregroundStyle(palette.primaryText)
                    Text("Pro")
                        .foregroundStyle(Color(hex: 0x249BFF))
                }
                .font(.custom("Inter-Bold", size: 23))

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)

            Spacer(minLength: 12)

            Image("onb")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 26)
                .padding(.top, 8)

            Spacer(minLength: 12)

            VStack(spacing: 18) {
                Text("Never Miss a\nGame Changing\nMoment")
                    .font(.custom("Inter-Bold", size: 30))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.primaryText)
                    .lineSpacing(2)

                Text("Real-time scores, in-depth stats, and video highlights for Football, Basketball, and Hockey.")
                    .font(.custom("Inter-Regular", size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(7)
                    .padding(.horizontal, 34)
            }

            Spacer(minLength: 28)

            PrimaryOnboardingButton(title: "Get Started", icon: "arrow.right") {
                move(to: .profile)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 26)
        }
    }

    private var profilePage: some View {
        stepLayout(step: 1) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Step 1 of 2")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundStyle(Color(hex: 0x249BFF))

                Text("Personalize your feed")
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundStyle(palette.primaryText)

                Text("Select your favorite sports and set up your profile to get tailored live scores and news.")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(7)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Profile Details")
                    .font(.custom("Inter-Bold", size: 15))
                    .foregroundStyle(palette.primaryText)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Display Name")
                        .font(.custom("Inter-Medium", size: 13))
                        .foregroundStyle(palette.primaryText.opacity(0.88))

                    OnboardingTextField(
                        icon: "person",
                        placeholder: "e.g. Alex Sports",
                        text: $displayName
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Region")
                        .font(.custom("Inter-Medium", size: 13))
                        .foregroundStyle(palette.primaryText.opacity(0.88))

                    Menu {
                        ForEach(regions, id: \.self) { region in
                            Button(region) {
                                selectedRegion = region
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(palette.secondaryText)

                            Text(LocalizedStringKey(regionTitle))
                                .font(.custom("Inter-Regular", size: 15))
                                .foregroundStyle(selectedRegion.isEmpty ? palette.secondaryText.opacity(0.72) : palette.primaryText)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(palette.primaryText.opacity(0.84))
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 50)
                        .background(OnboardingCardBackground(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Favorite Sports")
                        .font(.custom("Inter-Bold", size: 15))
                        .foregroundStyle(palette.primaryText)

                    Spacer()

                    Text("Multi-select")
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundStyle(Color(hex: 0x249BFF))
                }

                VStack(spacing: 14) {
                    ForEach(OnboardingSport.allCases) { sport in
                        SportSelectionRow(
                            sport: sport,
                            isSelected: selectedSports.contains(sport)
                        ) {
                            toggle(sport)
                        }
                    }
                }
            }
        } footer: {
            PrimaryOnboardingButton(title: "Continue", icon: "arrow.right") {
                move(to: .notifications)
            }
        }
    }

    private var notificationsPage: some View {
        stepLayout(step: 2) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Step 2 of 2")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundStyle(Color(hex: 0x249BFF))

                Text("Almost there!")
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundStyle(palette.primaryText)

                Text("Customize your experience. We'll prioritize news and notifications based on your choices.")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(7)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("You're following")
                    .font(.custom("Inter-Bold", size: 15))
                    .foregroundStyle(palette.primaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(sortedSelectedSports) { sport in
                            FollowingSportCard(sport: sport)
                        }

                        EditSportsCard {
                            move(to: .profile)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Notifications")
                    .font(.custom("Inter-Bold", size: 15))
                    .foregroundStyle(palette.primaryText)

                VStack(spacing: 14) {
                    NotificationToggleCard(
                        title: "Live Match Events",
                        subtitle: "Goals, cards, and final whistles",
                        icon: "bolt.fill",
                        tint: Color(hex: 0x45FF1D),
                        isOn: $liveMatchEventsEnabled
                    )

                    NotificationToggleCard(
                        title: "Breaking News",
                        subtitle: "Transfers and major announcements",
                        icon: "newspaper.fill",
                        tint: Color(hex: 0x249BFF),
                        isOn: $breakingNewsEnabled
                    )

                    NotificationToggleCard(
                        title: "Video Highlights",
                        subtitle: "Recaps and best moments",
                        icon: "play.fill",
                        tint: Color(hex: 0x9C54FF),
                        isOn: $videoHighlightsEnabled
                    )
                }
            }
        } footer: {
            PrimaryOnboardingButton(title: "Get Started", icon: "rocket") {
                completeOnboarding()
            }
        }
    }

    private func stepLayout<Content: View, Footer: View>(
        step: Int,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    goBack()
                } label: {
                    ZStack {
                        Circle()
                            .fill(palette.iconBackground)
                            .overlay(Circle().stroke(palette.divider, lineWidth: 1))

                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(palette.primaryText)
                    }
                    .frame(width: 56, height: 56)
                }
                .buttonStyle(.plain)

                Spacer()

                StepProgressView(step: step)

                Spacer()

                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(.plain)
                .font(.custom("Inter-SemiBold", size: 18))
                .foregroundStyle(palette.secondaryText)
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    content()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }

            footer()
                .padding(.horizontal, 28)
                .padding(.bottom, 26)
        }
    }

    private func move(to destination: OnboardingPage) {
        withAnimation(.easeInOut(duration: 0.22)) {
            page = destination
        }
    }

    private func goBack() {
        switch page {
        case .intro:
            return
        case .profile:
            move(to: .intro)
        case .notifications:
            move(to: .profile)
        }
    }

    private func toggle(_ sport: OnboardingSport) {
        if selectedSports.contains(sport) {
            selectedSports.remove(sport)
        } else {
            selectedSports.insert(sport)
        }
    }

    private func completeOnboarding() {
        storedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        storedRegion = selectedRegion
        storedFavoriteSports = sortedSelectedSports.map(\.rawValue).joined(separator: ",")
        storedLiveMatchEvents = liveMatchEventsEnabled
        storedBreakingNews = breakingNewsEnabled
        storedVideoHighlights = videoHighlightsEnabled
        onFinish()
    }
}

private struct StepProgressView: View {
    let step: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...2, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color(hex: 0x249BFF) : Color.white.opacity(0.12))
                    .frame(width: 48, height: 8)
            }
        }
        .shadow(color: Color(hex: 0x249BFF).opacity(step > 0 ? 0.16 : 0), radius: 12)
    }
}

private struct OnboardingTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(palette.secondaryText)

            TextField(
                "",
                text: $text,
                prompt: Text(LocalizedStringKey(placeholder)).foregroundColor(palette.secondaryText.opacity(0.7))
            )
                .font(.custom("Inter-Regular", size: 15))
                .foregroundStyle(palette.primaryText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 18)
        .frame(height: 50)
        .background(OnboardingCardBackground(cornerRadius: 20))
    }
}

private struct SportSelectionRow: View {
    let sport: OnboardingSport
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(palette.iconBackground)

                    Image(systemName: sport.icon)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(palette.primaryText.opacity(0.92))
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(sport.titleKey)
                        .font(.custom("Inter-Bold", size: 15))
                        .foregroundStyle(palette.primaryText)

                    Text(sport.subtitleKey)
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : palette.divider.opacity(1.8), lineWidth: 1.4)
                        .background(
                            Circle()
                                .fill(isSelected ? Color(hex: 0x249BFF) : Color.clear)
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(width: 30, height: 30)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? Color(hex: 0x10355A) : palette.iconBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(isSelected ? Color(hex: 0x249BFF) : palette.divider, lineWidth: 1.2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FollowingSportCard: View {
    let sport: OnboardingSport
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(palette.iconBackground)
                        .overlay(Circle().stroke(palette.divider, lineWidth: 1))

                    Image(systemName: sport.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 72, height: 72)

                Spacer()

                Circle()
                    .fill(palette.iconBackground)
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(palette.secondaryText)
                    }
            }

            Spacer(minLength: 0)

            Text(sport.titleKey)
                .font(.custom("Inter-Bold", size: 15))
                .foregroundStyle(palette.primaryText)

            Text(sport.compactSubtitleKey)
                .font(.custom("Inter-Regular", size: 12))
                .foregroundStyle(palette.secondaryText)
        }
        .padding(18)
        .frame(width: 170, height: 190)
        .background(OnboardingCardBackground(cornerRadius: 24))
    }
}

private struct EditSportsCard: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Spacer(minLength: 0)

                Circle()
                    .fill(palette.iconBackground)
                    .frame(width: 58, height: 58)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(palette.primaryText.opacity(0.8))
                    }

                Text("Edit Sports")
                    .font(.custom("Inter-Regular", size: 13))
                    .foregroundStyle(palette.secondaryText)

                Spacer(minLength: 0)
            }
            .frame(width: 120, height: 190)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                    .foregroundStyle(palette.divider.opacity(2.2))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct NotificationToggleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))

                Image(systemName: icon)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Inter-Bold", size: 15))
                    .foregroundStyle(palette.primaryText)

                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(OnboardingCardBackground(cornerRadius: 22))
    }
}

private struct PrimaryOnboardingButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    private var usesSystemSymbol: Bool {
        icon == "arrow.right"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Spacer()

                Text(title)
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundStyle(Color.white)

                if usesSystemSymbol {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                } else {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 20)
                }

                Spacer()
            }
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x2F91F7), Color(hex: 0x2990F2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color(hex: 0x249BFF).opacity(0.34), radius: 24, y: 14)
        }
        .buttonStyle(.plain)
    }
}

private struct OnboardingBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = appPalette(for: colorScheme)

        return palette.background
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 260, style: .continuous)
                    .fill(Color(hex: 0x123357).opacity(0.18))
                    .frame(width: 280, height: 560)
                    .blur(radius: 70)
                    .offset(x: -120, y: 80)
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color(hex: 0x249BFF).opacity(0.08))
                    .frame(width: 180, height: 180)
                    .blur(radius: 50)
                    .offset(x: 50, y: 40)
            }
    }
}

private struct OnboardingCardBackground: View {
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = appPalette(for: colorScheme)

        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        palette.iconBackground.opacity(1.15),
                        palette.iconBackground.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            )
    }
}

private extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
