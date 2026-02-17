import SwiftUI

struct Overview: View {
    let route: MatchRoute

    @StateObject private var vm = OverviewViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    TopNavBar(title: vm.title)

                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if let error = vm.errorText {
                        Text(error)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    MatchHeroCard(model: vm.hero)

                    PeriodScoreCard(model: vm.periods)

                    if !vm.stats.rows.isEmpty {
                        TeamStatsCardV2(stats: vm.stats)
                    }

                    SectionHeader(title: "Overview")

                    WeatherCard(model: vm.weather)

                    Spacer(minLength: 18)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
        }
        .task {
            await vm.load(route: route)
        }
        .navigationBarHidden(true)
    }
}


@MainActor
final class OverviewViewModel: ObservableObject {
    struct HeroModel {
        var league: String
        var isLive: Bool
        var homeName: String
        var awayName: String
        var homeImageURL: String?
        var awayImageURL: String?
        var scoreHome: Int
        var scoreAway: Int
        var possessionHome: Int
        var possessionAway: Int
    }

    struct PeriodsModel {
        var homeShort: String
        var awayShort: String
        var cols: [String]
        var home: [String]
        var away: [String]
    }

    struct WeatherModel {
        var city: String
        var temp: String
        var minMax: String
        var status: String
    }

    @Published var title: String = "Premier League"
    @Published var hero = HeroModel(
        league: "Premier League",
        isLive: true,
        homeName: "Manchester United",
        awayName: "Chelsea FC",
        homeImageURL: nil,
        awayImageURL: nil,
        scoreHome: 2,
        scoreAway: 1,
        possessionHome: 80,
        possessionAway: 20
    )

    @Published var periods = PeriodsModel(
        homeShort: "MUN",
        awayShort: "CHE",
        cols: ["1", "2", "3", "4", "T"],
        home: ["1", "1", "", "", "2"],
        away: ["0", "1", "", "", "1"]
    )

    @Published var stats = TeamStats(
        rows: [
            .init(title: "Field Goal", left: 51, right: 40),
            .init(title: "Shots on Target", left: 8, right: 5),
            .init(title: "Total Shots", left: 12, right: 10),
            .init(title: "Corners", left: 6, right: 4),
            .init(title: "Fouls", left: 10, right: 12),
            .init(title: "Offsides", left: 2, right: 1),
            .init(title: "xG", left: 15, right: 12),
        ]
    )

    @Published var weather = WeatherModel(
        city: "Manchester",
        temp: "15°C",
        minMax: "18°C  12°C",
        status: "Cloudy"
    )
    @Published var isLoading = false
    @Published var errorText: String?

    private let service: TheSportsDBServicing

    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func load(route: MatchRoute) async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        let homeBadge = await service.fetchTeamBadge(teamName: route.homeName)
        let awayBadge = await service.fetchTeamBadge(teamName: route.awayName)

        title = route.league
        hero = HeroModel(
            league: route.league,
            isLive: true,
            homeName: route.homeName,
            awayName: route.awayName,
            homeImageURL: homeBadge,
            awayImageURL: awayBadge,
            scoreHome: route.homeScore ?? 0,
            scoreAway: route.awayScore ?? 0,
            possessionHome: 50,
            possessionAway: 50
        )
        periods = PeriodsModel(
            homeShort: String(route.homeName.prefix(3)).uppercased(),
            awayShort: String(route.awayName.prefix(3)).uppercased(),
            cols: ["1", "2", "T"],
            home: ["", "", "\(route.homeScore ?? 0)"],
            away: ["", "", "\(route.awayScore ?? 0)"]
        )
        weather = WeatherModel(
            city: route.league,
            temp: "--",
            minMax: "--",
            status: route.homeName + " vs " + route.awayName
        )

        do {
            let payload = try await service.fetchOverviewPayload(fixtureId: route.fixtureId)
            let event = payload.event

            title = event.strLeague ?? "League"
            hero = HeroModel(
                league: event.strLeague ?? "League",
                isLive: (event.strStatus ?? "").localizedCaseInsensitiveContains("live"),
                homeName: event.strHomeTeam ?? "Home",
                awayName: event.strAwayTeam ?? "Away",
                homeImageURL: await service.fetchTeamBadge(teamName: event.strHomeTeam ?? ""),
                awayImageURL: await service.fetchTeamBadge(teamName: event.strAwayTeam ?? ""),
                scoreHome: event.homeScoreInt ?? 0,
                scoreAway: event.awayScoreInt ?? 0,
                possessionHome: 80,
                possessionAway: 20
            )
            periods = PeriodsModel(
                homeShort: String((event.strHomeTeam ?? "HOM").prefix(3)).uppercased(),
                awayShort: String((event.strAwayTeam ?? "AWY").prefix(3)).uppercased(),
                cols: ["1", "2", "T"],
                home: ["", "", "\(event.homeScoreInt ?? 0)"],
                away: ["", "", "\(event.awayScoreInt ?? 0)"]
            )
            weather = WeatherModel(
                city: event.strVenue ?? (event.strLeague ?? "Venue"),
                temp: "--",
                minMax: event.dateEvent ?? "--",
                status: event.strStatus ?? "Scheduled"
            )

            let mappedRows = payload.stats.map {
                TeamStats.Row(
                    title: $0.strStat,
                    left: numericValue($0.strHome),
                    right: numericValue($0.strAway)
                )
            }
            let visibleRows = mappedRows.filter { $0.left != 0 || $0.right != 0 }

            stats = TeamStats(
                rows: visibleRows,
                leftImageURL: hero.homeImageURL,
                rightImageURL: hero.awayImageURL
            )
            if stats.rows.isEmpty {
                errorText = "No stats for this match yet."
            }
        } catch is CancellationError {
            return
        } catch {
            errorText = "Failed to load match details."
        }
    }


    private func numericValue(_ raw: String?) -> Int {
        guard var raw else { return 0 }
        raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return 0 }
        raw = raw.replacingOccurrences(of: ",", with: ".")
        raw = raw.replacingOccurrences(of: "%", with: "")
        let allowed = Set("0123456789.-")
        let cleaned = String(raw.filter { allowed.contains($0) })
        return Int((Double(cleaned) ?? 0).rounded())
    }
}


private struct TopNavBar: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.custom("Inter-SemiBold", size: 16))
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Image(systemName: "soccerball")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical, 6)
    }
}

private struct MatchHeroCard: View {
    let model: OverviewViewModel.HeroModel

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Pill(text: model.league, icon: nil)
                Spacer()
                Pill(text: model.isLive ? "LIVE" : "FT", icon: "dot.radiowaves.left.and.right")
            }

            HStack(alignment: .center, spacing: 14) {
                VStack(spacing: 8) {
                    TeamLogo(urlString: model.homeImageURL)
                    Text(model.homeName)
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                Text("\(model.scoreHome) : \(model.scoreAway)")
                    .font(.custom("Inter-SemiBold", size: 34))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    TeamLogo(urlString: model.awayImageURL)
                    Text(model.awayName)
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 8) {
                Text("Possession")
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(.white.opacity(0.55))

                HStack {
                    Text("\(model.possessionHome)%")
                        .font(.custom("Inter-SemiBold", size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Text("\(model.possessionAway)%")
                        .font(.custom("Inter-SemiBold", size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                }

                PossessionBar(left: CGFloat(model.possessionHome) / 100.0)
                    .frame(height: 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.85),
                            Color.blue.opacity(0.55),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

private struct TeamLogo: View {
    let urlString: String?

    var body: some View {
        ZStack {
            Circle().fill(.black.opacity(0.25))
            RemoteCircleImage(urlString: urlString, systemName: "photo")
        }
        .frame(width: 44, height: 44)
        .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

private struct Pill: View {
    let text: String
    let icon: String?

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.custom("Inter-SemiBold", size: 12))
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.black.opacity(0.20)))
    }
}

private struct PossessionBar: View {
    let left: CGFloat
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let lw = max(0, min(1, left)) * w
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.18))
                Capsule().fill(.black.opacity(0.35)).frame(width: lw)
            }
        }
    }
}

private struct PeriodScoreCard: View {
    let model: OverviewViewModel.PeriodsModel

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                HStack(spacing: 30) {
                    ForEach(model.cols, id: \.self) { c in
                        Text(c)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.35))
                            .frame(width: 18)
                    }
                }
            }

            periodRow(team: model.homeShort, values: model.home)
            periodRow(team: model.awayShort, values: model.away)
        }
        .padding(14)
        .background(CardBackground())
    }

    private func periodRow(team: String, values: [String]) -> some View {
        HStack {
            Text(team)
                .font(.custom("Inter-SemiBold", size: 12))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 40, alignment: .leading)

            Spacer()

            HStack(spacing: 30) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, v in
                    Text(v.isEmpty ? " " : v)
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 18)
                }
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Inter-SemiBold", size: 16))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .padding(.top, 4)
    }
}

private struct WeatherCard: View {
    let model: OverviewViewModel.WeatherModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                Text(model.city)
                    .font(.custom("Inter-SemiBold", size: 18))
                    .foregroundStyle(.white.opacity(0.9))

                Text(model.temp)
                    .font(.custom("Inter-SemiBold", size: 44))
                    .foregroundStyle(.white)

                HStack {
                    Text(model.minMax)
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Text(model.status)
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(18)
        }
        .frame(height: 140)
    }
}

#Preview("Overview") {
    NavigationStack {
        Overview(
            route: MatchRoute(
                fixtureId: 123456,
                league: "Premier League",
                homeName: "Manchester United",
                awayName: "Chelsea FC",
                homeScore: 2,
                awayScore: 1
            )
        )
    }
}
