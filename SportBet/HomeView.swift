import SwiftUI

struct MatchRoute: Hashable {
    let fixtureId: Int
    let league: String
    let homeName: String
    let awayName: String
    let homeScore: Int?
    let awayScore: Int?
}

struct NewsRoute: Hashable {
    let title: String
    let subtitle: String
    let author: String
    let time: String
    let imageURL: String?
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var featured = FeaturedScore(
        fixtureId: 1001,
        league: "League",
        left: TeamMini(name: "Team Name"),
        right: TeamMini(name: "Team Name"),
        leftScore: 0,
        rightScore: 0,
        status: "Final"
    )
    @Published var todays: [MatchRow] = []
    @Published var recent: [MatchRow] = []
    @Published var stats = TeamStats(rows: [])
    @Published var news: [NewsItem] = []
    @Published var isLoading = false
    @Published var errorText: String?

    private let service: TheSportsDBServicing
    private var loadedLeagues = Set<League>()

    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func load() async {
        await ensureLoaded(for: .football)
    }

    func ensureLoaded(for league: League) async {
        guard !loadedLeagues.contains(league) else { return }
        await load(for: league, force: true)
    }

    func load(for league: League, force: Bool = false) async {
        if !force, loadedLeagues.contains(league) { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }
        do {
            let payload = try await service.fetchHomePayload(sport: league.apiSport)
            let allEvents = [payload.featured] + payload.todaysMatches + payload.recentMatches
            let badges = await badgeMap(for: allEvents, sport: league.apiSport)

            featured = makeFeatured(from: payload.featured, badges: badges)
            todays = payload.todaysMatches.map { makeMatch(from: $0, badges: badges) }
            recent = payload.recentMatches.map { makeMatch(from: $0, badges: badges) }
            let statRows = payload.stats.map(makeStatRow).filter { $0.left != 0 || $0.right != 0 }
            stats = TeamStats(
                rows: statRows,
                leftImageURL: badges[payload.featured.strHomeTeam ?? ""],
                rightImageURL: badges[payload.featured.strAwayTeam ?? ""]
            )
            news = payload.news.map(makeNews)
            if todays.isEmpty && recent.isEmpty {
                errorText = "No matches for selected sport right now."
            }
            loadedLeagues.insert(league)
        } catch is CancellationError {
            return
        } catch {
            errorText = "Failed to load data. Pull to retry."
        }
    }

    private func makeFeatured(from event: TheSportsDBEvent, badges: [String: String]) -> FeaturedScore {
        FeaturedScore(
            fixtureId: Int(event.idEvent) ?? 0,
            league: event.strLeague ?? "League",
            left: TeamMini(name: event.strHomeTeam ?? "Home", imageURL: badges[event.strHomeTeam ?? ""]),
            right: TeamMini(name: event.strAwayTeam ?? "Away", imageURL: badges[event.strAwayTeam ?? ""]),
            leftScore: event.homeScoreInt ?? 0,
            rightScore: event.awayScoreInt ?? 0,
            status: event.strStatus ?? "Final"
        )
    }

    private func makeMatch(from event: TheSportsDBEvent, badges: [String: String]) -> MatchRow {
        MatchRow(
            fixtureId: Int(event.idEvent) ?? 0,
            left: TeamMini(name: event.strHomeTeam ?? "Home", imageURL: badges[event.strHomeTeam ?? ""]),
            right: TeamMini(name: event.strAwayTeam ?? "Away", imageURL: badges[event.strAwayTeam ?? ""]),
            scoreLeft: event.homeScoreInt,
            scoreRight: event.awayScoreInt,
            league: event.strLeague ?? "League",
            showScore: event.homeScoreInt != nil && event.awayScoreInt != nil
        )
    }

    private func makeStatRow(from stat: TheSportsDBEventStat) -> TeamStats.Row {
        TeamStats.Row(
            title: stat.strStat,
            left: numericValue(stat.strHome),
            right: numericValue(stat.strAway)
        )
    }

    private func makeNews(from event: TheSportsDBEvent) -> NewsItem {
        NewsItem(
            author: event.strLeague ?? "TheSportsDB",
            time: event.dateEvent ?? "Today",
            title: event.strEvent?.replacingOccurrences(of: "_", with: " ") ?? "Sports News",
            subtitle: "\(event.strHomeTeam ?? "Team A") vs \(event.strAwayTeam ?? "Team B")",
            imageURL: event.strThumb,
            likes: Int(event.idEvent.suffix(2)) ?? 10,
            bookmarked: true
        )
    }

    private func badgeMap(for events: [TheSportsDBEvent], sport: String) async -> [String: String] {
        let names = Set(events.flatMap { [($0.strHomeTeam ?? ""), ($0.strAwayTeam ?? "")] }).filter { !$0.isEmpty }
        var map: [String: String] = [:]

        let leagues = Array(Set(events.compactMap(\.strLeague))).prefix(3)
        for leagueName in leagues {
            let bulk = await service.fetchTeamBadges(leagueName: leagueName, sport: sport)
            map.merge(bulk) { current, _ in current }
        }

        let missing = names.filter { map[$0] == nil }.prefix(8)
        for name in missing {
            if let badge = await service.fetchTeamBadge(teamName: name) {
                map[name] = badge
            }
        }
        return map
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


struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedLeague: League = .football

    private var filteredTodays: [MatchRow] {
        filter(matches: vm.todays)
    }

    private var filteredRecent: [MatchRow] {
        filter(matches: vm.recent)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 14) {
                    Text("Sports Hub")
                        .font(.custom("Inter-SemiBold", size: 17))
                        .foregroundStyle(.white)

                    SearchBar(text: $searchText, placeholder: "Search Matches")

                    LeagueChips(selected: $selectedLeague)

                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 4)
                    } else if let error = vm.errorText {
                        Text(error)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            NavigationLink(value: route(from: vm.featured)) {
                                FeaturedScoreCard(model: vm.featured)
                            }
                            .buttonStyle(.plain)

                            SectionTitle("Today's Matches")
                            VStack(spacing: 10) {
                                ForEach(filteredTodays) { match in
                                    NavigationLink(value: route(from: match)) {
                                        MatchCard(match: match)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            SectionTitle("Recent Results")
                            VStack(spacing: 10) {
                                ForEach(filteredRecent) { match in
                                    NavigationLink(value: route(from: match)) {
                                        MatchCard(match: match)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if !vm.stats.rows.isEmpty {
                                TeamStatsCardV2(stats: vm.stats)
                            }

                            NewsCarousel(items: vm.news)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 64)
                    }
                    .refreshable {
                        await vm.load(for: selectedLeague, force: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top)
                .padding(.horizontal, 16)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: MatchRoute.self) { route in
                Overview(route: route)
            }
            .navigationDestination(for: NewsRoute.self) { route in
                NewsStoryDetailView(route: route)
            }
            .task(id: selectedLeague) {
                await vm.ensureLoaded(for: selectedLeague)
            }
        }
    }

    private func route(from match: MatchRow) -> MatchRoute {
        MatchRoute(
            fixtureId: match.fixtureId,
            league: match.league,
            homeName: match.left.name,
            awayName: match.right.name,
            homeScore: match.scoreLeft,
            awayScore: match.scoreRight
        )
    }

    private func route(from featured: FeaturedScore) -> MatchRoute {
        MatchRoute(
            fixtureId: featured.fixtureId,
            league: featured.league,
            homeName: featured.left.name,
            awayName: featured.right.name,
            homeScore: featured.leftScore,
            awayScore: featured.rightScore
        )
    }

    private func filter(matches: [MatchRow]) -> [MatchRow] {
        guard !searchText.isEmpty else { return matches }
        return matches.filter {
            $0.left.name.localizedCaseInsensitiveContains(searchText)
            || $0.right.name.localizedCaseInsensitiveContains(searchText)
            || $0.league.localizedCaseInsensitiveContains(searchText)
        }
    }
}


enum League: String, CaseIterable, Identifiable {
    case football = "Football"
    case basketball = "Basketball"
    case americanFootball = "American Football"
    case iceHockey = "Ice Hockey"
    case baseball = "Baseball"
    case motorsport = "Motorsport"
    case tennis = "Tennis"
    case golf = "Golf"
    case rugby = "Rugby"
    case cricket = "Cricket"
    case fighting = "Fighting"
    var id: String { rawValue }

    var apiSport: String {
        switch self {
        case .football: return "Soccer"
        case .basketball: return "Basketball"
        case .americanFootball: return "American Football"
        case .iceHockey: return "Ice Hockey"
        case .baseball: return "Baseball"
        case .motorsport: return "Motorsport"
        case .tennis: return "Tennis"
        case .golf: return "Golf"
        case .rugby: return "Rugby"
        case .cricket: return "Cricket"
        case .fighting: return "Fighting"
        }
    }
}

struct TeamMini {
    var name: String
    var imageURL: String? = nil
}

struct FeaturedScore {
    var fixtureId: Int
    var league: String
    var left: TeamMini
    var right: TeamMini
    var leftScore: Int
    var rightScore: Int
    var status: String
}

struct MatchRow: Identifiable {
    let id = UUID()
    let fixtureId: Int
    var left: TeamMini
    var right: TeamMini
    var scoreLeft: Int?
    var scoreRight: Int?
    var league: String
    var showScore: Bool
}

struct TeamStats {
    struct Row: Identifiable {
        let id = UUID()
        var title: String
        var left: Int
        var right: Int
    }
    var rows: [Row]
    var leftImageURL: String? = nil
    var rightImageURL: String? = nil
}

struct NewsItem: Identifiable {
    let id = UUID()
    var author: String
    var time: String
    var sport: String = "Soccer"
    var title: String
    var subtitle: String
    var imageURL: String? = nil
    var likes: Int
    var bookmarked: Bool
}


struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack {
            Text(text)
                .font(.custom("Inter-SemiBold", size: 16))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.top, 2)
    }
}

struct FeaturedScoreCard: View {
    let model: FeaturedScore

    var body: some View {
        HStack(spacing: 14) {
            TeamBadge(title: model.left.name, imageURL: model.left.imageURL)

            Spacer()

            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(model.leftScore)")
                        .font(.custom("Inter-SemiBold", size: 28))
                        .foregroundStyle(.white)
                    Text(":")
                        .font(.custom("Inter-SemiBold", size: 20))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(model.rightScore)")
                        .font(.custom("Inter-SemiBold", size: 28))
                        .foregroundStyle(.white)
                }
                Text(model.status)
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            TeamBadge(title: model.right.name, imageURL: model.right.imageURL)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(CardBackground())
    }
}

struct TeamBadge: View {
    let title: String
    let imageURL: String?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))

                RemoteCircleImage(urlString: imageURL, systemName: "photo")
            }
            .frame(width: 44, height: 44)

            Text(title)
                .font(.custom("Inter-SemiBold", size: 12))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .frame(width: 72)
        }
    }
}

struct MatchCard: View {
    let match: MatchRow

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 10) {
                CircleIcon(urlString: match.left.imageURL)
                Text(match.left.name)
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .frame(width: 84)

            Spacer()

            VStack(spacing: 4) {
                if match.showScore, let l = match.scoreLeft, let r = match.scoreRight {
                    HStack(spacing: 6) {
                        Text("\(l)")
                            .font(.custom("Inter-SemiBold", size: 18))
                            .foregroundStyle(.white)
                        Text(":")
                            .font(.custom("Inter-SemiBold", size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(r)")
                            .font(.custom("Inter-SemiBold", size: 18))
                            .foregroundStyle(.white)
                    }
                } else {
                    Text("—  :  —")
                        .font(.custom("Inter-SemiBold", size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text(match.league)
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .frame(width: 104)

            Spacer()

            VStack(spacing: 10) {
                CircleIcon(urlString: match.right.imageURL)
                Text(match.right.name)
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .frame(width: 84)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(CardBackground())
    }
}

struct CircleIcon: View {
    let urlString: String?

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.06))
            RemoteCircleImage(urlString: urlString, systemName: "photo")
        }
        .frame(width: 34, height: 34)
    }
}


struct TeamStatsCardV2: View {
    let stats: TeamStats

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                TeamCornerIcon(urlString: stats.leftImageURL)
                Spacer()
                Text("Team Stats")
                    .font(.custom("Inter-SemiBold", size: 18))
                    .foregroundStyle(.white)
                Spacer()
                TeamCornerIcon(urlString: stats.rightImageURL)
            }

            VStack(spacing: 16) {
                ForEach(stats.rows) { row in
                    StatRowV2(title: row.title, left: row.left, right: row.right)
                }
            }
        }
        .padding(18)
        .background(StatsCardBackground())
    }
}

struct StatRowV2: View {
    let title: String
    let left: Int
    let right: Int

    private let barHeight: CGFloat = 8
    private let titleWidth: CGFloat = 110

    private func progress(value: Int, other: Int) -> CGFloat {
        let m = max(value, other, 1)
        return CGFloat(value) / CGFloat(m)
    }
    private let barWidth: CGFloat = 70

    var body: some View {
        let leftProgress = progress(value: left, other: right)
        let rightProgress = progress(value: right, other: left)

        return HStack(spacing: 10) {
            Text("\(left)")
                .font(.custom("Inter-SemiBold", size: 14))
                .foregroundStyle(.white)
                .frame(width: 30, alignment: .leading)

            StatBar(
                progress: leftProgress,
                height: 8,
                fillFromRight: true,
                width: barWidth
            )

            Text(title)
                .font(.custom("Inter-SemiBold", size: 12))
                .foregroundStyle(.white.opacity(0.45))
                .frame(width: titleWidth, alignment: .center)
                .lineLimit(2)

            StatBar(
                progress: rightProgress,
                height: 8,
                fillFromRight: false,
                width: barWidth
            )

            Text("\(right)")
                .font(.custom("Inter-SemiBold", size: 14))
                .foregroundStyle(.white)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct StatBar: View {
    let progress: CGFloat   // 0...1
    let height: CGFloat
    let fillFromRight: Bool
    let width: CGFloat      // <-- фиксированная ширина

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .frame(width: width, height: height)

            HStack(spacing: 0) {
                if fillFromRight {
                    Spacer(minLength: 0)
                }

                Capsule()
                    .fill(Color.blue)
                    .frame(width: width * max(0, min(1, progress)),
                           height: height)

                if !fillFromRight {
                    Spacer(minLength: 0)
                }
            }
            .frame(width: width, height: height)
        }
        .frame(width: width, height: height)
    }
}

struct TeamCornerIcon: View {
    let urlString: String?

    init(urlString: String? = nil) {
        self.urlString = urlString
    }

    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.35))
            RemoteCircleImage(urlString: urlString, systemName: "photo")
        }
        .frame(width: 32, height: 32)
        .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct StatsCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.05), Color.white.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}


struct NewsCarousel: View {
    let items: [NewsItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(items) { item in
                    NavigationLink(
                        value: NewsRoute(
                            title: item.title,
                            subtitle: item.subtitle,
                            author: item.author,
                            time: item.time,
                            imageURL: item.imageURL
                        )
                    ) {
                        NewsCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct NewsCard: View {
    let item: NewsItem

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                RemoteRectImage(urlString: item.imageURL, systemName: "photo")
            }
            .frame(height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(item.author)  •  \(item.time)")
                        .font(.custom("Inter-SemiBold", size: 11))
                        .foregroundStyle(.white.opacity(0.60))
                        .lineLimit(1)
                }

                Text(item.title)
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)

                HStack {
                    Label("\(item.likes)", systemImage: "hand.thumbsup.fill")
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(width: 230, height: 220)
        .background(CardBackground())
    }
}

struct NewsStoryDetailView: View {
    let route: NewsRoute
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("Sports News")
                            .font(.custom("Inter-SemiBold", size: 16))
                            .foregroundStyle(.white)
                        Spacer()
                        Color.clear.frame(width: 18, height: 18)
                    }
                    .padding(.top, 6)

                    RemoteRectImage(urlString: route.imageURL, systemName: "photo")
                        .frame(height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("\(route.author)  •  \(route.time)")
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(.white.opacity(0.65))

                    Text(route.title)
                        .font(.custom("Inter-SemiBold", size: 30))
                        .foregroundStyle(.white)

                    Text(route.subtitle)
                        .font(.custom("Inter-SemiBold", size: 15))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }
}


struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

struct RemoteCircleImage: View {
    let urlString: String?
    let systemName: String

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: systemName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .clipShape(Circle())
        } else {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct RemoteRectImage: View {
    let urlString: String?
    let systemName: String

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: systemName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        } else {
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

struct LeagueChips: View {
    @Binding var selected: League

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(League.allCases) { league in
                    Chip(title: league.rawValue, isSelected: selected == league) {
                        selected = league
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct Chip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Inter-SemiBold", size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(isSelected ? Color.blue : Color.white.opacity(0.06)))
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(.white)
                .tint(.white)

            Button { text = "" } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .opacity(text.isEmpty ? 0.6 : 1.0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

#Preview("Home") {
    HomeView()
}
