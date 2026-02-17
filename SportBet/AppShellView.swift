import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case matches = "Matches"
    case news = "News"
    case teams = "Teams"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .matches: return "heart"
        case .news: return "newspaper"
        case .teams: return "person.2"
        }
    }
}

struct AppShellView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home: HomeView()
                case .matches: MatchesView()
                case .news: NewsView()
                case .teams: TeamsView()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AppBottomBar(selectedTab: $selectedTab)
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
        }
    }
}

private struct AppBottomBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .medium))
                        Text(tab.rawValue)
                            .font(.custom("Inter-SemiBold", size: 10))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.blue : Color.white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}


@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var featured = FeaturedScore(
        fixtureId: 0,
        league: "League",
        left: TeamMini(name: "Home"),
        right: TeamMini(name: "Away"),
        leftScore: 0,
        rightScore: 0,
        status: "Not Started"
    )
    @Published var finals: [MatchRow] = []
    @Published var upcoming: [MatchRow] = []
    @Published var stats = TeamStats(rows: [])
    @Published var standings: [StandingRow] = []
    @Published var isLoading = false
    @Published var errorText: String?

    private let service: TheSportsDBServicing
    private var loadedLeagues = Set<League>()
    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
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
            let payload = try await service.fetchMatchesPayload(sport: league.apiSport)
            let allEvents = [payload.featured] + payload.finals + payload.upcoming
            let badges = await badgeMap(for: allEvents, sport: league.apiSport)
            let leagueBadges = await service.fetchTeamBadges(
                leagueName: payload.featured.strLeague ?? "",
                sport: league.apiSport
            )

            featured = FeaturedScore(
                fixtureId: Int(payload.featured.idEvent) ?? 0,
                league: payload.featured.strLeague ?? "League",
                left: TeamMini(name: payload.featured.strHomeTeam ?? "Home", imageURL: badges[payload.featured.strHomeTeam ?? ""]),
                right: TeamMini(name: payload.featured.strAwayTeam ?? "Away", imageURL: badges[payload.featured.strAwayTeam ?? ""]),
                leftScore: payload.featured.homeScoreInt ?? 0,
                rightScore: payload.featured.awayScoreInt ?? 0,
                status: payload.featured.strStatus ?? "Final"
            )

            finals = payload.finals.map { event in
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

            upcoming = payload.upcoming.map { event in
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

            stats = TeamStats(
                rows: payload.stats.map {
                    TeamStats.Row(
                        title: $0.strStat,
                        left: numericValue($0.strHome),
                        right: numericValue($0.strAway)
                    )
                }.filter { $0.left != 0 || $0.right != 0 },
                leftImageURL: featured.left.imageURL,
                rightImageURL: featured.right.imageURL
            )

            var standingRows: [StandingRow] = []
            standings = payload.standings.enumerated().map { index, row in
                let teamName = row.strTeam ?? "Team"
                let rowValue = StandingRow(
                    rank: Int(row.intRank ?? "") ?? (index + 1),
                    team: teamName,
                    record: "\(row.intWin ?? "0") : \(row.intLoss ?? "0")",
                    pct: row.intPoints ?? "-",
                    gb: row.intGoalDifference ?? "-",
                    imageURL: leagueBadges[teamName]
                )
                standingRows.append(rowValue)
                return rowValue
            }
            standings = standingRows
            if finals.isEmpty && upcoming.isEmpty {
                errorText = "No matches for selected sport right now."
            }
            loadedLeagues.insert(league)
        } catch is CancellationError {
            return
        } catch {
            errorText = "Failed to load matches."
        }
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

struct MatchesView: View {
    @StateObject private var vm = MatchesViewModel()
    @State private var selectedLeague: League = .football

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Text("Matches")
                            .font(.custom("Inter-SemiBold", size: 17))
                            .foregroundStyle(.white)
                            .padding(.top, 14)

                        if !vm.stats.rows.isEmpty {
                            TeamStatsCardV2(stats: vm.stats)
                        }

                    LeagueChips(selected: $selectedLeague)

                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if let error = vm.errorText {
                        Text(error)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    NavigationLink(value: route(from: vm.featured)) {
                            FeaturedScoreCard(model: vm.featured)
                        }
                        .buttonStyle(.plain)

                        SectionTitle("Final")
                        VStack(spacing: 10) {
                            ForEach(vm.finals) { item in
                                NavigationLink(value: route(from: item)) {
                                    MatchCard(match: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        SectionTitle("Later today")
                        VStack(spacing: 10) {
                            ForEach(vm.upcoming) { item in
                                NavigationLink(value: route(from: item)) {
                                    MatchCard(match: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("Standings")
                            .font(.custom("Inter-SemiBold", size: 18))
                            .foregroundStyle(.white)
                            .padding(.top, 6)

                        StandingsTable(rows: vm.standings)
                            .padding(.bottom, 90)
                    }
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    await vm.load(for: selectedLeague, force: true)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: MatchRoute.self) { route in
                Overview(route: route)
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
}


@MainActor
final class NewsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var newsBySport: [String: [NewsItem]] = [:]
    @Published var isLoading = false
    @Published var errorText: String?

    private let service: TheSportsDBServicing
    private var loadedSports = Set<String>()

    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func filteredNews(for sport: String) -> [NewsItem] {
        let items = newsBySport[sport] ?? []
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.subtitle.localizedCaseInsensitiveContains(searchText)
            || $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    func ensureLoaded(for sport: String) async {
        guard !loadedSports.contains(sport) else { return }
        await loadNews(for: sport, force: true)
    }

    func loadNews(for sport: String, force: Bool = false) async {
        if !force, loadedSports.contains(sport) { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }
        do {
            let events = try await service.fetchNews(for: sport)
            let items = events.map {
                NewsItem(
                    author: $0.strLeague ?? "TheSportsDB",
                    time: $0.dateEvent ?? "Today",
                    sport: sport,
                    title: $0.strEvent?.replacingOccurrences(of: "_", with: " ") ?? "Sports News",
                    subtitle: "\($0.strHomeTeam ?? "Team A") vs \($0.strAwayTeam ?? "Team B")",
                    imageURL: $0.strThumb,
                    likes: Int($0.idEvent.suffix(2)) ?? 0,
                    bookmarked: false
                )
            }
            newsBySport[sport] = items
            if items.isEmpty {
                errorText = "No news for selected sport right now."
            }
            loadedSports.insert(sport)
        } catch is CancellationError {
            return
        } catch {
            newsBySport[sport] = []
            errorText = "Failed to load news."
        }
    }
}

struct NewsView: View {
    @StateObject private var vm = NewsViewModel()
    @State private var selectedLeague: League = .football

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 12) {
                    Text("Sports News")
                        .font(.custom("Inter-SemiBold", size: 17))
                        .foregroundStyle(.white)
                        .padding(.top, 14)

                    SearchBar(text: $vm.searchText, placeholder: "Search sports")

                    LeagueChips(selected: $selectedLeague)

                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if let error = vm.errorText {
                        Text(error)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            let currentSport = selectedLeague.apiSport
                            ForEach(vm.filteredNews(for: currentSport)) { item in
                                NavigationLink(
                                    value: NewsRoute(
                                        title: item.title,
                                        subtitle: item.subtitle,
                                        author: item.author,
                                        time: item.time,
                                        imageURL: item.imageURL
                                    )
                                ) {
                                    NewsDetailCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 90)
                    }
                    .refreshable {
                        await vm.loadNews(for: selectedLeague.apiSport, force: true)
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: NewsRoute.self) { route in
                NewsStoryDetailView(route: route)
            }
            .task(id: selectedLeague) {
                await vm.ensureLoaded(for: selectedLeague.apiSport)
            }
        }
    }
}

private struct NewsDetailCard: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RemoteRectImage(urlString: item.imageURL, systemName: "photo")
                .frame(height: 180)
                .clipped()

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 14, height: 14)
                Text("\(item.author)  •  \(item.time)")
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.horizontal, 12)

            Text(item.title)
                .font(.custom("Inter-SemiBold", size: 28))
                .foregroundStyle(.white)
                .lineSpacing(3)
                .padding(.horizontal, 12)

            Text(item.subtitle)
                .font(.custom("Inter-SemiBold", size: 14))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .background(Color(red: 0.01, green: 0.08, blue: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.vertical, 8)
    }
}


@MainActor
final class TeamsViewModel: ObservableObject {
    @Published var teamName = "Team"
    @Published var teamBadgeURL: String?
    @Published var teamFieldImageURL: String?
    @Published var league = "League"
    @Published var scoreLeft = 0
    @Published var scoreRight = 0
    @Published var opponentName = "Opponent"
    @Published var opponentBadgeURL: String?
    @Published var stats = TeamStats(rows: [])
    @Published var standings: [StandingRow] = []
    @Published var isLoading = false
    @Published var errorText: String?

    private let service: TheSportsDBServicing
    private var loadedLeagues = Set<League>()
    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func ensureLoaded(for selectedLeague: League) async {
        guard !loadedLeagues.contains(selectedLeague) else { return }
        await load(for: selectedLeague, force: true)
    }

    func load(for selectedLeague: League, force: Bool = false) async {
        if !force, loadedLeagues.contains(selectedLeague) { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }
        do {
            let payload = try await service.fetchTeamProfile(sport: selectedLeague.apiSport)
            teamName = payload.team.strTeam ?? "Team"
            teamBadgeURL = payload.team.strBadge
            teamFieldImageURL = payload.team.strFanart1 ?? payload.team.strBanner
            self.league = payload.team.strLeague ?? "League"

            if let recent = payload.recentEvent {
                scoreLeft = recent.homeScoreInt ?? 0
                scoreRight = recent.awayScoreInt ?? 0

                let isHome = recent.strHomeTeam == teamName
                opponentName = isHome ? (recent.strAwayTeam ?? "Opponent") : (recent.strHomeTeam ?? "Opponent")
                opponentBadgeURL = await service.fetchTeamBadge(teamName: opponentName)
            }

            stats = TeamStats(
                rows: payload.stats.map {
                    TeamStats.Row(
                        title: $0.strStat,
                        left: numericValue($0.strHome),
                        right: numericValue($0.strAway)
                    )
                }.filter { $0.left != 0 || $0.right != 0 },
                leftImageURL: teamBadgeURL,
                rightImageURL: opponentBadgeURL
            )

            let leagueBadges = await service.fetchTeamBadges(
                leagueName: payload.team.strLeague ?? "",
                sport: selectedLeague.apiSport
            )

            let tableRows = payload.standings.enumerated().map { index, row in
                StandingRow(
                    rank: Int(row.intRank ?? "") ?? (index + 1),
                    team: row.strTeam ?? "Team",
                    record: "\(row.intWin ?? "0") : \(row.intLoss ?? "0")",
                    pct: row.intPoints ?? "-",
                    gb: row.intGoalDifference ?? "-",
                    imageURL: leagueBadges[row.strTeam ?? ""]
                )
            }
            standings = tableRows
            if stats.rows.isEmpty && standings.isEmpty {
                errorText = "No team data for selected sport right now."
            }
            loadedLeagues.insert(selectedLeague)
        } catch is CancellationError {
            return
        } catch {
            errorText = "Failed to load team data."
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

struct TeamsView: View {
    @StateObject private var vm = TeamsViewModel()
    @State private var selectedLeague: League = .football
    @State private var selectedSection = "All"
    private let sectionTabs = ["All", "Standings", "Statistics", "Injuries"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Text("Team Profile")
                        .font(.custom("Inter-SemiBold", size: 17))
                        .foregroundStyle(.white)
                        .padding(.top, 14)

                    if let field = vm.teamFieldImageURL, let url = URL(string: field) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFill()
                            default: Color.white.opacity(0.06)
                            }
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    TeamProfileScoreCard(
                        league: vm.league,
                        homeName: vm.teamName,
                        awayName: vm.opponentName,
                        homeBadgeURL: vm.teamBadgeURL,
                        awayBadgeURL: vm.opponentBadgeURL,
                        scoreLeft: vm.scoreLeft,
                        scoreRight: vm.scoreRight
                    )

                    LeagueChips(selected: $selectedLeague)

                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if let error = vm.errorText {
                        Text(error)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    TeamSectionTabs(items: sectionTabs, selected: $selectedSection)

                    if selectedSection == "All" || selectedSection == "Statistics" {
                        if !vm.stats.rows.isEmpty {
                            HStack {
                                TeamCornerIcon(urlString: vm.teamBadgeURL)
                                Spacer()
                                Text("Team Stats")
                                    .font(.custom("Inter-SemiBold", size: 20))
                                    .foregroundStyle(.white)
                                Spacer()
                                TeamCornerIcon(urlString: vm.opponentBadgeURL)
                            }

                            VStack(spacing: 16) {
                                ForEach(vm.stats.rows) { row in
                                    StatRowV2(title: row.title, left: row.left, right: row.right)
                                }
                            }
                            .padding(16)
                            .background(CardBackground())
                        }
                    }

                    if selectedSection == "All" || selectedSection == "Standings" {
                        Text("Team Standings")
                            .font(.custom("Inter-SemiBold", size: 24))
                            .foregroundStyle(.white)
                            .padding(.top, 12)

                        StandingsTable(rows: vm.standings)
                    }

                    if selectedSection == "Injuries" {
                        Text("No injuries data from selected endpoint")
                            .font(.custom("Inter-SemiBold", size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.vertical, 12)
                    }

                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                await vm.load(for: selectedLeague, force: true)
            }
        }
        .task(id: selectedLeague) {
            await vm.ensureLoaded(for: selectedLeague)
        }
    }
}

private struct TeamProfileScoreCard: View {
    let league: String
    let homeName: String
    let awayName: String
    let homeBadgeURL: String?
    let awayBadgeURL: String?
    let scoreLeft: Int
    let scoreRight: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TeamPill(text: league, icon: nil)
                Spacer()
                TeamPill(text: "Football", icon: "soccerball")
            }

            HStack {
                VStack(spacing: 6) {
                    TeamCornerIcon(urlString: homeBadgeURL)
                    Text(homeName)
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Text("\(scoreLeft) : \(scoreRight)")
                    .font(.custom("Inter-SemiBold", size: 46))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                VStack(spacing: 6) {
                    TeamCornerIcon(urlString: awayBadgeURL)
                    Text(awayName)
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            Text("Possession")
                .font(.custom("Inter-SemiBold", size: 11))
                .foregroundStyle(.white.opacity(0.55))

            HStack {
                Text("50%")
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("50%")
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(.white.opacity(0.55))
            }

            TeamPossessionBar(left: 0.5)
                .frame(height: 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.72), Color.blue.opacity(0.45), Color.white.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

private struct TeamPill: View {
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

private struct TeamPossessionBar: View {
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

private struct TeamSectionTabs: View {
    let items: [String]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 18) {
            ForEach(items, id: \.self) { item in
                Button {
                    selected = item
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: icon(for: item))
                            .font(.system(size: 14, weight: .medium))
                        Text(item)
                            .font(.custom("Inter-SemiBold", size: 11))
                    }
                    .foregroundStyle(selected == item ? Color.blue : Color.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private func icon(for item: String) -> String {
        switch item {
        case "All": return "line.3.horizontal"
        case "Standings": return "trophy"
        case "Statistics": return "clock.arrow.circlepath"
        default: return "cross.case"
        }
    }
}


struct StandingRow: Identifiable {
    let id = UUID()
    let rank: Int
    let team: String
    let record: String
    let pct: String
    let gb: String
    let imageURL: String?
}

struct StandingsTable: View {
    let rows: [StandingRow]

    var body: some View {
        if rows.isEmpty {
            Text("No standings data for selected sport")
                .font(.custom("Inter-SemiBold", size: 12))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 8) {
                HStack {
                    Text("Team")
                    Spacer()
                    Text("W : L")
                    Spacer()
                    Text("PCT")
                    Spacer()
                    Text("GB")
                }
                .font(.custom("Inter-SemiBold", size: 11))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.08)))

                ForEach(rows) { row in
                    HStack {
                        Text("\(row.rank)")
                            .font(.custom("Inter-SemiBold", size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 16, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        CircleIcon(urlString: row.imageURL)

                        Text(row.team)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(row.record)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 44)

                        Text(row.pct)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 38)

                        Text(row.gb)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 22)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.05)))
                }
            }
        }
    }
}

#Preview("Shell") {
    AppShellView()
}
