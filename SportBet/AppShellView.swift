import SwiftUI

private func appNormalizedIdentity(_ value: String?) -> String {
    (value ?? "")
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
}

private func appSanitizedDisplayName(_ value: String?, fallback: String) -> String {
    let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return fallback }
    let normalized = appNormalizedIdentity(trimmed)
    if ["home", "away", "team", "tbd"].contains(normalized) {
        return fallback
    }
    return trimmed
}

private func appSanitizedLeagueName(_ value: String?, fallback: String = "League") -> String {
    let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? fallback : trimmed
}

private func appEventIdentity(
    fixtureId: Int,
    homeName: String,
    awayName: String,
    league: String,
    eventDate: String?,
    eventTime: String?
) -> String {
    if fixtureId > 0 {
        return String(fixtureId)
    }
    return [
        appNormalizedIdentity(homeName),
        appNormalizedIdentity(awayName),
        appNormalizedIdentity(league),
        eventDate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
        eventTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    ].joined(separator: "|")
}

private func appAlertTitle(
    event: TheSportsDBEvent?,
    record: MatchNotificationRecord,
    state: AlertItemState
) -> String {
    let home = appSanitizedDisplayName(event?.strHomeTeam ?? record.homeName, fallback: "Home")
    let away = appSanitizedDisplayName(event?.strAwayTeam ?? record.awayName, fallback: "Away")

    if state == .delivered, let homeScore = event?.homeScoreInt, let awayScore = event?.awayScoreInt {
        return "\(home) \(homeScore):\(awayScore) \(away)"
    }

    return "\(home) vs \(away)"
}

private func appAlertSubtitle(
    event: TheSportsDBEvent?,
    record: MatchNotificationRecord,
    state: AlertItemState,
    normalizedStatus: (String?) -> String?
) -> String {
    switch state {
    case .scheduled:
        let parts = [
            appSanitizedLeagueName(event?.strLeague ?? record.league),
            {
                guard let date = record.scheduledAt else { return "" }
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return "Kickoff \(formatter.string(from: date))"
            }()
        ]
        .filter { !$0.isEmpty }
        return parts.joined(separator: " • ")
    case .delivered:
        let status = normalizedStatus(event?.strStatus) ?? "Match started"
        let parts = [
            appSanitizedLeagueName(event?.strLeague ?? record.league),
            status
        ]
        .filter { !$0.isEmpty }
        return parts.joined(separator: " • ")
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case matches = "Matches"
    case leagues = "Leagues"
    case alerts = "Alerts"
    case settings = "Settings"

    var id: String { rawValue }

    var textKey: AppTextKey {
        switch self {
        case .matches: return .tabMatches
        case .leagues: return .tabLeagues
        case .alerts: return .tabAlerts
        case .settings: return .tabSettings
        }
    }

    var icon: String {
        switch self {
        case .matches: return "soccerball"
        case .leagues: return "trophy"
        case .alerts: return "bell"
        case .settings: return "gearshape.fill"
        }
    }
}

enum FootballTournament: String, CaseIterable, Identifiable {
    case premierLeague = "Premier League"
    case laLiga = "La Liga"
    case serieA = "Serie A"
    case bundesliga = "Bundesliga"
    case ligue1 = "Ligue 1"

    var id: String { rawValue }

    var leagueId: Int {
        switch self {
        case .premierLeague: return 4328
        case .laLiga: return 4335
        case .serieA: return 4332
        case .bundesliga: return 4331
        case .ligue1: return 4334
        }
    }
}

struct AppShellView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var alertsViewModel = AlertsViewModel()
    @AppStorage("settings.theme") private var themeSelection = AppThemeMode.dark.rawValue
    @AppStorage("settings.language") private var languageCode = AppLanguage.english.rawValue
    @AppStorage("browse.selectedCompetitionIDs") private var selectedCompetitionIDsStorage = ""
    @State private var selectedTab: AppTab = .matches
    @State private var isBootstrapping = true

    private var palette: AppThemePalette {
        (AppThemeMode(rawValue: themeSelection) ?? .dark).palette
    }

    private var selectedCompetitionIDs: Set<String> {
        let stored = Set(selectedCompetitionIDsStorage.split(separator: "|").map(String.init))
        return stored.isEmpty ? BrowseCatalog.defaultCompetitionIDs : stored
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if isBootstrapping {
                    AppLaunchLoaderView(palette: palette, languageCode: languageCode)
                } else {
                    Group {
                        switch selectedTab {
                        case .matches: HomeView(viewModel: homeViewModel)
                        case .leagues: MatchesView()
                        case .alerts: AlertsView(viewModel: alertsViewModel)
                        case .settings: SettingsView()
                        }
                    }
                    AppBottomBar(selectedTab: $selectedTab)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            guard isBootstrapping else { return }
            if selectedCompetitionIDsStorage.isEmpty {
                selectedCompetitionIDsStorage = BrowseCatalog.defaultCompetitionIDs.sorted().joined(separator: "|")
            }
            let initialCompetitionIDs = selectedCompetitionIDs
            await homeViewModel.load(competitionIDs: initialCompetitionIDs)
            isBootstrapping = false
            Task {
                await homeViewModel.preloadHomeSports(selectedCompetitionIDs: initialCompetitionIDs)
            }
        }
    }
}

private struct AppLaunchLoaderView: View {
    let palette: AppThemePalette
    let languageCode: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    palette.elevatedBackground,
                    palette.surfaceSecondary,
                    palette.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(palette.iconBackground)
                        .frame(width: 112, height: 112)

                    Circle()
                        .stroke(palette.divider, lineWidth: 1)
                        .frame(width: 132, height: 132)

                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(palette.secondaryText)
                }

                VStack(spacing: 6) {
                    Text(appText(.launchLoadingTitle, languageCode: languageCode))
                        .font(.custom("Inter-Bold", size: 26))
                        .foregroundStyle(palette.primaryText)

                    Text(appText(.launchLoadingSubtitle, languageCode: languageCode))
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.center)
                }

                ProgressView()
                    .tint(palette.primaryText)
                    .scaleEffect(1.1)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct AppBottomBar: View {
    @Binding var selectedTab: AppTab
    @AppStorage("settings.theme") private var themeSelection = AppThemeMode.dark.rawValue
    @AppStorage("settings.language") private var languageCode = AppLanguage.english.rawValue

    private var palette: AppThemePalette {
        (AppThemeMode(rawValue: themeSelection) ?? .dark).palette
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                        Text(appText(tab.textKey, languageCode: languageCode))
                            .font(.custom("Inter-SemiBold", size: 10))
                    }
                    .foregroundStyle(selectedTab == tab ? palette.accent : palette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            Rectangle()
                .fill(palette.elevatedBackground)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(palette.divider)
                        .frame(height: 1)
                }
        )
    }
}


@MainActor
final class MatchesViewModel: ObservableObject {
    private let maxLoadAttempts = 3
    private struct Snapshot {
        let featured: FeaturedScore
        let finals: [MatchRow]
        let upcoming: [MatchRow]
        let stats: TeamStats
        let standings: [StandingRow]
        let errorText: String?
    }

    @Published var featured = FeaturedScore(
        fixtureId: 0,
        league: "League",
        left: TeamMini(name: "Home"),
        right: TeamMini(name: "Away"),
        leftScore: 0,
        rightScore: 0,
        status: "Not Started",
        eventDate: nil,
        eventTime: nil
    )
    @Published var finals: [MatchRow] = []
    @Published var upcoming: [MatchRow] = []
    @Published var stats = TeamStats(rows: [])
    @Published var standings: [StandingRow] = []
    @Published var isLoading = false
    @Published var errorText: String?

    private let service: TheSportsDBServicing
    private var loadedKeys = Set<String>()
    private var cachedSnapshots: [String: Snapshot] = [:]
    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func ensureLoaded(for league: League, tournament: FootballTournament?) async {
        let key = cacheKey(for: league, tournament: tournament)
        guard !loadedKeys.contains(key) else { return }
        await load(for: league, tournament: tournament, force: true)
    }

    func load(for league: League, tournament: FootballTournament?, force: Bool = false) async {
        let key = cacheKey(for: league, tournament: tournament)
        if !force, let cached = cachedSnapshots[key] {
            apply(cached)
            return
        }
        isLoading = true
        errorText = nil
        defer { isLoading = false }
        do {
            let snapshot = try await loadStableContent(for: league, tournament: tournament)
            cachedSnapshots[key] = snapshot
            apply(snapshot)
            loadedKeys.insert(key)
        } catch is CancellationError {
            return
        } catch {
            if let cached = cachedSnapshots[key] {
                apply(cached)
                return
            }
            loadedKeys.remove(key)
            errorText = "Unable to verify match data right now. Pull to retry."
        }
    }

    private func loadStableContent(for league: League, tournament: FootballTournament?) async throws -> Snapshot {
        for attempt in 0..<maxLoadAttempts {
            let payload: TheSportsDBMatchesPayload
            if league == .football, let tournament {
                payload = try await service.fetchMatchesPayload(leagueId: tournament.leagueId)
            } else {
                payload = try await service.fetchMatchesPayload(sport: league.apiSport)
            }

            let sanitizedFeaturedEvent = sanitizeEvent(payload.featured)
            let sanitizedFinalEvents = deduplicatedEvents(payload.finals.map(sanitizeEvent))
            let sanitizedUpcomingEvents = deduplicatedEvents(payload.upcoming.map(sanitizeEvent))
            let allEvents = [sanitizedFeaturedEvent] + sanitizedFinalEvents + sanitizedUpcomingEvents
            async let badgesTask = badgeMap(for: allEvents, sport: league.apiSport)
            async let leagueBadgesTask = service.fetchTeamBadges(
                leagueName: payload.featured.strLeague ?? "",
                sport: league.apiSport
            )
            let badges = await badgesTask
            let leagueBadges = await leagueBadgesTask

            let nextFeatured = FeaturedScore(
                fixtureId: Int(sanitizedFeaturedEvent.idEvent) ?? 0,
                league: appSanitizedLeagueName(sanitizedFeaturedEvent.strLeague),
                left: TeamMini(
                    name: appSanitizedDisplayName(sanitizedFeaturedEvent.strHomeTeam, fallback: "Home"),
                    imageURL: badges[appSanitizedDisplayName(sanitizedFeaturedEvent.strHomeTeam, fallback: "Home")]
                ),
                right: TeamMini(
                    name: appSanitizedDisplayName(sanitizedFeaturedEvent.strAwayTeam, fallback: "Away"),
                    imageURL: badges[appSanitizedDisplayName(sanitizedFeaturedEvent.strAwayTeam, fallback: "Away")]
                ),
                leftScore: sanitizedFeaturedEvent.homeScoreInt ?? 0,
                rightScore: sanitizedFeaturedEvent.awayScoreInt ?? 0,
                status: normalizedStatus(sanitizedFeaturedEvent.strStatus),
                eventDate: sanitizedFeaturedEvent.dateEvent,
                eventTime: sanitizedFeaturedEvent.strTime
            )

            let nextFinals = sanitizedFinalEvents.map { event in
                let homeName = appSanitizedDisplayName(event.strHomeTeam, fallback: "Home")
                let awayName = appSanitizedDisplayName(event.strAwayTeam, fallback: "Away")
                return MatchRow(
                    fixtureId: Int(event.idEvent) ?? 0,
                    left: TeamMini(name: homeName, imageURL: badges[homeName]),
                    right: TeamMini(name: awayName, imageURL: badges[awayName]),
                    scoreLeft: event.homeScoreInt,
                    scoreRight: event.awayScoreInt,
                    league: appSanitizedLeagueName(event.strLeague),
                    showScore: event.homeScoreInt != nil && event.awayScoreInt != nil,
                    eventDate: event.dateEvent,
                    eventTime: event.strTime
                )
            }

            let nextUpcoming = sanitizedUpcomingEvents.map { event in
                let homeName = appSanitizedDisplayName(event.strHomeTeam, fallback: "Home")
                let awayName = appSanitizedDisplayName(event.strAwayTeam, fallback: "Away")
                return MatchRow(
                    fixtureId: Int(event.idEvent) ?? 0,
                    left: TeamMini(name: homeName, imageURL: badges[homeName]),
                    right: TeamMini(name: awayName, imageURL: badges[awayName]),
                    scoreLeft: event.homeScoreInt,
                    scoreRight: event.awayScoreInt,
                    league: appSanitizedLeagueName(event.strLeague),
                    showScore: event.homeScoreInt != nil && event.awayScoreInt != nil,
                    eventDate: event.dateEvent,
                    eventTime: event.strTime
                )
            }

            let nextStats = TeamStats(
                rows: payload.stats.map {
                    TeamStats.Row(
                        title: $0.strStat,
                        left: numericValue($0.strHome),
                        right: numericValue($0.strAway)
                    )
                }.filter { $0.left != 0 || $0.right != 0 },
                leftImageURL: nextFeatured.left.imageURL,
                rightImageURL: nextFeatured.right.imageURL
            )

            let nextStandings = payload.standings.enumerated().map { index, row in
                let teamName = appSanitizedDisplayName(row.strTeam, fallback: "Team")
                return StandingRow(
                    rank: Int(row.intRank ?? "") ?? (index + 1),
                    team: teamName,
                    record: "\(row.intWin ?? "0") : \(row.intLoss ?? "0")",
                    pct: row.intPoints ?? "-",
                    gb: row.intGoalDifference ?? "-",
                    imageURL: leagueBadges[teamName]
                )
            }

            if isMeaningful(
                featured: nextFeatured,
                finals: nextFinals,
                upcoming: nextUpcoming,
                standings: nextStandings
            ) {
                return Snapshot(
                    featured: nextFeatured,
                    finals: nextFinals,
                    upcoming: nextUpcoming,
                    stats: nextStats,
                    standings: nextStandings,
                    errorText: (nextFinals.isEmpty && nextUpcoming.isEmpty)
                        ? "No verified matches are available for this selection right now."
                        : nil
                )
            }

            if attempt < maxLoadAttempts - 1 {
                try await Task.sleep(nanoseconds: 350_000_000)
            }
        }

        throw URLError(.badServerResponse)
    }

    private func apply(_ snapshot: Snapshot) {
        featured = snapshot.featured
        finals = snapshot.finals
        upcoming = snapshot.upcoming
        stats = snapshot.stats
        standings = snapshot.standings
        errorText = snapshot.errorText
    }

    private func isMeaningful(
        featured: FeaturedScore,
        finals: [MatchRow],
        upcoming: [MatchRow],
        standings: [StandingRow]
    ) -> Bool {
        if !finals.isEmpty || !upcoming.isEmpty || !standings.isEmpty {
            return true
        }
        return featured.fixtureId > 0
            && featured.left.name != "Home"
            && featured.right.name != "Away"
    }

    private func badgeMap(for events: [TheSportsDBEvent], sport: String) async -> [String: String] {
        let names = Set(
            events.flatMap {
                [
                    appSanitizedDisplayName($0.strHomeTeam, fallback: ""),
                    appSanitizedDisplayName($0.strAwayTeam, fallback: "")
                ]
            }
        ).filter { !$0.isEmpty }
        var map: [String: String] = [:]

        func mergeBadges(_ badges: [String: String], into map: inout [String: String]) {
            for (rawName, badge) in badges {
                let sanitizedName = appSanitizedDisplayName(rawName, fallback: "")
                guard !sanitizedName.isEmpty else { continue }
                if map[sanitizedName] == nil {
                    map[sanitizedName] = badge
                }
                let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty, map[trimmedName] == nil {
                    map[trimmedName] = badge
                }
            }
        }

        let leagues = Array(Set(events.map { appSanitizedLeagueName($0.strLeague, fallback: "") }.filter { !$0.isEmpty })).prefix(3)
        let bulkBadges = await withTaskGroup(of: [String: String].self) { group in
            for leagueName in leagues {
                group.addTask { [service] in
                    await service.fetchTeamBadges(leagueName: leagueName, sport: sport)
                }
            }

            var resolved: [[String: String]] = []
            for await badges in group {
                resolved.append(badges)
            }
            return resolved
        }

        for badges in bulkBadges {
            mergeBadges(badges, into: &map)
        }

        let missing = names.filter { map[$0] == nil }.prefix(8)
        let fetchedMissing = await withTaskGroup(of: (String, String?).self) { group in
            for name in missing {
                group.addTask { [service] in
                    (name, await service.fetchTeamBadge(teamName: name))
                }
            }

            var badges: [String: String] = [:]
            for await (name, badge) in group {
                if let badge {
                    badges[name] = badge
                }
            }
            return badges
        }

        mergeBadges(fetchedMissing, into: &map)
        return map
    }

    private func deduplicatedEvents(_ events: [TheSportsDBEvent]) -> [TheSportsDBEvent] {
        var seen = Set<String>()
        var unique: [TheSportsDBEvent] = []

        for event in events {
            let homeName = appSanitizedDisplayName(event.strHomeTeam, fallback: "")
            let awayName = appSanitizedDisplayName(event.strAwayTeam, fallback: "")
            guard !homeName.isEmpty, !awayName.isEmpty else { continue }
            let key = appEventIdentity(
                fixtureId: Int(event.idEvent) ?? 0,
                homeName: homeName,
                awayName: awayName,
                league: appSanitizedLeagueName(event.strLeague),
                eventDate: event.dateEvent,
                eventTime: event.strTime
            )
            guard seen.insert(key).inserted else { continue }
            unique.append(event)
        }

        return unique
    }

    private func sanitizeEvent(_ event: TheSportsDBEvent) -> TheSportsDBEvent {
        TheSportsDBEvent(
            idEvent: event.idEvent,
            idLeague: event.idLeague,
            idHomeTeam: event.idHomeTeam,
            idAwayTeam: event.idAwayTeam,
            strLeague: appSanitizedLeagueName(event.strLeague),
            strEvent: event.strEvent?.trimmingCharacters(in: .whitespacesAndNewlines),
            strHomeTeam: appSanitizedDisplayName(event.strHomeTeam, fallback: "Home"),
            strAwayTeam: appSanitizedDisplayName(event.strAwayTeam, fallback: "Away"),
            intHomeScore: event.intHomeScore,
            intAwayScore: event.intAwayScore,
            dateEvent: event.dateEvent,
            strTime: event.strTime,
            strStatus: normalizedStatus(event.strStatus),
            strVenue: event.strVenue,
            strThumb: event.strThumb,
            strVideo: event.strVideo,
            strOfficial: event.strOfficial,
            intSpectators: event.intSpectators,
            strSport: event.strSport,
            intHomeShots: event.intHomeShots,
            intAwayShots: event.intAwayShots,
            intHomeShotsOnGoal: event.intHomeShotsOnGoal,
            intAwayShotsOnGoal: event.intAwayShotsOnGoal,
            intHomeCorners: event.intHomeCorners,
            intAwayCorners: event.intAwayCorners,
            intHomeFouls: event.intHomeFouls,
            intAwayFouls: event.intAwayFouls,
            intHomeOffsides: event.intHomeOffsides,
            intAwayOffsides: event.intAwayOffsides,
            intHomeYellowCards: event.intHomeYellowCards,
            intAwayYellowCards: event.intAwayYellowCards,
            intHomeRedCards: event.intHomeRedCards,
            intAwayRedCards: event.intAwayRedCards,
            intHomeSaves: event.intHomeSaves,
            intAwaySaves: event.intAwaySaves
        )
    }

    private func normalizedStatus(_ raw: String?) -> String {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Scheduled" : trimmed.replacingOccurrences(of: "_", with: " ")
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

    private func cacheKey(for league: League, tournament: FootballTournament?) -> String {
        if league == .football {
            return "\(league.rawValue)|\(tournament?.rawValue ?? "none")"
        }
        return league.rawValue
    }
}

struct MatchesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSport: League = .football
    @State private var searchText = ""
    @State private var expandedCountryIDs: Set<String> = ["football-england"]
    @StateObject private var artworkStore = BrowseLeagueArtworkStore()
    @AppStorage("browse.selectedCompetitionIDs") private var selectedCompetitionIDsStorage = ""

    private let browseSports: [League] = [.football, .basketball, .iceHockey]
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    private var selectedCompetitionIDs: Set<String> {
        let stored = Set(selectedCompetitionIDsStorage.split(separator: "|").map(String.init))
        return stored.isEmpty ? BrowseCatalog.defaultCompetitionIDs : stored
    }

    private var topCompetitions: [BrowseCompetition] {
        BrowseCatalog.topCompetitions(for: selectedSport).filter(matchesSearch)
    }

    private var visibleCountries: [BrowseCountry] {
        BrowseCatalog
            .countries(for: selectedSport)
            .compactMap { country in
                guard !searchText.isEmpty else { return country }
                let countryMatches = country.title.localizedCaseInsensitiveContains(searchText)
                let filteredCompetitions = country.competitions.filter(matchesSearch)
                if countryMatches || !filteredCompetitions.isEmpty {
                    return BrowseCountry(
                        id: country.id,
                        title: country.title,
                        flag: country.flag,
                        sport: country.sport,
                        competitions: filteredCompetitions
                    )
                }
                return nil
            }
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Browse")
                        .font(.custom("Inter-Bold", size: 30))
                        .foregroundStyle(palette.primaryText)
                        .padding(.top, 24)

                    BrowseSearchBar(text: $searchText)

                    BrowseSportBar(
                        sports: browseSports,
                        selected: $selectedSport
                    )

                    Rectangle()
                        .fill(palette.divider)
                        .frame(height: 1)

                    Text("Top Competitions")
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundStyle(palette.primaryText)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(topCompetitions) { competition in
                            BrowseCompetitionCard(
                                competition: competition,
                                remoteImageURL: artworkStore.artworkURL(for: competition.id),
                                isSelected: isSelected(competition),
                                action: { toggleCompetition(competition) }
                            )
                        }
                    }

                    HStack {
                        Text("All Countries")
                            .font(.custom("Inter-Bold", size: 18))
                            .foregroundStyle(palette.primaryText)

                        Spacer()

                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(palette.secondaryText)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 14) {
                        ForEach(visibleCountries) { country in
                            BrowseCountryCard(
                                country: country,
                                isExpanded: expandedCountryIDs.contains(country.id),
                                selectedCompetitionIDs: selectedCompetitionIDs,
                                toggleExpanded: { toggleExpanded(country.id) },
                                toggleCompetition: { toggleCompetition($0) }
                            )
                        }
                    }
                    .padding(.bottom, 120)
                }
                .padding(.horizontal, 18)
            }
        }
        .onAppear {
            if selectedCompetitionIDsStorage.isEmpty {
                selectedCompetitionIDsStorage = BrowseCatalog.defaultCompetitionIDs.sorted().joined(separator: "|")
            }
            ensureExpandedCountry(for: selectedSport)
        }
        .task(id: selectedSport) {
            await artworkStore.ensureLoaded(for: selectedSport)
        }
        .onChange(of: selectedSport) { sport in
            ensureExpandedCountry(for: sport)
        }
    }

    private func ensureExpandedCountry(for sport: League) {
        if expandedCountryIDs.isEmpty,
           let first = BrowseCatalog.countries(for: sport).first?.id {
            expandedCountryIDs = [first]
            return
        }

        if !BrowseCatalog.countries(for: sport).contains(where: { expandedCountryIDs.contains($0.id) }),
           let first = BrowseCatalog.countries(for: sport).first?.id {
            expandedCountryIDs = [first]
        }
    }

    private func matchesSearch(_ competition: BrowseCompetition) -> Bool {
        guard !searchText.isEmpty else { return true }
        return competition.title.localizedCaseInsensitiveContains(searchText)
            || competition.subtitle.localizedCaseInsensitiveContains(searchText)
            || competition.countryTitle.localizedCaseInsensitiveContains(searchText)
    }

    private func isSelected(_ competition: BrowseCompetition) -> Bool {
        selectedCompetitionIDs.contains(competition.id)
    }

    private func toggleExpanded(_ id: String) {
        if expandedCountryIDs.contains(id) {
            expandedCountryIDs.remove(id)
        } else {
            expandedCountryIDs.insert(id)
        }
    }

    private func toggleCompetition(_ competition: BrowseCompetition) {
        var updated = selectedCompetitionIDs
        if updated.contains(competition.id) {
            updated.remove(competition.id)
        } else {
            updated.insert(competition.id)
        }
        selectedCompetitionIDsStorage = updated.sorted().joined(separator: "|")
    }
}

struct BrowseCompetition: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let countryTitle: String
    let sport: League
    let apiLeagueId: Int?
    let imageAssetName: String?
    let symbol: String
    let tint: Color
    let aliases: [String]
}

struct BrowseCountry: Identifiable {
    let id: String
    let title: String
    let flag: String
    let sport: League
    let competitions: [BrowseCompetition]
}

enum BrowseCatalog {
    static let defaultCompetitionIDs: Set<String> = [
        "football-premier-league",
        "football-champions-league",
        "basketball-nba",
        "hockey-nhl"
    ]

    static let countries: [BrowseCountry] = [
        BrowseCountry(
            id: "football-england",
            title: "England",
            flag: "🇬🇧",
            sport: .football,
            competitions: [
                competition("football-premier-league", "Premier League", "England", "England", .football, 4328, "premleague", "soccerball", Color(red: 0.26, green: 0.69, blue: 1), ["English Premier League", "Premier League"]),
                competition("football-championship", "Championship", "England", "England", .football, nil, nil, "shield.lefthalf.filled", Color(red: 0.53, green: 0.61, blue: 1), ["Championship", "EFL Championship"]),
                competition("football-fa-cup", "FA Cup", "England", "England", .football, nil, nil, "flag.fill", Color(red: 1, green: 0.4, blue: 0.32), ["FA Cup"]),
                competition("football-efl-cup", "EFL Cup", "England", "England", .football, nil, nil, "star.circle.fill", Color(red: 0.86, green: 0.78, blue: 0.28), ["EFL Cup", "English League Cup", "League Cup"])
            ]
        ),
        BrowseCountry(
            id: "football-spain",
            title: "Spain",
            flag: "🇪🇸",
            sport: .football,
            competitions: [
                competition("football-la-liga", "La Liga", "Spain", "Spain", .football, 4335, "laliga", "sun.max.fill", Color(red: 1, green: 0.63, blue: 0.27), ["Spanish La Liga", "La Liga"]),
                competition("football-copa-del-rey", "Copa del Rey", "Spain", "Spain", .football, nil, nil, "crown.fill", Color(red: 0.93, green: 0.34, blue: 0.31), ["Copa del Rey"]),
                competition("football-segunda", "Segunda", "Spain", "Spain", .football, nil, nil, "shield.fill", Color(red: 0.38, green: 0.77, blue: 0.91), ["Segunda Division", "Spanish Segunda Division"])
            ]
        ),
        BrowseCountry(
            id: "football-italy",
            title: "Italy",
            flag: "🇮🇹",
            sport: .football,
            competitions: [
                competition("football-serie-a", "Serie A", "Italy", "Italy", .football, 4332, nil, "circle.grid.hex.fill", Color(red: 0.2, green: 0.73, blue: 1), ["Italian Serie A", "Serie A"]),
                competition("football-coppa-italia", "Coppa Italia", "Italy", "Italy", .football, nil, nil, "flag.2.crossed.fill", Color(red: 0.43, green: 0.84, blue: 0.44), ["Coppa Italia"])
            ]
        ),
        BrowseCountry(
            id: "football-germany",
            title: "Germany",
            flag: "🇩🇪",
            sport: .football,
            competitions: [
                competition("football-bundesliga", "Bundesliga", "Germany", "Germany", .football, 4331, nil, "bolt.horizontal.circle.fill", Color(red: 1, green: 0.48, blue: 0.32), ["German Bundesliga", "Bundesliga"]),
                competition("football-dfb-pokal", "DFB Pokal", "Germany", "Germany", .football, nil, nil, "hexagon.fill", Color(red: 0.91, green: 0.31, blue: 0.27), ["DFB Pokal"])
            ]
        ),
        BrowseCountry(
            id: "football-france",
            title: "France",
            flag: "🇫🇷",
            sport: .football,
            competitions: [
                competition("football-ligue-1", "Ligue 1", "France", "France", .football, 4334, nil, "sparkles", Color(red: 0.46, green: 0.52, blue: 1), ["French Ligue 1", "Ligue 1"]),
                competition("football-coupe-france", "Coupe de France", "France", "France", .football, nil, nil, "trophy.fill", Color(red: 0.22, green: 0.73, blue: 1), ["Coupe de France"])
            ]
        ),
        BrowseCountry(
            id: "football-international",
            title: "International",
            flag: "🌍",
            sport: .football,
            competitions: [
                competition("football-champions-league", "Champions League", "Europe", "International", .football, nil, "champleague", "globe.europe.africa.fill", Color(red: 0.35, green: 0.68, blue: 1), ["UEFA Champions League", "Champions League"]),
                competition("football-europa-league", "Europa League", "Europe", "International", .football, nil, nil, "shield.pattern.checkered", Color(red: 1, green: 0.55, blue: 0.22), ["UEFA Europa League", "Europa League"]),
                competition("football-mls", "MLS", "USA", "International", .football, nil, "mls", "sportscourt.fill", Color(red: 0.55, green: 0.72, blue: 1), ["MLS", "Major League Soccer"])
            ]
        ),
        BrowseCountry(
            id: "basketball-usa",
            title: "USA",
            flag: "🇺🇸",
            sport: .basketball,
            competitions: [
                competition("basketball-nba", "NBA", "USA", "USA", .basketball, 4387, "nba", "basketball.fill", Color(red: 0.31, green: 0.62, blue: 1), ["NBA"]),
                competition("basketball-wnba", "WNBA", "USA", "USA", .basketball, nil, nil, "figure.basketball", Color(red: 1, green: 0.49, blue: 0.3), ["WNBA"])
            ]
        ),
        BrowseCountry(
            id: "basketball-europe",
            title: "Europe",
            flag: "🇪🇺",
            sport: .basketball,
            competitions: [
                competition("basketball-euroleague", "EuroLeague", "Europe", "Europe", .basketball, nil, "euroleague", "basketball.circle.fill", Color(red: 0.61, green: 0.66, blue: 1), ["EuroLeague", "Euroleague"]),
                competition("basketball-acb", "Liga ACB", "Spain", "Europe", .basketball, nil, nil, "circle.hexagongrid.fill", Color(red: 1, green: 0.73, blue: 0.27), ["Liga ACB", "Spanish Liga ACB"])
            ]
        ),
        BrowseCountry(
            id: "basketball-international",
            title: "International",
            flag: "🌍",
            sport: .basketball,
            competitions: [
                competition("basketball-fiba", "FIBA", "International", "International", .basketball, nil, "fiba", "globe.americas.fill", Color(red: 0.2, green: 0.82, blue: 0.71), ["FIBA", "FIBA World Cup", "FIBA Basketball World Cup"]),
                competition("basketball-olympics", "Olympics", "International", "International", .basketball, nil, nil, "medal.fill", Color(red: 0.9, green: 0.78, blue: 0.29), ["Olympics"])
            ]
        ),
        BrowseCountry(
            id: "hockey-usa",
            title: "USA",
            flag: "🇺🇸",
            sport: .iceHockey,
            competitions: [
                competition("hockey-nhl", "NHL", "USA", "USA", .iceHockey, 4380, "nhl", "opticaldisc.fill", Color(red: 0.33, green: 0.69, blue: 1), ["NHL"]),
                competition("hockey-ahl", "AHL", "USA", "USA", .iceHockey, nil, nil, "circle.fill", Color(red: 0.84, green: 0.86, blue: 0.94), ["AHL"])
            ]
        ),
        BrowseCountry(
            id: "hockey-europe",
            title: "Europe",
            flag: "🇪🇺",
            sport: .iceHockey,
            competitions: [
                competition("hockey-khl", "KHL", "Europe", "Europe", .iceHockey, nil, "khl", "snowflake", Color(red: 0.34, green: 0.74, blue: 1), ["KHL"]),
                competition("hockey-shl", "SHL", "Sweden", "Europe", .iceHockey, nil, nil, "drop.fill", Color(red: 1, green: 0.48, blue: 0.27), ["SHL"]),
                competition("hockey-liiga", "Liiga", "Finland", "Europe", .iceHockey, nil, nil, "seal.fill", Color(red: 0.43, green: 0.89, blue: 0.6), ["Liiga"])
            ]
        ),
        BrowseCountry(
            id: "hockey-international",
            title: "International",
            flag: "🌍",
            sport: .iceHockey,
            competitions: [
                competition("hockey-iihf", "IIHF", "International", "International", .iceHockey, nil, "iihf", "globe.europe.africa.fill", Color(red: 0.61, green: 0.7, blue: 1), ["IIHF", "IIHF World Championship", "World Championship"]),
                competition("hockey-chl", "Champions HL", "Europe", "International", .iceHockey, nil, nil, "sparkles", Color(red: 0.91, green: 0.79, blue: 0.3), ["Champions Hockey League"])
            ]
        )
    ]

    static func countries(for sport: League) -> [BrowseCountry] {
        countries.filter { $0.sport == sport }
    }

    static func topCompetitions(for sport: League) -> [BrowseCompetition] {
        switch sport {
        case .football:
            return [
                competition(for: "football-premier-league"),
                competition(for: "football-champions-league"),
                competition(for: "football-la-liga"),
                competition(for: "football-mls")
            ].compactMap { $0 }
        case .basketball:
            return [
                competition(for: "basketball-nba"),
                competition(for: "basketball-euroleague"),
                competition(for: "basketball-fiba")
            ].compactMap { $0 }
        case .iceHockey:
            return [
                competition(for: "hockey-nhl"),
                competition(for: "hockey-khl"),
                competition(for: "hockey-iihf")
            ].compactMap { $0 }
        default:
            return []
        }
    }

    static func competition(for id: String) -> BrowseCompetition? {
        countries
            .flatMap(\.competitions)
            .first(where: { $0.id == id })
    }

    static func matchesSelection(competitionIDs: Set<String>, leagueName: String, sport: League) -> Bool {
        let relevant = competitionIDs.compactMap(competition(for:)).filter { $0.sport == sport }
        guard !relevant.isEmpty else { return true }
        let normalizedLeague = normalize(leagueName)
        return relevant.contains { competition in
            competition.aliases.contains(where: { normalize($0) == normalizedLeague })
                || normalize(competition.title) == normalizedLeague
        }
    }

    private static func competition(
        _ id: String,
        _ title: String,
        _ subtitle: String,
        _ countryTitle: String,
        _ sport: League,
        _ apiLeagueId: Int? = nil,
        _ imageAssetName: String? = nil,
        _ symbol: String,
        _ tint: Color,
        _ aliases: [String]
    ) -> BrowseCompetition {
        BrowseCompetition(
            id: id,
            title: title,
            subtitle: subtitle,
            countryTitle: countryTitle,
            sport: sport,
            apiLeagueId: apiLeagueId,
            imageAssetName: imageAssetName,
            symbol: symbol,
            tint: tint,
            aliases: aliases
        )
    }

    private static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
private final class BrowseLeagueArtworkStore: ObservableObject {
    @Published private var artworkByCompetitionID: [String: String] = [:]

    private let service: TheSportsDBServicing
    private var loadedSports = Set<String>()

    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func artworkURL(for competitionID: String) -> String? {
        artworkByCompetitionID[competitionID]
    }

    func ensureLoaded(for sport: League) async {
        guard !loadedSports.contains(sport.rawValue) else { return }

        let artworks = await withTaskGroup(of: (String, String?).self) { group in
            for competition in BrowseCatalog.countries(for: sport).flatMap(\.competitions) {
                group.addTask { [service] in
                    let artwork: String?
                    if let apiLeagueId = competition.apiLeagueId {
                        artwork = await service.fetchLeagueArtwork(leagueId: apiLeagueId)
                    } else {
                        artwork = await service.fetchLeagueArtwork(
                            leagueName: competition.title,
                            sport: competition.sport.apiSport
                        )
                    }
                    return (competition.id, artwork)
                }
            }

            var resolved: [(String, String?)] = []
            for await artwork in group {
                resolved.append(artwork)
            }
            return resolved
        }

        for (competitionID, artwork) in artworks {
            if let artwork {
                artworkByCompetitionID[competitionID] = artwork
            }
        }

        loadedSports.insert(sport.rawValue)
    }
}

private struct BrowseSearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(palette.secondaryText)

            TextField("Search leagues, teams, or countries...", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(palette.primaryText)
                .font(.custom("Inter-Regular", size: 15))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.iconBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        )
    }
}

private struct BrowseSportBar: View {
    let sports: [League]
    @Binding var selected: League
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 18) {
            ForEach(sports) { sport in
                Button {
                    selected = sport
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selected == sport ? Color(red: 0.07, green: 0.28, blue: 0.5) : palette.iconBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(selected == sport ? Color(red: 0.19, green: 0.61, blue: 1) : palette.divider, lineWidth: 1)
                                )

                            Image(systemName: icon(for: sport))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(selected == sport ? Color(red: 0.19, green: 0.61, blue: 1) : palette.secondaryText)
                        }
                        .frame(width: 62, height: 62)

                        Text(LocalizedStringKey(title(for: sport)))
                            .font(.custom("Inter-Medium", size: 13))
                            .foregroundStyle(selected == sport ? palette.primaryText : palette.secondaryText)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func title(for sport: League) -> String {
        switch sport {
        case .football: return "Football"
        case .basketball: return "Basketball"
        case .iceHockey: return "Hockey"
        default: return sport.rawValue
        }
    }

    private func icon(for sport: League) -> String {
        switch sport {
        case .football: return "soccerball"
        case .basketball: return "basketball.fill"
        case .iceHockey: return "opticaldisc.fill"
        default: return "sportscourt"
        }
    }
}

private struct BrowseCompetitionCard: View {
    let competition: BrowseCompetition
    let remoteImageURL: String?
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(palette.surfaceSecondary)

                    if let remoteImageURL {
                        RemoteRectImage(urlString: remoteImageURL, systemName: competition.symbol)
                            .frame(width: 40, height: 40)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else if let assetName = competition.imageAssetName {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .padding(assetName == "mls" ? 7 : 2)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Image(systemName: competition.symbol)
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(competition.tint)
                    }
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 4) {
                    Text(competition.title)
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundStyle(palette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)

                    Text(competition.subtitle)
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.surface,
                                palette.surfaceSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(isSelected ? Color(red: 0.13, green: 0.56, blue: 1) : palette.divider, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct BrowseCountryCard: View {
    let country: BrowseCountry
    let isExpanded: Bool
    let selectedCompetitionIDs: Set<String>
    let toggleExpanded: () -> Void
    let toggleCompetition: (BrowseCompetition) -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    private var countryHeaderColor: Color {
        colorScheme == .dark ? Color(red: 21 / 255, green: 21 / 255, blue: 26 / 255) : Color(.secondarySystemBackground)
    }

    private var leagueRowColor: Color {
        colorScheme == .dark ? Color(red: 26 / 255, green: 26 / 255, blue: 32 / 255) : Color(.tertiarySystemBackground)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggleExpanded) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(red: 0.18, green: 0.19, blue: 0.24) : palette.iconBackground)
                            .overlay(
                                Circle()
                                    .stroke(palette.divider, lineWidth: 1)
                            )
                        Text(country.flag)
                        .font(.system(size: 18))
                    }
                    .frame(width: 44, height: 44)

                    Text(country.title)
                        .font(.custom("Inter-Bold", size: 17))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 18)
                .frame(height: isExpanded ? 86 : 66)
                .background(countryHeaderColor)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Rectangle()
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 1)

                VStack(spacing: 0) {
                    ForEach(Array(country.competitions.enumerated()), id: \.element.id) { index, competition in
                        HStack(spacing: 12) {
                            Text(competition.title)
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundStyle(Color.primary)

                            Spacer()

                            Button {
                                toggleCompetition(competition)
                            } label: {
                                Image(systemName: selectedCompetitionIDs.contains(competition.id) ? "star.fill" : "star")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(selectedCompetitionIDs.contains(competition.id) ? Color(red: 0.19, green: 0.61, blue: 1) : Color.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 66)
                        .background(leagueRowColor)

                        if index < country.competitions.count - 1 {
                            Rectangle()
                                .fill(Color.primary.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 18)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(countryHeaderColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}


enum AlertsFilter: CaseIterable, Identifiable {
    case all
    case scheduled
    case delivered

    var id: String {
        switch self {
        case .all: return "all"
        case .scheduled: return "scheduled"
        case .delivered: return "delivered"
        }
    }

    var textKey: AppTextKey {
        switch self {
        case .all: return .alertsFilterAll
        case .scheduled: return .alertsFilterScheduled
        case .delivered: return .alertsFilterDelivered
        }
    }
}

enum AlertItemState: Hashable {
    case scheduled
    case delivered
}

struct AlertItem: Identifiable, Hashable {
    let id: String
    let state: AlertItemState
    let title: String
    let subtitle: String
    let league: String
    let homeImageURL: String?
    let awayImageURL: String?
    let date: Date
    let route: MatchRoute
    var isUnread: Bool
}

struct AlertSection: Identifiable {
    let id: String
    let title: String
    let items: [AlertItem]
}

@MainActor
final class AlertsViewModel: ObservableObject {
    @Published private(set) var items: [AlertItem] = []
    @Published var isLoading = false

    private let service: TheSportsDBServicing
    private let readStorageKey = "alerts.readItemIDs"

    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    var hasUnread: Bool {
        items.contains(where: \.isUnread)
    }

    func ensureLoaded() async {
        if items.isEmpty {
            await load(force: true)
        } else {
            applyReadState()
        }
    }

    func load(force: Bool = false) async {
        if !force, !items.isEmpty {
            applyReadState()
            return
        }

        isLoading = true
        defer { isLoading = false }

        let snapshot = await MatchNotificationManager.shared.inboxSnapshot()
        let loaded = await buildItems(from: snapshot)
        items = applyReadState(to: loaded.sorted { $0.date > $1.date })
    }

    func sections(filter: AlertsFilter, languageCode: String) -> [AlertSection] {
        let filtered: [AlertItem]
        switch filter {
        case .all:
            filtered = items
        case .scheduled:
            filtered = items.filter { $0.state == .scheduled }
        case .delivered:
            filtered = items.filter { $0.state == .delivered }
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.date) }

        return grouped.keys.sorted(by: >).map { day in
            AlertSection(
                id: ISO8601DateFormatter().string(from: day),
                title: sectionTitle(for: day, languageCode: languageCode),
                items: grouped[day, default: []].sorted { $0.date > $1.date }
            )
        }
    }

    func markRead(id: String) {
        var ids = readIDs()
        guard ids.insert(id).inserted else { return }
        storeReadIDs(ids)
        applyReadState()
    }

    func markAllRead() {
        var ids = readIDs()
        ids.formUnion(items.map { $0.id })
        storeReadIDs(ids)
        applyReadState()
    }

    private func buildItems(from snapshot: MatchNotificationInboxSnapshot) async -> [AlertItem] {
        await withTaskGroup(of: AlertItem?.self) { group in
            for record in snapshot.records {
                group.addTask { [service] in
                    let identifier = MatchNotificationManager.identifier(for: record.fixtureId)
                    let deliveredDate = snapshot.deliveredDates[identifier]
                    let state: AlertItemState = deliveredDate == nil ? .scheduled : .delivered

                    let payload = try? await service.fetchOverviewPayload(fixtureId: record.fixtureId)
                    let event = payload?.event

                    let homeName = appSanitizedDisplayName(event?.strHomeTeam ?? record.homeName, fallback: "Home")
                    let awayName = appSanitizedDisplayName(event?.strAwayTeam ?? record.awayName, fallback: "Away")
                    let league = appSanitizedLeagueName(event?.strLeague ?? record.league)
                    let route = MatchRoute(
                        fixtureId: record.fixtureId,
                        league: league,
                        homeName: homeName,
                        awayName: awayName,
                        homeScore: event?.homeScoreInt,
                        awayScore: event?.awayScoreInt
                    )

                    return AlertItem(
                        id: identifier,
                        state: state,
                        title: appAlertTitle(event: event, record: record, state: state),
                        subtitle: appAlertSubtitle(
                            event: event,
                            record: record,
                            state: state,
                            normalizedStatus: { raw in
                                let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard let trimmed, !trimmed.isEmpty else { return nil }
                                return trimmed.replacingOccurrences(of: "_", with: " ")
                            }
                        ),
                        league: league,
                        homeImageURL: record.homeImageURL,
                        awayImageURL: record.awayImageURL,
                        date: deliveredDate ?? record.scheduledAt ?? record.createdAt,
                        route: route,
                        isUnread: true
                    )
                }
            }

            var loadedItems: [AlertItem] = []
            for await item in group {
                if let item {
                    loadedItems.append(item)
                }
            }
            return loadedItems
        }
    }

    private func title(
        for event: TheSportsDBEvent?,
        record: MatchNotificationRecord,
        state: AlertItemState
    ) -> String {
        appAlertTitle(event: event, record: record, state: state)
    }

    private func subtitle(
        for event: TheSportsDBEvent?,
        record: MatchNotificationRecord,
        state: AlertItemState
    ) -> String {
        appAlertSubtitle(event: event, record: record, state: state, normalizedStatus: normalizedStatus)
    }

    private func kickoffText(for record: MatchNotificationRecord) -> String {
        guard let date = record.scheduledAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "Kickoff \(formatter.string(from: date))"
    }

    private func normalizedStatus(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.replacingOccurrences(of: "_", with: " ")
    }

    private func sectionTitle(for date: Date, languageCode: String) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return appText(.alertsToday, languageCode: languageCode)
        }
        if calendar.isDateInYesterday(date) {
            return appText(.alertsYesterday, languageCode: languageCode)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: (AppLanguage(rawValue: languageCode) ?? .english).localeIdentifier)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func applyReadState() {
        items = applyReadState(to: items)
    }

    private func applyReadState(to items: [AlertItem]) -> [AlertItem] {
        let ids = readIDs()
        return items.map { item in
            var updated = item
            updated.isUnread = !ids.contains(item.id)
            return updated
        }
    }

    private func readIDs() -> Set<String> {
        let raw = UserDefaults.standard.string(forKey: readStorageKey) ?? ""
        return Set(raw.split(separator: "|").map { String($0) })
    }

    private func storeReadIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(ids.sorted().joined(separator: "|"), forKey: readStorageKey)
    }
}

struct AlertsView: View {
    @ObservedObject var viewModel: AlertsViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("settings.language") private var languageCode = AppLanguage.english.rawValue
    @AppStorage("home.matchNotifications") private var notificationFixturesStorage = ""
    @State private var selectedFilter: AlertsFilter = .all

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    private var sections: [AlertSection] {
        viewModel.sections(filter: selectedFilter, languageCode: languageCode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(appText(.alertsTitle, languageCode: languageCode))
                            .font(.custom("Inter-Bold", size: 30))
                            .foregroundStyle(palette.primaryText)

                        Spacer()

                        if viewModel.hasUnread {
                            Button(appText(.alertsMarkAllRead, languageCode: languageCode)) {
                                viewModel.markAllRead()
                            }
                            .font(.custom("Inter-SemiBold", size: 13))
                            .foregroundStyle(palette.accent)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(AlertsFilter.allCases) { filter in
                                Button {
                                    selectedFilter = filter
                                } label: {
                                    Text(appText(filter.textKey, languageCode: languageCode))
                                        .font(.custom("Inter-SemiBold", size: 14))
                                        .foregroundStyle(selectedFilter == filter ? Color.white : palette.primaryText)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(selectedFilter == filter ? palette.accent : palette.surface)
                                        )
                                        .overlay(
                                            Capsule(style: .continuous)
                                                .stroke(palette.divider, lineWidth: selectedFilter == filter ? 0 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    if viewModel.isLoading && sections.isEmpty {
                        Spacer()
                        ProgressView()
                            .tint(palette.primaryText)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else if sections.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Text(appText(.alertsEmptyTitle, languageCode: languageCode))
                                .font(.custom("Inter-Bold", size: 22))
                                .foregroundStyle(palette.primaryText)
                            Text(appText(.alertsEmptySubtitle, languageCode: languageCode))
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundStyle(palette.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 18) {
                                ForEach(sections) { section in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(section.title)
                                            .font(.custom("Inter-SemiBold", size: 22))
                                            .foregroundStyle(palette.primaryText)

                                        VStack(spacing: 12) {
                                            ForEach(section.items) { item in
                                                NavigationLink(value: item.route) {
                                                    AlertsCard(item: item, languageCode: languageCode, palette: palette)
                                                }
                                                .buttonStyle(.plain)
                                                .simultaneousGesture(TapGesture().onEnded {
                                                    viewModel.markRead(id: item.id)
                                                })
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 90)
                        }
                        .refreshable {
                            await viewModel.load(force: true)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: MatchRoute.self) { route in
                Overview(route: route)
            }
            .task {
                await viewModel.ensureLoaded()
            }
            .task(id: notificationFixturesStorage) {
                await viewModel.load(force: true)
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                Task {
                    await viewModel.load(force: true)
                }
            }
        }
    }
}

private struct AlertsCard: View {
    let item: AlertItem
    let languageCode: String
    let palette: AppThemePalette

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            alertsBadgeStack

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Text(item.title)
                        .font(.custom("Inter-SemiBold", size: 18))
                        .foregroundStyle(palette.primaryText)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 8) {
                        Text(relativeTimeText(for: item.date, languageCode: languageCode))
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundStyle(palette.secondaryText)

                        if item.isUnread {
                            Circle()
                                .fill(item.state == .scheduled ? palette.accent : Color(red: 0.23, green: 0.8, blue: 0.45))
                                .frame(width: 10, height: 10)
                        }
                    }
                }

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.custom("Inter-Regular", size: 15))
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 10) {
                    Text(item.league)
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(alertTint)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack(spacing: 6) {
                        Image(systemName: item.state == .scheduled ? "bell.badge.fill" : "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(appText(.alertsOpenMatch, languageCode: languageCode))
                            .font(.custom("Inter-SemiBold", size: 12))
                    }
                    .foregroundStyle(alertTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(alertTint.opacity(0.14))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        )
    }

    private var alertsBadgeStack: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(spacing: -10) {
                circleBadge(urlString: item.homeImageURL, fallbackText: item.route.homeName)
                circleBadge(urlString: item.awayImageURL, fallbackText: item.route.awayName)
            }

            Circle()
                .fill(alertTint)
                .frame(width: 18, height: 18)
                .overlay {
                    Image(systemName: item.state == .scheduled ? "bell.fill" : "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
        .frame(width: 58, height: 48, alignment: .center)
    }

    private func circleBadge(urlString: String?, fallbackText: String) -> some View {
        ZStack {
            Circle()
                .fill(palette.iconBackground)
            RemoteCircleImage(urlString: urlString, systemName: "shield.fill", fallbackText: fallbackText)
                .frame(width: 32, height: 32)
        }
        .frame(width: 34, height: 34)
    }

    private var alertTint: Color {
        item.state == .scheduled ? palette.accent : Color(red: 0.23, green: 0.8, blue: 0.45)
    }

    private func relativeTimeText(for date: Date, languageCode: String) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: (AppLanguage(rawValue: languageCode) ?? .english).localeIdentifier)
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var newsBySport: [String: [NewsItem]] = [:]
    @Published var isLoading = false
    @Published var isRefreshing = false
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
        if !force, loadedSports.contains(sport), !(newsBySport[sport] ?? []).isEmpty { return }
        if hasVisibleContent(for: sport) {
            isRefreshing = true
        } else {
            isLoading = true
        }
        errorText = nil
        defer {
            isLoading = false
            isRefreshing = false
        }
        do {
            let events = try await service.fetchNews(for: sport)
            let items = makeTrustedNewsItems(from: events, sport: sport)
            newsBySport[sport] = items
            if items.isEmpty {
                errorText = "No verified news is available for this sport right now."
            }
            loadedSports.insert(sport)
        } catch is CancellationError {
            return
        } catch {
            if (newsBySport[sport] ?? []).isEmpty {
                errorText = "Unable to verify news right now. Pull to retry."
            } else {
                errorText = "Showing the latest verified news available."
            }
        }
    }

    private func makeTrustedNewsItems(from events: [TheSportsDBEvent], sport: String) -> [NewsItem] {
        var seen = Set<String>()
        var items: [NewsItem] = []

        for event in events {
            let home = appSanitizedDisplayName(event.strHomeTeam, fallback: "")
            let away = appSanitizedDisplayName(event.strAwayTeam, fallback: "")
            let title = trustedNewsTitle(event: event, home: home, away: away)
            let league = appSanitizedLeagueName(event.strLeague, fallback: sport)
            let identity = [
                appNormalizedIdentity(title),
                appNormalizedIdentity(league),
                appNormalizedIdentity(home),
                appNormalizedIdentity(away),
                event.dateEvent ?? ""
            ].joined(separator: "|")
            guard seen.insert(identity).inserted else { continue }

            let matchup = [home, away].filter { !$0.isEmpty }.joined(separator: " vs ")
            let scoreText: String? = {
                guard let homeScore = event.homeScoreInt, let awayScore = event.awayScoreInt else { return nil }
                return "\(homeScore):\(awayScore)"
            }()
            let subtitle = [league, matchup.isEmpty ? nil : matchup, scoreText]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " • ")
            let body = [
                "\(title) is one of the latest verified updates for \(sport).",
                matchup.isEmpty
                    ? "Open the story for competition context and schedule details."
                    : "This update centers on \(home) and \(away), with the latest verified fixture context available inside the story."
            ].joined(separator: "\n\n")

            items.append(
                NewsItem(
                    author: league,
                    time: event.dateEvent ?? NSLocalizedString("Today", comment: ""),
                    sport: sport,
                    league: league,
                    title: title,
                    subtitle: subtitle,
                    body: body,
                    imageURL: event.strThumb,
                    likes: Int(event.idEvent.suffix(2)) ?? 0,
                    bookmarked: false
                )
            )
        }

        return Array(items.prefix(24))
    }

    private func trustedNewsTitle(event: TheSportsDBEvent, home: String, away: String) -> String {
        let explicit = event.strEvent?
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !explicit.isEmpty {
            return explicit
        }
        if !home.isEmpty && !away.isEmpty {
            return "\(home) vs \(away)"
        }
        return NSLocalizedString("Sports News", comment: "")
    }

    private func hasVisibleContent(for sport: String) -> Bool {
        !(newsBySport[sport] ?? []).isEmpty
    }
}

struct NewsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var vm = NewsViewModel()
    @State private var selectedLeague: League = .football

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()

                VStack(spacing: 12) {
                    Text("Sports News")
                        .font(.custom("Inter-SemiBold", size: 17))
                        .foregroundStyle(palette.primaryText)
                        .padding(.top, 14)

                    SearchBar(text: $vm.searchText, placeholder: "Search sports")

                    LeagueChips(selected: $selectedLeague)

                    if vm.isLoading {
                        ProgressView()
                            .tint(palette.primaryText)
                    } else if vm.isRefreshing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                                .tint(palette.primaryText)
                            Text("Refreshing verified news...")
                                .font(.custom("Inter-SemiBold", size: 12))
                                .foregroundStyle(palette.secondaryText)
                        }
                    } else if let error = vm.errorText {
                        Text(LocalizedStringKey(error))
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(palette.secondaryText)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            let currentSport = selectedLeague.apiSport
                            let items = vm.filteredNews(for: currentSport)
                            if items.isEmpty && !vm.isLoading && vm.errorText == nil {
                                VStack(spacing: 8) {
                                    Text("No verified news yet")
                                        .font(.custom("Inter-Bold", size: 20))
                                        .foregroundStyle(palette.primaryText)
                                    Text("Pull to refresh when new verified updates arrive for this sport.")
                                        .font(.custom("Inter-Regular", size: 14))
                                        .foregroundStyle(palette.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                            } else {
                                ForEach(items) { item in
                                    NavigationLink(
                                    value: NewsRoute(
                                        title: item.title,
                                        subtitle: item.subtitle,
                                        author: item.author,
                                        time: item.time,
                                        imageURL: item.imageURL,
                                        body: item.body,
                                        sport: item.sport,
                                        league: item.league
                                    )
                                ) {
                                    NewsDetailCard(item: item)
                                }
                                .buttonStyle(.plain)
                                }
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
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RemoteRectImage(urlString: item.imageURL, systemName: "photo")
                .frame(height: 180)
                .clipped()

            HStack(spacing: 6) {
                Circle()
                    .fill(palette.iconBackground)
                    .frame(width: 14, height: 14)
                Text("\(item.author)  •  \(item.time)")
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(palette.secondaryText)
            }
            .padding(.horizontal, 12)

            Text(item.title)
                .font(.custom("Inter-SemiBold", size: 28))
                .foregroundStyle(palette.primaryText)
                .lineSpacing(3)
                .padding(.horizontal, 12)

            Text(item.subtitle)
                .font(.custom("Inter-SemiBold", size: 14))
                .foregroundStyle(palette.secondaryText)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.vertical, 8)
    }
}


@MainActor
final class TeamsViewModel: ObservableObject {
    private struct Snapshot {
        let teamName: String
        let teamBadgeURL: String?
        let teamFieldImageURL: String?
        let league: String
        let scoreLeft: Int
        let scoreRight: Int
        let opponentName: String
        let opponentBadgeURL: String?
        let stats: TeamStats
        let standings: [StandingRow]
        let errorText: String?
    }

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
    @Published var isRefreshing = false
    @Published var errorText: String?

    private let service: TheSportsDBServicing
    private var loadedKeys = Set<String>()
    private var cachedSnapshots: [String: Snapshot] = [:]
    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func ensureLoaded(for selectedLeague: League, tournament: FootballTournament?) async {
        let key = cacheKey(for: selectedLeague, tournament: tournament)
        guard !loadedKeys.contains(key) else { return }
        await load(for: selectedLeague, tournament: tournament, force: true)
    }

    func load(for selectedLeague: League, tournament: FootballTournament?, force: Bool = false) async {
        let key = cacheKey(for: selectedLeague, tournament: tournament)
        if !force, let cached = cachedSnapshots[key] {
            apply(cached)
            return
        }
        if hasVisibleContent {
            isRefreshing = true
        } else {
            isLoading = true
        }
        errorText = nil
        defer {
            isLoading = false
            isRefreshing = false
        }
        do {
            let payload: TheSportsDBTeamProfilePayload
            if selectedLeague == .football, let tournament {
                payload = try await service.fetchTeamProfile(leagueId: tournament.leagueId)
            } else {
                payload = try await service.fetchTeamProfile(sport: selectedLeague.apiSport)
            }
            let trustedTeamName = appSanitizedDisplayName(payload.team.strTeam, fallback: "Team")
            let trustedLeague = appSanitizedLeagueName(payload.team.strLeague)
            let scoreLeftValue: Int
            let scoreRightValue: Int
            let trustedOpponentName: String

            if let recent = payload.recentEvent {
                scoreLeftValue = recent.homeScoreInt ?? 0
                scoreRightValue = recent.awayScoreInt ?? 0
                let recentHome = appSanitizedDisplayName(recent.strHomeTeam, fallback: "Home")
                let recentAway = appSanitizedDisplayName(recent.strAwayTeam, fallback: "Away")
                let isHome = appNormalizedIdentity(recentHome) == appNormalizedIdentity(trustedTeamName)
                trustedOpponentName = isHome ? recentAway : recentHome
            } else {
                scoreLeftValue = 0
                scoreRightValue = 0
                trustedOpponentName = "Opponent"
            }

            async let resolvedOpponentBadge = service.fetchTeamBadge(teamName: trustedOpponentName)
            async let leagueBadges = service.fetchTeamBadges(
                leagueName: trustedLeague,
                sport: selectedLeague.apiSport
            )
            let resolvedOpponentBadgeURL = await resolvedOpponentBadge

            let trustedStats = TeamStats(
                rows: payload.stats.map {
                    TeamStats.Row(
                        title: $0.strStat,
                        left: numericValue($0.strHome),
                        right: numericValue($0.strAway)
                    )
                }.filter { $0.left != 0 || $0.right != 0 },
                leftImageURL: payload.team.strBadge,
                rightImageURL: resolvedOpponentBadgeURL
            )

            let badges = await leagueBadges
            let trustedStandings = payload.standings.enumerated().map { index, row in
                let teamName = appSanitizedDisplayName(row.strTeam, fallback: "Team")
                return StandingRow(
                    rank: Int(row.intRank ?? "") ?? (index + 1),
                    team: teamName,
                    record: "\(row.intWin ?? "0") : \(row.intLoss ?? "0")",
                    pct: row.intPoints ?? "-",
                    gb: row.intGoalDifference ?? "-",
                    imageURL: badges[teamName]
                )
            }

            let snapshot = Snapshot(
                teamName: trustedTeamName,
                teamBadgeURL: payload.team.strBadge,
                teamFieldImageURL: payload.team.strFanart1 ?? payload.team.strBanner,
                league: trustedLeague,
                scoreLeft: scoreLeftValue,
                scoreRight: scoreRightValue,
                opponentName: trustedOpponentName,
                opponentBadgeURL: resolvedOpponentBadgeURL,
                stats: trustedStats,
                standings: trustedStandings,
                errorText: trustedStats.rows.isEmpty && trustedStandings.isEmpty
                    ? "No verified team data is available for this selection right now."
                    : nil
            )

            cachedSnapshots[key] = snapshot
            apply(snapshot)
            loadedKeys.insert(key)
        } catch is CancellationError {
            return
        } catch {
            if let cached = cachedSnapshots[key] {
                apply(cached)
                errorText = "Showing the latest verified team data."
                return
            }
            errorText = "Unable to verify team data right now. Pull to retry."
        }
    }

    private func apply(_ snapshot: Snapshot) {
        teamName = snapshot.teamName
        teamBadgeURL = snapshot.teamBadgeURL
        teamFieldImageURL = snapshot.teamFieldImageURL
        league = snapshot.league
        scoreLeft = snapshot.scoreLeft
        scoreRight = snapshot.scoreRight
        opponentName = snapshot.opponentName
        opponentBadgeURL = snapshot.opponentBadgeURL
        stats = snapshot.stats
        standings = snapshot.standings
        errorText = snapshot.errorText
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

    private func cacheKey(for league: League, tournament: FootballTournament?) -> String {
        if league == .football {
            return "\(league.rawValue)|\(tournament?.rawValue ?? "none")"
        }
        return league.rawValue
    }

    private var hasVisibleContent: Bool {
        teamName != "Team" || !stats.rows.isEmpty || !standings.isEmpty
    }
}

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("settings.theme") private var themeSelection = AppThemeMode.dark.rawValue
    @AppStorage("settings.language") private var languageCode = AppLanguage.english.rawValue
    @AppStorage("home.favoriteLeagues") private var favoriteLeaguesStorage = ""
    @AppStorage("home.matchNotifications") private var notificationFixturesStorage = ""
    @AppStorage("browse.selectedCompetitionIDs") private var selectedCompetitionIDsStorage = ""
    @State private var showResetConfirmation = false

    private var theme: AppThemeMode {
        AppThemeMode(rawValue: themeSelection) ?? .dark
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    private var palette: AppThemePalette {
        theme.palette
    }

    private var darkModeBinding: Binding<Bool> {
        Binding(
            get: { theme == .dark },
            set: { themeSelection = $0 ? AppThemeMode.dark.rawValue : AppThemeMode.light.rawValue }
        )
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text(appText(.settingsTitle, languageCode: languageCode))
                        .font(.custom("Inter-Bold", size: 30))
                        .foregroundStyle(palette.primaryText)
                        .padding(.top, 24)

                    settingsSectionTitle(appText(.settingsPreferences, languageCode: languageCode))

                    VStack(spacing: 0) {
                        SettingsToggleRow(
                            icon: theme == .dark ? "moon.fill" : "sun.max.fill",
                            title: appText(.settingsDarkMode, languageCode: languageCode),
                            isOn: darkModeBinding,
                            palette: palette
                        )

                        settingsDivider

                        Menu {
                            ForEach(AppLanguage.allCases) { option in
                                Button {
                                    languageCode = option.rawValue
                                } label: {
                                    if option == language {
                                        Label(option.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(option.displayName)
                                    }
                                }
                            }
                        } label: {
                            SettingsValueRow(
                                icon: "globe",
                                title: appText(.settingsLanguage, languageCode: languageCode),
                                value: language.displayName,
                                palette: palette
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .background(settingsCardBackground)

                    settingsSectionTitle(appText(.settingsSupportAbout, languageCode: languageCode))

                    VStack(spacing: 0) {
                        SettingsActionRow(
                            icon: "questionmark.circle",
                            title: appText(.settingsHelpSupport, languageCode: languageCode),
                            palette: palette
                        ) {
                            openURL(SettingsLinkDestination.helpSupport.url)
                        }

                        settingsDivider

                        SettingsActionRow(
                            icon: "hand.raised.fill",
                            title: appText(.settingsPrivacyPolicy, languageCode: languageCode),
                            palette: palette
                        ) {
                            openURL(SettingsLinkDestination.privacyPolicy.url)
                        }

                        settingsDivider

                        SettingsActionRow(
                            icon: "doc.text.fill",
                            title: appText(.settingsTerms, languageCode: languageCode),
                            palette: palette
                        ) {
                            openURL(SettingsLinkDestination.terms.url)
                        }
                    }
                    .background(settingsCardBackground)

                    Button {
                        showResetConfirmation = true
                    } label: {
                        Text(appText(.settingsResetData, languageCode: languageCode))
                            .font(.custom("Inter-Bold", size: 18))
                            .foregroundStyle(palette.destructive)
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(palette.destructiveBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(palette.destructive.opacity(0.45), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                .padding(.horizontal, 18)
            }
        }
        .confirmationDialog(
            appText(.settingsResetTitle, languageCode: languageCode),
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(appText(.settingsConfirmReset, languageCode: languageCode), role: .destructive) {
                resetAppData()
            }
            Button(appText(.settingsCancel, languageCode: languageCode), role: .cancel) {}
        } message: {
            Text(appText(.settingsResetMessage, languageCode: languageCode))
        }
    }

    private var settingsCardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            )
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(palette.divider)
            .frame(height: 1)
            .padding(.leading, 82)
    }

    private func settingsSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.custom("Inter-Bold", size: 17))
            .foregroundStyle(palette.secondaryText)
    }

    private func resetAppData() {
        themeSelection = AppThemeMode.dark.rawValue
        languageCode = AppLanguage.english.rawValue
        favoriteLeaguesStorage = ""
        notificationFixturesStorage = ""
        selectedCompetitionIDsStorage = BrowseCatalog.defaultCompetitionIDs.sorted().joined(separator: "|")
        MatchNotificationManager.shared.clearAll()
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let palette: AppThemePalette

    var body: some View {
        HStack(spacing: 16) {
            settingsIcon

            Text(title)
                .font(.custom("Inter-SemiBold", size: 16))
                .foregroundStyle(palette.primaryText)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(palette.accent)
        }
        .padding(.horizontal, 22)
        .frame(height: 76)
    }

    private var settingsIcon: some View {
        ZStack {
            Circle()
                .fill(palette.iconBackground)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(palette.primaryText)
        }
        .frame(width: 48, height: 48)
    }
}

private struct SettingsValueRow: View {
    let icon: String
    let title: String
    let value: String
    let palette: AppThemePalette

    var body: some View {
        HStack(spacing: 16) {
            settingsIcon

            Text(title)
                .font(.custom("Inter-SemiBold", size: 16))
                .foregroundStyle(palette.primaryText)

            Spacer()

            Text(value)
                .font(.custom("Inter-Medium", size: 15))
                .foregroundStyle(palette.secondaryText)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(palette.secondaryText)
        }
        .padding(.horizontal, 22)
        .frame(height: 76)
    }

    private var settingsIcon: some View {
        ZStack {
            Circle()
                .fill(palette.iconBackground)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(palette.primaryText)
        }
        .frame(width: 48, height: 48)
    }
}

private struct SettingsActionRow: View {
    let icon: String
    let title: String
    let palette: AppThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                settingsIcon

                Text(title)
                    .font(.custom("Inter-SemiBold", size: 16))
                    .foregroundStyle(palette.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(palette.secondaryText)
            }
            .padding(.horizontal, 22)
            .frame(height: 76)
        }
        .buttonStyle(.plain)
    }

    private var settingsIcon: some View {
        ZStack {
            Circle()
                .fill(palette.iconBackground)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(palette.primaryText)
        }
        .frame(width: 48, height: 48)
    }
}

struct TeamsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var vm = TeamsViewModel()
    @State private var selectedLeague: League = .football
    @State private var selectedTournament: FootballTournament = .premierLeague
    @State private var selectedSection = "All"
    private let sectionTabs = ["All", "Standings", "Statistics", "Injuries"]

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Text("Team Profile")
                        .font(.custom("Inter-SemiBold", size: 17))
                        .foregroundStyle(palette.primaryText)
                        .padding(.top, 14)

                    if let field = vm.teamFieldImageURL, let url = URL(string: field) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFill()
                            default: palette.iconBackground
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

                    if selectedLeague == .football {
                        FootballLeagueChips(selected: $selectedTournament)
                    }

                    if vm.isLoading {
                        ProgressView()
                            .tint(palette.primaryText)
                    } else if vm.isRefreshing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                                .tint(palette.primaryText)
                            Text("Refreshing verified team data...")
                                .font(.custom("Inter-SemiBold", size: 12))
                                .foregroundStyle(palette.secondaryText)
                        }
                    } else if let error = vm.errorText {
                        Text(LocalizedStringKey(error))
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(palette.secondaryText)
                    }

                    TeamSectionTabs(items: sectionTabs, selected: $selectedSection)

                    if selectedSection == "All" || selectedSection == "Statistics" {
                        if !vm.stats.rows.isEmpty {
                            HStack {
                                TeamCornerIcon(urlString: vm.teamBadgeURL, fallbackText: vm.teamName)
                                Spacer()
                                Text("Team Stats")
                                    .font(.custom("Inter-SemiBold", size: 20))
                                    .foregroundStyle(palette.primaryText)
                                Spacer()
                                TeamCornerIcon(urlString: vm.opponentBadgeURL, fallbackText: vm.opponentName)
                            }

                            VStack(spacing: 16) {
                                ForEach(vm.stats.rows) { row in
                                    StatRowV2(title: row.title, left: row.left, right: row.right)
                                }
                            }
                            .padding(16)
                            .background(CardBackground())
                        } else if selectedSection == "Statistics" {
                            Text("Verified team stats are not available yet")
                                .font(.custom("Inter-SemiBold", size: 13))
                                .foregroundStyle(palette.secondaryText)
                                .padding(.vertical, 12)
                        }
                    }

                    if selectedSection == "All" || selectedSection == "Standings" {
                        Text("Team Standings")
                            .font(.custom("Inter-SemiBold", size: 24))
                            .foregroundStyle(palette.primaryText)
                            .padding(.top, 12)

                        StandingsTable(rows: vm.standings)
                    }

                    if selectedSection == "Injuries" {
                        Text("Verified injury data is not available from the selected source")
                            .font(.custom("Inter-SemiBold", size: 13))
                            .foregroundStyle(palette.secondaryText)
                            .padding(.vertical, 12)
                    }

                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                await vm.load(for: selectedLeague, tournament: selectedLeague == .football ? selectedTournament : nil, force: true)
            }
        }
        .task(id: selectedLeague) {
            await vm.ensureLoaded(for: selectedLeague, tournament: selectedLeague == .football ? selectedTournament : nil)
        }
        .task(id: selectedTournament) {
            guard selectedLeague == .football else { return }
            await vm.ensureLoaded(for: selectedLeague, tournament: selectedTournament)
        }
        .onChange(of: selectedLeague) { newValue in
            if newValue == .football {
                selectedTournament = .premierLeague
            }
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
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

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
                        .foregroundStyle(palette.primaryText.opacity(0.9))
                }
                Spacer()
                Text("\(scoreLeft) : \(scoreRight)")
                    .font(.custom("Inter-SemiBold", size: 46))
                    .foregroundStyle(palette.primaryText.opacity(0.9))
                Spacer()
                VStack(spacing: 6) {
                    TeamCornerIcon(urlString: awayBadgeURL)
                    Text(awayName)
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(palette.primaryText.opacity(0.9))
                }
            }

            Text("Possession")
                .font(.custom("Inter-SemiBold", size: 11))
                .foregroundStyle(palette.secondaryText)

            HStack {
                Text("50%")
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(palette.secondaryText)
                Spacer()
                Text("50%")
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(palette.secondaryText)
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
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.custom("Inter-SemiBold", size: 12))
        }
        .foregroundStyle(palette.primaryText.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.primary.opacity(0.12)))
    }
}

private struct TeamPossessionBar: View {
    let left: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let lw = max(0, min(1, left)) * w
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.18))
                Capsule().fill(Color.primary.opacity(0.35)).frame(width: lw)
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
                        Text(LocalizedStringKey(item))
                            .font(.custom("Inter-SemiBold", size: 11))
                    }
                    .foregroundStyle(selected == item ? Color.blue : Color.secondary)
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

struct FootballLeagueChips: View {
    @Binding var selected: FootballTournament

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FootballTournament.allCases) { league in
                    Button {
                        selected = league
                    } label: {
                        Text(league.rawValue)
                            .font(.custom("Inter-SemiBold", size: 13))
                            .foregroundStyle(Color.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(selected == league ? Color.blue : Color.primary.opacity(0.06)))
                            .overlay(Capsule().stroke(Color.primary.opacity(selected == league ? 0 : 0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
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
            Text("No verified standings are available for this selection")
                .font(.custom("Inter-SemiBold", size: 12))
                .foregroundStyle(Color.secondary)
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
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.primary.opacity(0.08)))

                ForEach(rows) { row in
                    HStack {
                        Text("\(row.rank)")
                            .font(.custom("Inter-SemiBold", size: 16))
                            .foregroundStyle(Color.primary)
                            .frame(width: 16, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        CircleIcon(urlString: row.imageURL)

                        Text(row.team)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(row.record)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(Color.primary.opacity(0.9))
                            .frame(width: 44)

                        Text(row.pct)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(Color.primary.opacity(0.9))
                            .frame(width: 38)

                        Text(row.gb)
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(Color.primary.opacity(0.9))
                            .frame(width: 22)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.primary.opacity(0.05)))
                }
            }
        }
    }
}

#Preview("Shell") {
    AppShellView()
}
