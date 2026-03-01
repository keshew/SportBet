import SwiftUI
import AVKit
import SafariServices

private enum OverviewSection: String, CaseIterable, Identifiable {
    case summary = "Summary"
    case stats = "Stats"
    case lineups = "Lineups"
    case news = "News"

    var id: String { rawValue }
}

struct PlayerRoute: Hashable {
    let playerId: Int
    let playerName: String
}

struct Overview: View {
    let route: MatchRoute

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm = OverviewViewModel()
    @State private var selectedSection: OverviewSection = .summary
    @State private var showFullTimeline = false

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    OverviewTopBar(title: vm.title)

                    if vm.isRefreshing || vm.shouldAutoRefresh {
                        LiveDataStatusStrip(
                            isRefreshing: vm.isRefreshing,
                            lastUpdatedAt: vm.lastUpdatedAt,
                            autoRefreshEnabled: vm.shouldAutoRefresh,
                            palette: palette
                        )
                    }

                    if vm.isLoading {
                        ProgressView().tint(palette.primaryText)
                    } else if let error = vm.errorText {
                        Text(LocalizedStringKey(error))
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(palette.secondaryText)
                    }

                    OverviewHeroCard(
                        model: vm.hero,
                        homeScorers: vm.homeScorers,
                        awayScorers: vm.awayScorers
                    )

                    OverviewTabs(selected: $selectedSection)

                    switch selectedSection {
                    case .summary:
                        VStack(spacing: 18) {
                            if vm.hasVideo {
                                HighlightsCard(
                                    imageURL: vm.highlightImageURL,
                                    videoURL: vm.videoURL
                                )
                            }

                            if vm.isPreMatch {
                                MatchPendingCard()
                            } else {
                                if !vm.momentumBars.isEmpty {
                                    MatchMomentumCard(
                                        bars: vm.momentumBars,
                                        homeCode: vm.hero.homeName.shortTeamCode,
                                        awayCode: vm.hero.awayName.shortTeamCode,
                                        trailingLabel: vm.hero.statusText
                                    )
                                }

                                if !vm.timeline.isEmpty {
                                    TimelineSummaryCard(
                                        items: vm.timeline,
                                        homeBadgeURL: vm.hero.homeImageURL,
                                        awayBadgeURL: vm.hero.awayImageURL,
                                        showAll: $showFullTimeline
                                    )
                                }

                                if !vm.stats.rows.isEmpty {
                                    SummaryStatsCard(
                                        stats: vm.stats.rows,
                                        onSeeAll: { selectedSection = .stats }
                                    )
                                }
                            }

                            if vm.hasMatchMeta {
                                MatchMetaTiles(
                                    referee: vm.referee,
                                    attendance: vm.attendance
                                )
                            }
                        }

                    case .stats:
                        if vm.isPreMatch {
                            MatchPendingCard()
                        } else {
                            MatchStatsDetailCard(stats: vm.stats.rows)
                        }

                    case .lineups:
                        if !vm.homeLineup.isEmpty || !vm.awayLineup.isEmpty {
                            LineupsCard(
                                homeTitle: vm.hero.homeName,
                                awayTitle: vm.hero.awayName,
                                homeRows: vm.homeLineup,
                                awayRows: vm.awayLineup,
                                homeFormation: vm.homeFormation,
                                awayFormation: vm.awayFormation,
                                homeBench: vm.homeBench,
                                awayBench: vm.awayBench
                            )
                        } else {
                            EmptySection(text: "Verified lineup data is not available yet")
                        }

                    case .news:
                        MatchNewsCard(items: vm.news)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 90)
            }
            .refreshable {
                await vm.load(route: route, force: true)
            }
        }
        .task {
            await vm.loadIfNeeded(route: route)
        }
        .task(id: overviewRefreshTaskKey) {
            guard scenePhase == .active, vm.shouldAutoRefresh else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                guard !Task.isCancelled, scenePhase == .active else { return }
                await vm.refreshIfNeeded()
            }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            Task {
                await vm.refreshIfNeeded(maxAge: 10)
            }
        }
        .navigationDestination(for: PlayerRoute.self) { playerRoute in
            PlayerProfileView(route: playerRoute)
        }
        .navigationBarHidden(true)
    }

    private var overviewRefreshTaskKey: String {
        [
            String(route.fixtureId),
            vm.shouldAutoRefresh ? "live" : "idle",
            scenePhase == .active ? "active" : "inactive"
        ].joined(separator: "|")
    }
}

@MainActor
final class OverviewViewModel: ObservableObject {
    struct HeroModel {
        var league: String
        var sport: String
        var isLive: Bool
        var statusText: String
        var homeName: String
        var awayName: String
        var homeImageURL: String?
        var awayImageURL: String?
        var scoreHome: Int
        var scoreAway: Int
        var venue: String
        var referee: String
        var possessionHome: Int
        var possessionAway: Int
    }

    struct MomentumBar: Identifiable {
        let id = UUID()
        let value: Double
        let side: TimelineRow.Side
    }

    struct TimelineRow: Identifiable {
        enum Side {
            case home
            case away
            case neutral
        }

        enum Kind {
            case goal
            case yellowCard
            case redCard
            case substitution
            case other
        }

        let id = UUID()
        let minute: Int
        let minuteText: String
        let side: Side
        let kind: Kind
        let player: String
        let detail: String
        let scoreText: String?
    }

    struct LineupRow: Identifiable {
        let id = UUID()
        let playerId: Int?
        let number: String
        let name: String
        let position: String
        let formation: String
        let isSubstitute: Bool
        let imageURL: String?
    }

    private struct Snapshot {
        let title: String
        let hero: HeroModel
        let isPreMatch: Bool
        let stats: TeamStats
        let timeline: [TimelineRow]
        let homeLineup: [LineupRow]
        let awayLineup: [LineupRow]
        let homeFormation: String
        let awayFormation: String
        let homeBench: [LineupRow]
        let awayBench: [LineupRow]
        let homeScorers: [String]
        let awayScorers: [String]
        let highlightImageURL: String?
        let referee: String
        let attendance: String
        let momentumBars: [MomentumBar]
        let videoURL: String?
        let h2hMatches: [MatchRow]
        let h2hDebugInfo: String
        let news: [NewsItem]
        let previousMatches: [MatchRow]
        let nextMatches: [MatchRow]
    }

    @Published var title: String = "Match"
    @Published var hero = HeroModel(
        league: "League",
        sport: "Soccer",
        isLive: false,
        statusText: "Not Started",
        homeName: "Home",
        awayName: "Away",
        homeImageURL: nil,
        awayImageURL: nil,
        scoreHome: 0,
        scoreAway: 0,
        venue: "-",
        referee: "-",
        possessionHome: 50,
        possessionAway: 50
    )
    @Published var stats = TeamStats(rows: [])
    @Published var isPreMatch = false
    @Published var timeline: [TimelineRow] = []
    @Published var homeLineup: [LineupRow] = []
    @Published var awayLineup: [LineupRow] = []
    @Published var homeFormation: String = "-"
    @Published var awayFormation: String = "-"
    @Published var homeBench: [LineupRow] = []
    @Published var awayBench: [LineupRow] = []
    @Published var homeScorers: [String] = []
    @Published var awayScorers: [String] = []
    @Published var highlightImageURL: String?
    @Published var referee: String = "-"
    @Published var attendance: String = "-"
    @Published var momentumBars: [MomentumBar] = []
    @Published var videoURL: String?
    @Published var h2hMatches: [MatchRow] = []
    @Published var h2hDebugInfo: String = "H2H debug is empty"
    @Published var news: [NewsItem] = []
    @Published var previousMatches: [MatchRow] = []
    @Published var nextMatches: [MatchRow] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorText: String?
    @Published var lastUpdatedAt: Date?

    var hasMatchMeta: Bool {
        hasValue(referee) || hasValue(attendance)
    }

    var hasVideo: Bool {
        hasValue(videoURL ?? "")
    }

    private let service: TheSportsDBServicing
    private static var cache: [Int: Snapshot] = [:]
    private static var cacheUpdatedAt: [Int: Date] = [:]
    private var currentRoute: MatchRoute?
    private var newsTask: Task<Void, Never>?
    private var badgeTask: Task<Void, Never>?

    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func loadIfNeeded(route: MatchRoute) async {
        currentRoute = route
        if let cached = Self.cache[route.fixtureId] {
            apply(cached, updatedAt: Self.cacheUpdatedAt[route.fixtureId])
            let homeValid = isLineupValid(cached.homeLineup)
            let awayValid = isLineupValid(cached.awayLineup)
            if homeValid && awayValid {
                return
            }
            await load(route: route, force: true)
            return
        }
        await load(route: route, force: false)
    }

    func load(route: MatchRoute, force: Bool) async {
        currentRoute = route
        newsTask?.cancel()
        badgeTask?.cancel()
        if !force, let cached = Self.cache[route.fixtureId] {
            apply(cached, updatedAt: Self.cacheUpdatedAt[route.fixtureId])
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

        async let payloadTask = service.fetchOverviewPayload(fixtureId: route.fixtureId)

        hero = HeroModel(
            league: route.league,
            sport: "Soccer",
            isLive: false,
            statusText: "Not Started",
            homeName: route.homeName,
            awayName: route.awayName,
            homeImageURL: hero.homeImageURL,
            awayImageURL: hero.awayImageURL,
            scoreHome: route.homeScore ?? 0,
            scoreAway: route.awayScore ?? 0,
            venue: "-",
            referee: "-",
            possessionHome: 50,
            possessionAway: 50
        )
        title = route.league

        do {
            let payload = try await payloadTask
            let event = payload.event
            let isPreMatch = isNotStartedStatus(event.strStatus)

            let homeName = event.strHomeTeam ?? route.homeName
            let awayName = event.strAwayTeam ?? route.awayName

            let statRows = payload.stats.map {
                TeamStats.Row(
                    title: $0.strStat,
                    left: numericValue($0.strHome),
                    right: numericValue($0.strAway)
                )
            }.filter { !isPreMatch && ($0.left != 0 || $0.right != 0) }

            let possession = statRows.first(where: { $0.title == "Ball Possession" })
            let homeId = event.idHomeTeam
            let awayId = event.idAwayTeam
            let sortedLineup = payload.lineup.sorted {
                numericValue($0.intSquadNumber) < numericValue($1.intSquadNumber)
            }

            let homeAll = sortedLineup.filter { $0.idTeam == homeId }.map {
                LineupRow(
                    playerId: Int($0.idPlayer ?? ""),
                    number: $0.intSquadNumber ?? "-",
                    name: $0.strPlayer ?? "Player",
                    position: $0.strPosition ?? "-",
                    formation: normalizedFormation($0.strFormation),
                    isSubstitute: (($0.strSubstitute ?? "").lowercased() == "yes"),
                    imageURL: $0.strCutout ?? $0.strThumb
                )
            }

            let awayAll = sortedLineup.filter { $0.idTeam == awayId }.map {
                LineupRow(
                    playerId: Int($0.idPlayer ?? ""),
                    number: $0.intSquadNumber ?? "-",
                    name: $0.strPlayer ?? "Player",
                    position: $0.strPosition ?? "-",
                    formation: normalizedFormation($0.strFormation),
                    isSubstitute: (($0.strSubstitute ?? "").lowercased() == "yes"),
                    imageURL: $0.strCutout ?? $0.strThumb
                )
            }
            let homeRows = ensureUniqueByName(normalizedStartingXI(from: homeAll))
            let awayRows = ensureUniqueByName(normalizedStartingXI(from: awayAll))
            let homeFormation = homeRows.first?.formation ?? normalizedFormation(homeAll.first?.formation)
            let awayFormation = awayRows.first?.formation ?? normalizedFormation(awayAll.first?.formation)
            let homeBench = homeAll.filter(\.isSubstitute)
            let awayBench = awayAll.filter(\.isSubstitute)

            let mappedTimeline = isPreMatch ? [] : mapTimeline(
                payload.timeline,
                homeName: homeName,
                awayName: awayName
            )
            let previous = payload.previousEvents.map { toMatchRow(event: $0) }
            let next = payload.nextEvents.map { toMatchRow(event: $0) }
            let h2hSourceEvents: [TheSportsDBEvent]
            let h2hSourceLabel: String
            if !payload.h2hEvents.isEmpty {
                h2hSourceEvents = payload.h2hEvents
                h2hSourceLabel = "pairAPI"
            } else if !payload.leaguePastEvents.isEmpty {
                h2hSourceEvents = payload.leaguePastEvents
                h2hSourceLabel = "leaguePast"
            } else {
                h2hSourceEvents = payload.previousEvents
                h2hSourceLabel = "teamPrevious"
            }
            let summaryScorers = scorerColumns(from: mappedTimeline)
            let h2h = buildH2HMatches(
                from: h2hSourceEvents.map { toMatchRow(event: $0) },
                homeName: homeName,
                awayName: awayName
            )
            let h2hDebugInfo = [
                "fixture=\(route.fixtureId)",
                "home=\(homeName)",
                "away=\(awayName)",
                "pairAPI=\(payload.h2hEvents.count)",
                "leaguePast=\(payload.leaguePastEvents.count)",
                "fallbackPrevious=\(payload.previousEvents.count)",
                "sourceKind=\(h2hSourceLabel)",
                "sourceUsed=\(h2hSourceEvents.count)",
                "matched=\(h2h.count)"
            ].joined(separator: " | ")
            let heroModel = HeroModel(
                league: event.strLeague ?? route.league,
                sport: event.strSport ?? "Soccer",
                isLive: isLiveStatus(event.strStatus),
                statusText: statusText(from: event.strStatus, timeline: mappedTimeline),
                homeName: homeName,
                awayName: awayName,
                homeImageURL: hero.homeImageURL,
                awayImageURL: hero.awayImageURL,
                scoreHome: event.homeScoreInt ?? (route.homeScore ?? 0),
                scoreAway: event.awayScoreInt ?? (route.awayScore ?? 0),
                venue: event.strVenue ?? "-",
                referee: event.strOfficial ?? "-",
                possessionHome: possession?.left ?? 50,
                possessionAway: possession?.right ?? 50
            )

            let snapshot = Snapshot(
                title: event.strLeague ?? route.league,
                hero: heroModel,
                isPreMatch: isPreMatch,
                stats: TeamStats(rows: statRows, leftImageURL: hero.homeImageURL, rightImageURL: hero.awayImageURL),
                timeline: mappedTimeline,
                homeLineup: homeRows,
                awayLineup: awayRows,
                homeFormation: homeFormation,
                awayFormation: awayFormation,
                homeBench: homeBench,
                awayBench: awayBench,
                homeScorers: summaryScorers.home,
                awayScorers: summaryScorers.away,
                highlightImageURL: event.strThumb,
                referee: normalizedMetaValue(event.strOfficial),
                attendance: formattedAttendance(event.intSpectators),
                momentumBars: isPreMatch ? [] : makeMomentumBars(timeline: mappedTimeline, hero: heroModel),
                videoURL: event.strVideo,
                h2hMatches: h2h,
                h2hDebugInfo: h2hDebugInfo,
                news: [],
                previousMatches: previous,
                nextMatches: next
            )

            Self.cache[route.fixtureId] = snapshot
            let updatedAt = Date()
            Self.cacheUpdatedAt[route.fixtureId] = updatedAt
            apply(snapshot, updatedAt: updatedAt)
            startBadgeRefresh(
                fixtureId: route.fixtureId,
                homeName: homeName,
                awayName: awayName
            )
            startRelatedNewsRefresh(
                fixtureId: route.fixtureId,
                homeName: homeName,
                awayName: awayName,
                leagueName: event.strLeague ?? route.league,
                sport: event.strSport ?? "Soccer"
            )
        } catch is CancellationError {
            return
        } catch {
            if let cached = Self.cache[route.fixtureId] {
                apply(cached, updatedAt: Self.cacheUpdatedAt[route.fixtureId])
                errorText = nil
                return
            }
            errorText = "Failed to load match details."
        }
    }

    func refreshIfNeeded(maxAge: TimeInterval = 20) async {
        guard shouldAutoRefresh, let currentRoute else { return }
        if let lastUpdatedAt, Date().timeIntervalSince(lastUpdatedAt) < maxAge {
            return
        }
        await load(route: currentRoute, force: true)
    }

    var shouldAutoRefresh: Bool {
        hero.isLive
    }

    private func apply(_ snapshot: Snapshot, updatedAt: Date?) {
        title = snapshot.title
        hero = snapshot.hero
        isPreMatch = snapshot.isPreMatch
        stats = snapshot.stats
        timeline = snapshot.timeline
        homeLineup = snapshot.homeLineup
        awayLineup = snapshot.awayLineup
        homeFormation = snapshot.homeFormation
        awayFormation = snapshot.awayFormation
        homeBench = snapshot.homeBench
        awayBench = snapshot.awayBench
        homeScorers = snapshot.homeScorers
        awayScorers = snapshot.awayScorers
        highlightImageURL = snapshot.highlightImageURL
        referee = snapshot.referee
        attendance = snapshot.attendance
        momentumBars = snapshot.momentumBars
        videoURL = snapshot.videoURL
        h2hMatches = snapshot.h2hMatches
        h2hDebugInfo = snapshot.h2hDebugInfo
        news = snapshot.news
        previousMatches = snapshot.previousMatches
        nextMatches = snapshot.nextMatches
        lastUpdatedAt = updatedAt
        isLoading = false
        isRefreshing = false
    }

    private func startBadgeRefresh(
        fixtureId: Int,
        homeName: String,
        awayName: String
    ) {
        badgeTask?.cancel()
        badgeTask = Task { [service] in
            async let homeBadge = service.fetchTeamBadge(teamName: homeName)
            async let awayBadge = service.fetchTeamBadge(teamName: awayName)
            let resolvedHome = await homeBadge
            let resolvedAway = await awayBadge
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard currentRoute?.fixtureId == fixtureId else { return }
                hero.homeImageURL = resolvedHome
                hero.awayImageURL = resolvedAway
                stats = TeamStats(
                    rows: stats.rows,
                    leftImageURL: resolvedHome,
                    rightImageURL: resolvedAway
                )
                if var cached = Self.cache[fixtureId] {
                    let updatedHero = HeroModel(
                        league: cached.hero.league,
                        sport: cached.hero.sport,
                        isLive: cached.hero.isLive,
                        statusText: cached.hero.statusText,
                        homeName: cached.hero.homeName,
                        awayName: cached.hero.awayName,
                        homeImageURL: resolvedHome,
                        awayImageURL: resolvedAway,
                        scoreHome: cached.hero.scoreHome,
                        scoreAway: cached.hero.scoreAway,
                        venue: cached.hero.venue,
                        referee: cached.hero.referee,
                        possessionHome: cached.hero.possessionHome,
                        possessionAway: cached.hero.possessionAway
                    )
                    let updatedStats = TeamStats(
                        rows: cached.stats.rows,
                        leftImageURL: resolvedHome,
                        rightImageURL: resolvedAway
                    )
                    Self.cache[fixtureId] = Snapshot(
                        title: cached.title,
                        hero: updatedHero,
                        isPreMatch: cached.isPreMatch,
                        stats: updatedStats,
                        timeline: cached.timeline,
                        homeLineup: cached.homeLineup,
                        awayLineup: cached.awayLineup,
                        homeFormation: cached.homeFormation,
                        awayFormation: cached.awayFormation,
                        homeBench: cached.homeBench,
                        awayBench: cached.awayBench,
                        homeScorers: cached.homeScorers,
                        awayScorers: cached.awayScorers,
                        highlightImageURL: cached.highlightImageURL,
                        referee: cached.referee,
                        attendance: cached.attendance,
                        momentumBars: cached.momentumBars,
                        videoURL: cached.videoURL,
                        h2hMatches: cached.h2hMatches,
                        h2hDebugInfo: cached.h2hDebugInfo,
                        news: cached.news,
                        previousMatches: cached.previousMatches,
                        nextMatches: cached.nextMatches
                    )
                }
            }
        }
    }

    private func startRelatedNewsRefresh(
        fixtureId: Int,
        homeName: String,
        awayName: String,
        leagueName: String,
        sport: String
    ) {
        newsTask?.cancel()
        newsTask = Task { [service] in
            let fetchedNews = (try? await service.fetchNews(for: sport)) ?? []
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard currentRoute?.fixtureId == fixtureId else { return }
                let mappedNews = makeNews(
                    from: fetchedNews,
                    homeName: homeName,
                    awayName: awayName,
                    leagueName: leagueName,
                    sport: sport
                )
                news = mappedNews
                if var cached = Self.cache[fixtureId] {
                    Self.cache[fixtureId] = Snapshot(
                        title: cached.title,
                        hero: cached.hero,
                        isPreMatch: cached.isPreMatch,
                        stats: cached.stats,
                        timeline: cached.timeline,
                        homeLineup: cached.homeLineup,
                        awayLineup: cached.awayLineup,
                        homeFormation: cached.homeFormation,
                        awayFormation: cached.awayFormation,
                        homeBench: cached.homeBench,
                        awayBench: cached.awayBench,
                        homeScorers: cached.homeScorers,
                        awayScorers: cached.awayScorers,
                        highlightImageURL: cached.highlightImageURL,
                        referee: cached.referee,
                        attendance: cached.attendance,
                        momentumBars: cached.momentumBars,
                        videoURL: cached.videoURL,
                        h2hMatches: cached.h2hMatches,
                        h2hDebugInfo: cached.h2hDebugInfo,
                        news: mappedNews,
                        previousMatches: cached.previousMatches,
                        nextMatches: cached.nextMatches
                    )
                }
            }
        }
    }

    private var hasVisibleContent: Bool {
        hero.homeName != "Home"
            || hero.awayName != "Away"
            || !timeline.isEmpty
            || !stats.rows.isEmpty
    }

    private func toMatchRow(event: TheSportsDBEvent) -> MatchRow {
        MatchRow(
            fixtureId: Int(event.idEvent) ?? 0,
            left: TeamMini(name: sanitizedDisplayName(event.strHomeTeam, fallback: "Home")),
            right: TeamMini(name: sanitizedDisplayName(event.strAwayTeam, fallback: "Away")),
            scoreLeft: event.homeScoreInt,
            scoreRight: event.awayScoreInt,
            league: sanitizedDisplayName(event.strLeague, fallback: "League"),
            showScore: event.homeScoreInt != nil && event.awayScoreInt != nil,
            eventDate: event.dateEvent,
            eventTime: event.strTime
        )
    }

    private func mapTimeline(_ items: [TheSportsDBTimelineItem], homeName: String, awayName: String) -> [TimelineRow] {
        let mapped = items.map { item -> TimelineRow in
            let minute = minuteValue(from: item)
            let teamName = item.strTeam?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let side: TimelineRow.Side
            if !teamName.isEmpty && sameTeam(teamName, homeName) {
                side = .home
            } else if !teamName.isEmpty && sameTeam(teamName, awayName) {
                side = .away
            } else {
                side = .neutral
            }
            let kind = detectKind(item: item)
            let player = (item.strPlayer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            var detail = (item.strTimelineDetail ?? item.strEvent ?? item.strType ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if detail.lowercased().contains(" vs ") { detail = "" }
            if detail.isEmpty, let p2 = item.strPlayer2, !p2.isEmpty {
                detail = p2
            }
            return TimelineRow(
                minute: minute,
                minuteText: minute > 0 ? "\(minute)'" : "-",
                side: side,
                kind: kind,
                player: player.isEmpty ? "Event" : player,
                detail: detail,
                scoreText: nil
            )
        }.sorted { lhs, rhs in
            if lhs.minute == rhs.minute {
                return lhs.player < rhs.player
            }
            return lhs.minute < rhs.minute
        }

        var homeGoals = 0
        var awayGoals = 0
        var out: [TimelineRow] = []
        for row in mapped {
            if row.kind == .goal {
                if row.side == .home { homeGoals += 1 }
                if row.side == .away { awayGoals += 1 }
                out.append(
                    TimelineRow(
                        minute: row.minute,
                        minuteText: row.minuteText,
                        side: row.side,
                        kind: row.kind,
                        player: row.player,
                        detail: row.detail,
                        scoreText: "\(homeGoals) - \(awayGoals)"
                    )
                )
            } else {
                out.append(row)
            }
        }
        return out
    }

    private func minuteValue(from item: TheSportsDBTimelineItem) -> Int {
        if let intTime = Int(item.intTime ?? "") {
            return intTime
        }
        let raw = (item.strTime ?? item.strTimeline ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = raw.filter(\.isNumber)
        return Int(digits) ?? 0
    }

    private func detectKind(item: TheSportsDBTimelineItem) -> TimelineRow.Kind {
        let full = [
            item.strType ?? "",
            item.strEvent ?? "",
            item.strTimelineDetail ?? "",
            item.strTimeline ?? ""
        ].joined(separator: " ").lowercased()
        if full.contains("yellow") { return .yellowCard }
        if full.contains("red") { return .redCard }
        if full.contains("sub") || full.contains("replace") || full.contains("change") { return .substitution }
        if full.contains("goal") || full.contains("penalty") { return .goal }
        return .other
    }

    private func scorerColumns(from timeline: [TimelineRow]) -> (home: [String], away: [String]) {
        let goals = timeline.filter { $0.kind == .goal }
        let home = goals
            .filter { $0.side == .home }
            .prefix(2)
            .map { "\($0.minute)' \($0.player)" }
        let away = goals
            .filter { $0.side == .away }
            .prefix(2)
            .map { "\($0.minute)' \($0.player)" }
        return (Array(home), Array(away))
    }

    private func isLiveStatus(_ status: String?) -> Bool {
        let value = (status ?? "").lowercased()
        if value.contains("not started") || value == "ns" || value.contains("postponed") { return false }
        if value.contains("live") || value.contains("'") || value == "ht" || value == "1h" || value == "2h" {
            return true
        }
        return false
    }

    private func isNotStartedStatus(_ status: String?) -> Bool {
        let value = (status ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return value.isEmpty
            || value == "ns"
            || value.contains("not started")
            || value.contains("scheduled")
            || value.contains("fixture")
            || value.contains("time to be defined")
    }

    private func statusText(from status: String?, timeline: [TimelineRow]) -> String {
        let raw = (status ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.lowercased().contains("live"), let latest = timeline.map(\.minute).max(), latest > 0 {
            return "Live • \(latest)'"
        }
        if raw.isEmpty {
            return "Not Started"
        }
        return raw
    }

    private func formattedAttendance(_ raw: String?) -> String {
        guard let raw, let value = Int(raw), value > 0 else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? raw
    }

    private func normalizedMetaValue(_ raw: String?) -> String {
        let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value == "-" ? "" : value
    }

    private func hasValue(_ raw: String) -> Bool {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return !value.isEmpty && value != "-"
    }

    private func normalizedFormation(_ raw: String?) -> String {
        let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "-" : value
    }

    private func makeMomentumBars(timeline: [TimelineRow], hero: HeroModel) -> [MomentumBar] {
        var buckets = Array(repeating: 0.0, count: 8)
        var bucketSides = Array(repeating: TimelineRow.Side.neutral, count: 8)

        for item in timeline {
            let bucket = max(0, min(7, item.minute / 12))
            let weight: Double
            switch item.kind {
            case .goal: weight = 1.0
            case .substitution: weight = 0.45
            case .yellowCard: weight = 0.55
            case .redCard: weight = 0.75
            case .other: weight = 0.3
            }

            switch item.side {
            case .home:
                buckets[bucket] += weight
                bucketSides[bucket] = .home
            case .away:
                buckets[bucket] -= weight
                bucketSides[bucket] = .away
            case .neutral:
                continue
            }
        }

        if buckets.allSatisfy({ $0 == 0 }) {
            let possessionBias = Double(hero.possessionHome - hero.possessionAway) / 100.0
            buckets = [0.55, 0.8, 0.4, -0.6, -0.85, 0.75, -0.35, 0.7].map { $0 + possessionBias }
            bucketSides = buckets.map { $0 >= 0 ? .home : .away }
        }

        return buckets.enumerated().map { index, value in
            MomentumBar(
                value: max(-1, min(1, value)),
                side: bucketSides[index]
            )
        }
    }

    private func buildH2HMatches(from rows: [MatchRow], homeName: String, awayName: String) -> [MatchRow] {
        let home = canonicalName(homeName)
        let away = canonicalName(awayName)
        let filtered = rows.filter { row in
            let left = canonicalName(row.left.name)
            let right = canonicalName(row.right.name)
            return (left == home && right == away) || (left == away && right == home)
        }

        print(
            "[H2H] local-filter home=\(homeName) away=\(awayName) source=\(rows.count) matched=\(filtered.count) " +
            "events=\(filtered.map { "\($0.left.name) vs \($0.right.name)" }.joined(separator: " | "))"
        )

        return filtered
    }

    private func makeNews(
        from events: [TheSportsDBEvent],
        homeName: String,
        awayName: String,
        leagueName: String,
        sport: String
    ) -> [NewsItem] {
        let filtered = events.filter { event in
            newsMatchesTeams(event: event, homeName: homeName, awayName: awayName)
        }

        return Array(uniqueNewsEvents(filtered).prefix(8)).map {
            NewsItem(
                author: sanitizedDisplayName($0.strLeague, fallback: leagueName),
                time: $0.dateEvent ?? NSLocalizedString("Today", comment: ""),
                sport: sport,
                title: sanitizedNewsTitle($0, homeName: homeName, awayName: awayName),
                subtitle: newsSummary(
                    event: $0,
                    homeName: homeName,
                    awayName: awayName,
                    leagueName: leagueName
                ),
                imageURL: $0.strThumb,
                likes: Int($0.idEvent.suffix(2)) ?? 0,
                bookmarked: false
            )
        }
    }

    private func newsMatchesTeams(event: TheSportsDBEvent, homeName: String, awayName: String) -> Bool {
        let home = canonicalName(homeName)
        let away = canonicalName(awayName)
        let eventHome = canonicalName(event.strHomeTeam ?? "")
        let eventAway = canonicalName(event.strAwayTeam ?? "")
        let title = canonicalName(event.strEvent ?? "")

        let exactPairMatch =
            (eventHome == home && eventAway == away)
            || (eventHome == away && eventAway == home)

        let titleMatch =
            (!home.isEmpty && title.contains(home))
            || (!away.isEmpty && title.contains(away))

        return exactPairMatch || titleMatch
    }

    private func uniqueNewsEvents(_ events: [TheSportsDBEvent]) -> [TheSportsDBEvent] {
        var seen = Set<String>()
        var out: [TheSportsDBEvent] = []

        for event in events {
            let key = [
                canonicalName(event.strEvent ?? ""),
                canonicalName(event.strHomeTeam ?? ""),
                canonicalName(event.strAwayTeam ?? ""),
                event.dateEvent ?? ""
            ].joined(separator: "|")
            if seen.insert(key).inserted {
                out.append(event)
            }
        }

        return out
    }

    private func newsSummary(
        event: TheSportsDBEvent,
        homeName: String,
        awayName: String,
        leagueName: String
    ) -> String {
        let left = sanitizedDisplayName(event.strHomeTeam, fallback: homeName)
        let right = sanitizedDisplayName(event.strAwayTeam, fallback: awayName)
        let league = sanitizedDisplayName(event.strLeague, fallback: leagueName)
        return "\(left) and \(right) remain the focus as the latest \(league) storyline develops."
    }

    private func sanitizedNewsTitle(_ event: TheSportsDBEvent, homeName: String, awayName: String) -> String {
        let explicit = event.strEvent?
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !explicit.isEmpty {
            return explicit
        }

        let left = sanitizedDisplayName(event.strHomeTeam, fallback: homeName)
        let right = sanitizedDisplayName(event.strAwayTeam, fallback: awayName)
        if !left.isEmpty && !right.isEmpty {
            return "\(left) vs \(right)"
        }
        return NSLocalizedString("News", comment: "")
    }

    private func sanitizedDisplayName(_ value: String?, fallback: String) -> String {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return fallback }
        let normalized = canonicalName(trimmed)
        if ["home", "away", "team", "tbd"].contains(normalized) {
            return fallback
        }
        return trimmed
    }

    private func sameTeam(_ a: String, _ b: String) -> Bool {
        canonicalName(a) == canonicalName(b)
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

    private func normalizedStartingXI(from rows: [LineupRow]) -> [LineupRow] {
        let starters = rows.filter { !$0.isSubstitute }
        let pool = starters.isEmpty ? rows : starters
        let orderedPool = pool.sorted { lhs, rhs in
            let lGK = isGoalkeeper(lhs.position) || lhs.number == "1"
            let rGK = isGoalkeeper(rhs.position) || rhs.number == "1"
            if lGK != rGK { return lGK }
            return rank(for: lhs.position) < rank(for: rhs.position)
        }

        var unique: [LineupRow] = []
        var seen = Set<String>()
        for row in orderedPool {
            let key = canonicalName(row.name)
            if key.isEmpty || seen.contains(key) { continue }
            seen.insert(key)
            unique.append(row)
        }

        guard !unique.isEmpty else { return [] }

        let keeper = unique.first(where: { isGoalkeeper($0.position) || $0.number == "1" })
            ?? rows.first(where: { isGoalkeeper($0.position) || $0.number == "1" })
            ?? unique.first

        var out: [LineupRow] = []
        if let keeper {
            out.append(keeper)
        }

        for row in unique {
            if out.count >= 11 { break }
            let key = canonicalName(row.name)
            if out.contains(where: { canonicalName($0.name) == key }) { continue }
            out.append(row)
        }

        return Array(out.prefix(11))
    }

    private func isLineupValid(_ rows: [LineupRow]) -> Bool {
        guard rows.count <= 11, !rows.isEmpty else { return false }
        let uniqueNames = Set(rows.map { canonicalName($0.name) })
        let hasKeeper = rows.contains { isGoalkeeper($0.position) || $0.number == "1" }
        return uniqueNames.count == rows.count && hasKeeper
    }

    private func isGoalkeeper(_ position: String) -> Bool {
        let p = position.lowercased()
        return p.contains("goalkeeper") || p == "gk"
    }

    private func canonicalName(_ name: String) -> String {
        let lowered = name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        return String(lowered.filter { allowed.contains($0) })
    }

    private func ensureUniqueByName(_ rows: [LineupRow]) -> [LineupRow] {
        var seen = Set<String>()
        var out: [LineupRow] = []
        for row in rows {
            let key = canonicalName(row.name)
            if key.isEmpty || seen.contains(key) { continue }
            seen.insert(key)
            out.append(row)
            if out.count == 11 { break }
        }
        return out
    }

    private func rank(for position: String) -> Int {
        let p = position.lowercased()
        if p.contains("def") || p.contains("back") || p == "df" { return 1 }
        if p.contains("mid") || p == "mf" { return 2 }
        if p.contains("wing") || p.contains("for") || p.contains("att") || p == "fw" || p == "st" { return 3 }
        return 4
    }
}

private struct OverviewTabs: View {
    @Binding var selected: OverviewSection

    var body: some View {
        HStack(spacing: 0) {
            ForEach(OverviewSection.allCases) { item in
                Button {
                    selected = item
                } label: {
                    VStack(spacing: 12) {
                        Text(LocalizedStringKey(item.rawValue))
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(selected == item ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(selected == item ? Color.primary : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.14))
                .frame(height: 1)
        }
    }
}

private struct OverviewTopBar: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.88))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(0.04))
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Text(title)
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundStyle(Color.primary)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
        }
    }
}

private struct OverviewHeroCard: View {
    let model: OverviewViewModel.HeroModel
    let homeScorers: [String]
    let awayScorers: [String]

    var body: some View {
        VStack(spacing: 18) {
            Text(model.statusText)
                .font(.custom("Inter-Bold", size: 12))
                .foregroundStyle(Color(red: 1, green: 0.44, blue: 0.35))
                .padding(.horizontal, 18)
                .frame(height: 30)
                .background(
                    Capsule()
                        .fill(Color(red: 0.35, green: 0.1, blue: 0.08))
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.85, green: 0.24, blue: 0.19), lineWidth: 1)
                        )
                )

            HStack(alignment: .center, spacing: 18) {
                heroTeam(urlString: model.homeImageURL, name: model.homeName)

                VStack(spacing: 4) {
                    Text("\(model.scoreHome):\(model.scoreAway)")
                        .font(.custom("Inter-Bold", size: scoreFontSize))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.95))
                    Text(model.venue)
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                heroTeam(urlString: model.awayImageURL, name: model.awayName)
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(homeScorers.isEmpty ? ["NO GOALS"] : homeScorers, id: \.self) { row in
                        scorerRow(text: row, align: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(awayScorers.isEmpty ? ["NO GOALS"] : awayScorers, id: \.self) { row in
                        scorerRow(text: row, align: .trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.09, blue: 0.13),
                            Color(red: 0.07, green: 0.07, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var scoreFontSize: CGFloat {
        let sport = model.sport.lowercased()
        if sport == "basketball" || sport == "ice hockey" || sport == "hockey" {
            return 38
        }
        return 48
    }

    private func heroTeam(urlString: String?, name: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                RemoteCircleImage(urlString: urlString, systemName: "shield.fill", fallbackText: name)
            }
            .frame(width: 56, height: 56)
            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))

            Text(name)
                .font(.custom("Inter-Bold", size: 14))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 90)
        }
    }

    private func scorerRow(text: String, align: HorizontalAlignment) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "soccerball")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color(red: 0.27, green: 0.62, blue: 1))
            Text(text)
                .font(.custom("Inter-Regular", size: 11))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: align == .leading ? .leading : .trailing)
    }
}

private struct HighlightsCard: View {
    let imageURL: String?
    let videoURL: String?
    @State private var isPlaying = false
    @State private var presentSafari = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if isPlaying, let source = playbackSource, case let .direct(url) = source {
                InlineHighlightPlayer(source: source)
                    .frame(height: 186)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            isPlaying = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.black.opacity(0.7)))
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                    }
            } else {
                RemoteRectImage(urlString: imageURL, systemName: "play.rectangle.fill")
                    .frame(height: 186)
                    .clipped()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if playbackSource != nil {
                    Button {
                        switch playbackSource {
                        case .direct:
                            isPlaying = true
                        case .web:
                            presentSafari = true
                        case .none:
                            break
                        }
                    } label: {
                        playOverlay
                    }
                    .buttonStyle(.plain)
                } else {
                    playOverlay
                }

                Text("HIGHLIGHTS")
                    .font(.custom("Inter-Bold", size: 10))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.black.opacity(0.55))
                    )
                    .padding(14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .sheet(isPresented: $presentSafari) {
            if let source = playbackSource, case let .web(url) = source {
                InAppSafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    private var playbackSource: HighlightPlaybackSource? {
        HighlightPlaybackSource.make(from: videoURL)
    }

    private var playOverlay: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.16, green: 0.58, blue: 1))
                .frame(width: 54, height: 54)
            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(.leading, 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum HighlightPlaybackSource {
    case direct(URL)
    case web(URL)

    static func make(from rawValue: String?) -> HighlightPlaybackSource? {
        guard var value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        if value.contains("<iframe"), let srcRange = value.range(of: "src=\"") {
            let tail = value[srcRange.upperBound...]
            if let endQuote = tail.firstIndex(of: "\"") {
                value = String(tail[..<endQuote])
            }
        }

        if !value.lowercased().hasPrefix("http://") && !value.lowercased().hasPrefix("https://") {
            value = "https://" + value
        }

        guard let url = URL(string: value) else { return nil }
        let absolute = url.absoluteString.lowercased()
        let ext = url.pathExtension.lowercased()

        if ["mp4", "m3u8", "mov"].contains(ext) {
            return .direct(url)
        }

        if absolute.contains("youtube.com/watch"),
           let components = URLComponents(string: url.absoluteString),
           let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value,
           !videoId.isEmpty {
            return .web(URL(string: "https://www.youtube.com/watch?v=\(videoId)") ?? url)
        }

        if absolute.contains("youtu.be/") {
            let videoId = url.lastPathComponent
            if !videoId.isEmpty {
                return .web(URL(string: "https://www.youtube.com/watch?v=\(videoId)") ?? url)
            }
        }

        if absolute.contains("youtube.com/embed/") || absolute.contains("player.vimeo.com/video/") {
            return .web(url)
        }

        if absolute.contains("vimeo.com/") {
            let videoId = url.lastPathComponent
            if !videoId.isEmpty {
                return .web(URL(string: "https://vimeo.com/\(videoId)") ?? url)
            }
        }

        return .web(url)
    }
}

private struct InlineHighlightPlayer: View {
    let source: HighlightPlaybackSource

    var body: some View {
        ZStack {
            Color.black

            switch source {
            case .direct(let url):
                VideoPlayer(player: AVPlayer(url: url))
            case .web:
                Color.black
            }
        }
    }
}

private struct InAppSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        controller.preferredBarTintColor = .black
        controller.preferredControlTintColor = .white
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private struct MatchMomentumCard: View {
    let bars: [OverviewViewModel.MomentumBar]
    let homeCode: String
    let awayCode: String
    let trailingLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Match Momentum")
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundStyle(.white)
                Spacer()
                Text(homeCode)
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundStyle(.white.opacity(0.55))
                Text(awayCode)
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundStyle(.white.opacity(0.55))
            }

            HStack(alignment: .center, spacing: 6) {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(bar.side == .away ? Color(red: 0.64, green: 0.25, blue: 0.26) : Color(red: 0.21, green: 0.5, blue: 0.83))
                            .frame(height: max(18, abs(bar.value) * 54))
                            .offset(y: bar.value < 0 ? 10 : -10)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)

                    if index == 3 {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 1, height: 84)
                    }
                }
            }
            .frame(height: 84)

            HStack {
                Text("0'")
                Spacer()
                Text("HT")
                Spacer()
                Text(displayMinute)
            }
            .font(.custom("Inter-Regular", size: 11))
            .foregroundStyle(.white.opacity(0.58))
        }
        .padding(16)
        .background(overviewCardBackground)
    }

    private var displayMinute: String {
        let digits = trailingLabel.filter(\.isNumber)
        if let minute = Int(digits), minute > 0 {
            return "\(minute)'"
        }
        if trailingLabel.lowercased().contains("not started") {
            return "NS"
        }
        return trailingLabel
    }
}

private struct TimelineSummaryCard: View {
    let items: [OverviewViewModel.TimelineRow]
    let homeBadgeURL: String?
    let awayBadgeURL: String?
    @Binding var showAll: Bool

    private var visibleItems: [OverviewViewModel.TimelineRow] {
        let sorted = items.sorted { $0.minute > $1.minute }
        return showAll ? sorted : Array(sorted.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(.white)

            if visibleItems.isEmpty {
                Text("NO TIMELINE DATA")
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                VStack(spacing: 14) {
                    ForEach(visibleItems) { row in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                                Text(row.minuteText)
                                    .font(.custom("Inter-Bold", size: 12))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 44, height: 44)

                            HStack(spacing: 12) {
                                timelineKindIcon(row.kind)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title(for: row.kind))
                                        .font(.custom("Inter-Bold", size: 17))
                                        .foregroundStyle(.white)
                                    Text(detail(for: row))
                                        .font(.custom("Inter-Regular", size: 12))
                                        .foregroundStyle(.white.opacity(0.58))
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 8)

                                RemoteRectImage(
                                    urlString: row.side == .away ? awayBadgeURL : homeBadgeURL,
                                    systemName: "shield.fill"
                                )
                                .frame(width: 28, height: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }

                Button {
                    showAll.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Text(showAll ? "Show Less" : "View Full Timeline")
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showAll ? 180 : 0))
                    }
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(overviewCardBackground)
    }

    private func title(for kind: OverviewViewModel.TimelineRow.Kind) -> String {
        switch kind {
        case .goal: return "GOAL!"
        case .yellowCard: return "Yellow Card"
        case .redCard: return "Red Card"
        case .substitution: return "Substitution"
        case .other: return "Match Event"
        }
    }

    private func detail(for row: OverviewViewModel.TimelineRow) -> String {
        if row.detail.isEmpty { return row.player }
        return row.player + " • " + row.detail
    }

    private func timelineKindIcon(_ kind: OverviewViewModel.TimelineRow.Kind) -> some View {
        let color: Color
        let symbol: String
        switch kind {
        case .goal:
            color = Color.white.opacity(0.22)
            symbol = "soccerball"
        case .yellowCard:
            color = Color(red: 0.69, green: 0.54, blue: 0.08)
            symbol = "rectangle.fill"
        case .redCard:
            color = Color(red: 0.67, green: 0.22, blue: 0.2)
            symbol = "rectangle.fill"
        case .substitution:
            color = Color(red: 0.04, green: 0.34, blue: 0.67)
            symbol = "arrow.triangle.2.circlepath"
        case .other:
            color = Color.white.opacity(0.08)
            symbol = "circle.fill"
        }

        return ZStack {
            Circle()
                .fill(color)
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 34, height: 34)
    }
}

private struct SummaryStatsCard: View {
    let stats: [TeamStats.Row]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Match Stats")
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(.white)

            if primaryRows.isEmpty {
                Text("Verified match stats are not available yet")
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                VStack(spacing: 16) {
                    ForEach(primaryRows) { row in
                        SummaryStatRow(row: row)
                    }
                }

                Button(action: onSeeAll) {
                    Text("See All Stats")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(red: 0.2, green: 0.6, blue: 1).opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(overviewCardBackground)
    }

    private var primaryRows: [TeamStats.Row] {
        let priority = ["Ball Possession", "Total Shots", "Shots on Goal", "Corners", "Fouls"]
        let mapped = priority.compactMap { name in
            stats.first { $0.title.caseInsensitiveCompare(name) == .orderedSame }
        }
        return Array(mapped.prefix(3))
    }
}

private struct SummaryStatRow: View {
    let row: TeamStats.Row

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(valueText(row.left, title: row.title))
                    .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1))
                Spacer()
                Text(normalizedTitle(row.title))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(valueText(row.right, title: row.title))
                    .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.35))
            }
            .font(.custom("Inter-Regular", size: 12))

            GeometryReader { proxy in
                let total = max(1, row.left + row.right)
                let leftWidth = proxy.size.width * CGFloat(row.left) / CGFloat(total)
                let rightWidth = max(0, proxy.size.width - leftWidth)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    HStack(spacing: 0) {
                        StatFillShape(roundLeft: true)
                            .fill(Color(red: 0.2, green: 0.6, blue: 1))
                            .frame(width: leftWidth)
                        StatFillShape(roundLeft: false)
                            .fill(Color(red: 1, green: 0.35, blue: 0.35))
                            .frame(width: rightWidth)
                    }
                }
            }
            .frame(height: 6)
        }
    }

    private func normalizedTitle(_ title: String) -> String {
        switch title {
        case "Ball Possession": return "Possession"
        case "Shots on Goal": return "Shots on Target"
        default: return title
        }
    }


    private func valueText(_ value: Int, title: String) -> String {
        title == "Ball Possession" ? "\(value)%" : "\(value)"
    }
}

private struct MatchMetaTiles: View {
    let referee: String
    let attendance: String

    private var items: [(icon: String, title: String, value: String)] {
        [
            (icon: "tshirt.fill", title: "Referee", value: referee),
            (icon: "person.3.fill", title: "Attendance", value: attendance)
        ]
        .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.value != "-" }
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                metaTile(icon: item.icon, title: item.title, value: item.value)
            }
        }
    }

    private func metaTile(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text(title)
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Text(value)
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(16)
        .background(overviewCardBackground)
    }
}

private struct MatchPendingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MATCH HAS NOT STARTED")
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(Color.primary)

            Text("Statistics and timeline will appear when the match starts.")
                .font(.custom("Inter-Regular", size: 13))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(overviewCardBackground)
    }
}

private struct StatFillShape: Shape {
    let roundLeft: Bool

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.height / 2, 999)
        var path = Path()

        if roundLeft {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.minX + radius, y: rect.midY),
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: true
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: rect.midY),
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}

private struct MatchStatsDetailCard: View {
    let stats: [TeamStats.Row]

    private var orderedRows: [TeamStats.Row] {
        let priority = [
            "Ball Possession",
            "Total Shots",
            "Shots on Goal",
            "Corners",
            "Fouls",
            "Yellow Cards",
            "Offsides"
        ]

        let preferred = priority.compactMap { name in
            stats.first { normalizedKey($0.title) == normalizedKey(name) }
        }

        let extra = stats.filter { row in
            !priority.contains { normalizedKey($0) == normalizedKey(row.title) }
        }

        return preferred + extra
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Team Statistics")
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundStyle(.white)

                Spacer()

                Text("All Stats")
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundStyle(Color(red: 0.18, green: 0.58, blue: 1))
            }

            if orderedRows.isEmpty {
                EmptySection(text: "Verified match stats are not available yet")
            } else {
                VStack(spacing: 14) {
                    ForEach(orderedRows) { row in
                        DetailStatMetricCard(row: row)
                    }
                }
            }
        }
    }

    private func normalizedKey(_ title: String) -> String {
        title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DetailStatMetricCard: View {
    let row: TeamStats.Row

    private var isCardMetric: Bool {
        normalizedTitle == "Yellow Cards"
    }

    private var total: Int {
        max(1, row.left + row.right)
    }

    private var leftRatio: CGFloat {
        CGFloat(row.left) / CGFloat(total)
    }

    private var rightRatio: CGFloat {
        CGFloat(row.right) / CGFloat(total)
    }

    private var leftLeads: Bool {
        row.left >= row.right
    }

    var body: some View {
        VStack(spacing: isCardMetric ? 22 : 24) {
            ZStack {
                Text(normalizedTitle)
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack {
                    Text(valueText(row.left))
                        .font(.custom("Inter-Bold", size: 12))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(valueText(row.right))
                        .font(.custom("Inter-Bold", size: 12))
                        .foregroundStyle(.white)
                }
            }

            if isCardMetric {
                HStack(spacing: 8) {
                    ForEach(0..<min(12, row.left + row.right), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color(red: 0.97, green: 0.8, blue: 0.12))
                            .frame(width: 16, height: 28)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let leadingWidth = width * leftRatio
                    let trailingWidth = width * rightRatio

                    VStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .fill(Color.white.opacity(0.07))

                            if leftLeads {
                                HStack(spacing: 0) {
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .fill(Color(red: 0.18, green: 0.58, blue: 1))
                                        .frame(width: max(8, leadingWidth), height: 3)
                                    Spacer(minLength: 0)
                                }
                            } else {
                                HStack(spacing: 0) {
                                    Spacer(minLength: 0)
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .fill(Color.white.opacity(0.52))
                                        .frame(width: max(8, trailingWidth), height: 3)
                                }
                            }
                        }
                        .frame(height: 8)

                        Spacer(minLength: 0)
                    }
                }
                .frame(height: 20, alignment: .top)
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 28)
        .padding(.bottom, 26)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.09, blue: 0.13),
                            Color(red: 0.07, green: 0.07, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var normalizedTitle: String {
        switch row.title {
        case "Ball Possession":
            return "Possession"
        case "Shots on Goal":
            return "Shots on Target"
        default:
            return row.title
        }
    }

    private func valueText(_ value: Int) -> String {
        row.title == "Ball Possession" ? "\(value)%" : "\(value)"
    }
}

private struct HeadToHeadCard: View {
    let homeName: String
    let awayName: String
    let rows: [MatchRow]

    private var summary: (homeWins: Int, draws: Int, awayWins: Int, homeGoals: Int, totalMatches: Int, awayGoals: Int) {
        var homeWins = 0
        var draws = 0
        var awayWins = 0
        var homeGoals = 0
        var awayGoals = 0

        for row in rows {
            let result = resultForCurrentTeams(row)
            switch result.outcome {
            case .win: homeWins += 1
            case .draw: draws += 1
            case .loss: awayWins += 1
            }
            homeGoals += result.homeGoals
            awayGoals += result.awayGoals
        }

        return (homeWins, draws, awayWins, homeGoals, rows.count, awayGoals)
    }

    private var homeVsAway: (homeRecord: String, awayRecord: String, homeProgress: CGFloat, awayProgress: CGFloat) {
        let homeHosted = rows.filter { normalize($0.left.name) == normalize(homeName) }
        let awayHosted = rows.filter { normalize($0.left.name) == normalize(awayName) }

        let homeRecordTuple = recordTuple(for: homeHosted, favoredTeam: homeName)
        let awayRecordTuple = recordTuple(for: awayHosted, favoredTeam: awayName)

        let homeTotal = max(1, homeRecordTuple.win + homeRecordTuple.draw + homeRecordTuple.loss)
        let awayTotal = max(1, awayRecordTuple.win + awayRecordTuple.draw + awayRecordTuple.loss)

        return (
            "\(homeRecordTuple.win)-\(homeRecordTuple.draw)-\(homeRecordTuple.loss)",
            "\(awayRecordTuple.win)-\(awayRecordTuple.draw)-\(awayRecordTuple.loss)",
            CGFloat(homeRecordTuple.win) / CGFloat(homeTotal),
            CGFloat(awayRecordTuple.win) / CGFloat(awayTotal)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Head to Head")
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(.white)

            if rows.isEmpty {
                Text("NO H2H DATA")
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                metricsCard(
                    left: ("\(summary.homeWins)", "\(homeName) Wins", Color(red: 0.18, green: 0.58, blue: 1)),
                    center: ("\(summary.draws)", "Draws", .white),
                    right: ("\(summary.awayWins)", "\(awayName) Wins", .white)
                )

                metricsCard(
                    left: ("\(summary.homeGoals)", "Goals For", .white),
                    center: ("\(summary.totalMatches)", "Total Matches", .white),
                    right: ("\(summary.awayGoals)", "Goals For", .white)
                )

                Text("Recent Matches")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(spacing: 12) {
                    ForEach(rows.prefix(5)) { row in
                        NavigationLink(
                            value: MatchRoute(
                                fixtureId: row.fixtureId,
                                league: row.league,
                                homeName: row.left.name,
                                awayName: row.right.name,
                                homeScore: row.scoreLeft,
                                awayScore: row.scoreRight
                            )
                        ) {
                            recentMatchCard(row)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Home vs Away")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundStyle(.white.opacity(0.9))

                    homeAwayRow(title: "\(homeName) (Home)", record: homeVsAway.homeRecord, progress: homeVsAway.homeProgress, tint: Color(red: 0.18, green: 0.58, blue: 1))
                    homeAwayRow(title: "\(awayName) (Away)", record: homeVsAway.awayRecord, progress: homeVsAway.awayProgress, tint: Color.white.opacity(0.42))
                }
                .padding(18)
                .background(overviewCardBackground)
            }
        }
    }

    private func metricsCard(
        left: (value: String, title: String, tint: Color),
        center: (value: String, title: String, tint: Color),
        right: (value: String, title: String, tint: Color)
    ) -> some View {
        HStack(spacing: 0) {
            h2hMetric(value: left.value, title: left.title, tint: left.tint)
            metricDivider
            h2hMetric(value: center.value, title: center.title, tint: center.tint)
            metricDivider
            h2hMetric(value: right.value, title: right.title, tint: right.tint)
        }
        .padding(.vertical, 18)
        .background(overviewCardBackground)
    }

    private func h2hMetric(value: String, title: String, tint: Color) -> some View {
        VStack(spacing: 10) {
            Text(value)
                .font(.custom("Inter-Bold", size: 24))
                .foregroundStyle(tint)
            Text(title)
                .font(.custom("Inter-Regular", size: 13))
                .foregroundStyle(.white.opacity(0.58))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 68)
    }

    private func recentMatchCard(_ row: MatchRow) -> some View {
        let result = resultForCurrentTeams(row)
        return VStack(alignment: .leading, spacing: 16) {
            Text(matchDateText(for: row))
                .font(.custom("Inter-Regular", size: 12))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 10) {
                rowTeam(team: row.left, isLeading: true)

                Spacer()

                Text(scoreText(for: row))
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundStyle(.white)

                Spacer()

                rowTeam(team: row.right, isLeading: false)
            }

            Text(result.outcome.symbol)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundStyle(result.outcome.color)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(overviewCardBackground)
    }

    private func rowTeam(team: TeamMini, isLeading: Bool) -> some View {
        HStack(spacing: 8) {
            if isLeading {
                teamBadge(urlString: team.imageURL)
            }

            Text(team.name)
                .font(.custom("Inter-Bold", size: 15))
                .foregroundStyle(.white)
                .lineLimit(1)

            if !isLeading {
                teamBadge(urlString: team.imageURL)
            }
        }
        .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .trailing)
    }

    private func teamBadge(urlString: String?) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.06))

            RemoteCircleImage(urlString: urlString, systemName: "shield.fill")
                .padding(6)
        }
        .frame(width: 26, height: 26)
    }

    private func homeAwayRow(title: String, record: String, progress: CGFloat, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundStyle(.white.opacity(0.82))
                Spacer()
                Text(record)
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundStyle(tint)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(tint)
                        .frame(width: proxy.size.width * max(0.12, progress))
                }
            }
            .frame(height: 6)
        }
    }

    private func resultForCurrentTeams(_ row: MatchRow) -> (homeGoals: Int, awayGoals: Int, outcome: HeadToHeadOutcome) {
        let leftName = normalize(row.left.name)
        let rightName = normalize(row.right.name)
        let leftScore = row.scoreLeft ?? 0
        let rightScore = row.scoreRight ?? 0

        if leftName == normalize(homeName) && rightName == normalize(awayName) {
            return (
                leftScore,
                rightScore,
                outcomeFor(homeScore: leftScore, awayScore: rightScore)
            )
        }

        if leftName == normalize(awayName) && rightName == normalize(homeName) {
            return (
                rightScore,
                leftScore,
                outcomeFor(homeScore: rightScore, awayScore: leftScore)
            )
        }

        return (leftScore, rightScore, .draw)
    }

    private func outcomeFor(homeScore: Int, awayScore: Int) -> HeadToHeadOutcome {
        if homeScore > awayScore { return .win }
        if homeScore < awayScore { return .loss }
        return .draw
    }

    private func recordTuple(for rows: [MatchRow], favoredTeam: String) -> (win: Int, draw: Int, loss: Int) {
        var wins = 0
        var draws = 0
        var losses = 0

        for row in rows {
            let favoredIsLeft = normalize(row.left.name) == normalize(favoredTeam)
            let left = row.scoreLeft ?? 0
            let right = row.scoreRight ?? 0

            if left == right {
                draws += 1
            } else if (favoredIsLeft && left > right) || (!favoredIsLeft && right > left) {
                wins += 1
            } else {
                losses += 1
            }
        }

        return (wins, draws, losses)
    }

    private func scoreText(for row: MatchRow) -> String {
        guard let left = row.scoreLeft, let right = row.scoreRight else { return "- - -" }
        return "\(left) - \(right)"
    }

    private func matchDateText(for row: MatchRow) -> String {
        if let raw = row.eventDate, let date = isoDate(from: raw) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            return "\(formatter.string(from: date)) • \(row.league)"
        }
        return row.league
    }

    private func isoDate(from raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }

    private func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum HeadToHeadOutcome {
    case win
    case draw
    case loss

    var symbol: String {
        switch self {
        case .win: return "W"
        case .draw: return "D"
        case .loss: return "L"
        }
    }

    var color: Color {
        switch self {
        case .win: return Color(red: 0.18, green: 0.58, blue: 1)
        case .draw: return .white.opacity(0.72)
        case .loss: return Color(red: 1, green: 0.35, blue: 0.35)
        }
    }
}

private struct MatchNewsCard: View {
    let items: [NewsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Related News")
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundStyle(.white)

                Spacer()

                Button {} label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.84))
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(true)
                .opacity(0.9)
            }

            if items.isEmpty {
                EmptySection(text: "No verified related updates for these teams yet")
            } else {
                ForEach(items) { item in
                    RelatedNewsCard(item: item)
                }
            }
        }
    }
}

private struct RelatedNewsCard: View {
    let item: NewsItem

    private var route: NewsRoute {
        NewsRoute(
            title: item.title,
            subtitle: item.subtitle,
            author: item.author,
            time: item.time,
            imageURL: item.imageURL,
            body: item.body,
            sport: item.sport,
            league: item.league
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteRectImage(urlString: item.imageURL, systemName: "photo")
                .frame(height: 156)
                .clipped()
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Text(tagText)
                        .font(.custom("Inter-Bold", size: 11))
                        .foregroundStyle(tagColor)

                    Text("•")
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundStyle(Color.secondary.opacity(0.7))

                    Text("\(item.author) • \(relativeTimeText)")
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundStyle(Color.secondary)
                }

                Text(item.title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)

                Text(item.subtitle)
                    .font(.custom("Inter-Regular", size: 13))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(3)

                HStack {
                    ShareLink(
                        item: "\(item.title)\n\n\(item.subtitle)",
                        preview: SharePreview(item.title)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.primary.opacity(0.05)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    NavigationLink(value: route) {
                        HStack(spacing: 6) {
                            Text("Read more")
                                .font(.custom("Inter-Medium", size: 12))
                                .foregroundStyle(Color(red: 0.18, green: 0.58, blue: 1))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(red: 0.18, green: 0.58, blue: 1))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var tagText: String {
        switch item.likes % 3 {
        case 0: return "Breaking"
        case 1: return "Analysis"
        default: return "Update"
        }
    }

    private var tagColor: Color {
        switch item.likes % 3 {
        case 0: return Color(red: 1, green: 0.24, blue: 0.24)
        case 1: return Color(red: 0.21, green: 0.88, blue: 0.34)
        default: return Color(red: 0.18, green: 0.58, blue: 1)
        }
    }

    private var relativeTimeText: String {
        if item.time.count >= 10 {
            return NSLocalizedString("5 mins ago", comment: "")
        }
        return item.time
    }
}

private var overviewCardBackground: some View {
    RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.06),
                    Color.primary.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
}

private extension String {
    var shortTeamCode: String {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "---" }

        let parts = cleaned
            .split(separator: " ")
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            let joined = parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
            return joined.uppercased()
        }

        return String(cleaned.prefix(3)).uppercased()
    }
}

private struct TimelineCard: View {
    let items: [OverviewViewModel.TimelineRow]
    var body: some View {
        VStack(spacing: 8) {
            let firstHalf = items.filter { $0.minute <= 45 }
            let secondHalf = items.filter { $0.minute > 45 }

            timelineHalf(title: "1ST HALF", rows: firstHalf)
            timelineHalf(title: "2ND HALF", rows: secondHalf)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
        )
    }

    private func timelineHalf(title: String, rows: [OverviewViewModel.TimelineRow]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(Color.black.opacity(0.7))
                Spacer()
                Text(halfScoreText(rows))
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(Color.black.opacity(0.7))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.08))

            VStack(spacing: 0) {
                ForEach(rows) { row in
                    HStack(alignment: .center) {
                        sideEvent(row: row, side: .home)
                        Spacer(minLength: 8)
                        sideEvent(row: row, side: .away)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color.white)
                }
            }
        }
    }

    private func sideEvent(row: OverviewViewModel.TimelineRow, side: OverviewViewModel.TimelineRow.Side) -> some View {
        let visible = row.side == side || row.side == .neutral
        return HStack(spacing: 6) {
            if visible {
                Text(row.minuteText)
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(Color.black.opacity(0.75))
                    .frame(width: 32, alignment: .leading)

                icon(for: row.kind)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(row.player)
                            .font(.custom("Inter-SemiBold", size: 13))
                            .foregroundStyle(Color.black.opacity(0.85))
                            .lineLimit(1)
                        if let score = row.scoreText {
                            Text(score)
                                .font(.custom("Inter-SemiBold", size: 12))
                                .foregroundStyle(Color.black.opacity(0.85))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(Color.black.opacity(0.06))
                                )
                        }
                    }
                    if !row.detail.isEmpty {
                        Text(row.detail)
                            .font(.custom("Inter-SemiBold", size: 11))
                            .foregroundStyle(Color.black.opacity(0.55))
                            .lineLimit(1)
                    }
                }
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: side == .home ? .leading : .trailing)
    }

    private func icon(for kind: OverviewViewModel.TimelineRow.Kind) -> some View {
        let iconName: String
        let color: Color
        switch kind {
        case .goal:
            iconName = "soccerball"
            color = .black.opacity(0.75)
        case .yellowCard:
            iconName = "rectangle.fill"
            color = .yellow
        case .redCard:
            iconName = "rectangle.fill"
            color = .red
        case .substitution:
            iconName = "arrow.triangle.2.circlepath"
            color = .green
        case .other:
            iconName = "circle.fill"
            color = .gray
        }
        return Image(systemName: iconName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 16)
    }

    private func halfScoreText(_ rows: [OverviewViewModel.TimelineRow]) -> String {
        let homeGoals = rows.filter { $0.kind == .goal && $0.side == .home }.count
        let awayGoals = rows.filter { $0.kind == .goal && $0.side == .away }.count
        return "\(homeGoals) - \(awayGoals)"
    }
}

private struct LineupsCard: View {
    let homeTitle: String
    let awayTitle: String
    let homeRows: [OverviewViewModel.LineupRow]
    let awayRows: [OverviewViewModel.LineupRow]
    let homeFormation: String
    let awayFormation: String
    let homeBench: [OverviewViewModel.LineupRow]
    let awayBench: [OverviewViewModel.LineupRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lineups")
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(.white)

            TeamLineupCard(
                title: homeTitle,
                formation: homeFormation,
                rows: homeRows,
                accent: Color(red: 0.16, green: 0.58, blue: 1),
                numberColor: .white,
                fallbackRows: homeBench
            )

            TeamLineupCard(
                title: awayTitle,
                formation: awayFormation,
                rows: awayRows,
                accent: Color.white.opacity(0.82),
                numberColor: Color.black.opacity(0.82),
                fallbackRows: awayBench
            )
        }
    }
}

private struct TeamLineupCard: View {
    let title: String
    let formation: String
    let rows: [OverviewViewModel.LineupRow]
    let accent: Color
    let numberColor: Color
    let fallbackRows: [OverviewViewModel.LineupRow]

    private var starters: [OverviewViewModel.LineupRow] {
        let source = rows.isEmpty ? fallbackRows : rows
        return Array(uniqueRowsByName(source).prefix(11))
    }

    private var groupedLines: [[OverviewViewModel.LineupRow]] {
        grouped(rows: starters)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                        Image(systemName: "shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 36, height: 36)

                    Text(title)
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundStyle(.white)
                }

                Spacer()

                if formation != "-" && !formation.isEmpty {
                    Text(formation)
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.08, green: 0.2, blue: 0.14),
                                Color(red: 0.05, green: 0.13, blue: 0.1)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 220
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.green.opacity(0.28), lineWidth: 1)
                    )

                VStack(spacing: 20) {
                    ForEach(Array(groupedLines.enumerated()), id: \.offset) { _, line in
                        HStack(spacing: 8) {
                            ForEach(line) { row in
                                NavigationLink(value: PlayerRoute(playerId: row.playerId ?? 0, playerName: row.name)) {
                                    lineupMarker(row: row)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .frame(height: 360)
        }
        .padding(16)
        .background(overviewCardBackground)
    }

    private func grouped(rows: [OverviewViewModel.LineupRow]) -> [[OverviewViewModel.LineupRow]] {
        let starters = Array(uniqueRowsByName(rows).prefix(11))
        if starters.isEmpty { return [] }

        let gk = starters.first(where: { isMatch($0.position, keys: ["gk", "goalkeeper"]) || $0.number == "1" }) ?? starters[0]
        let rest = starters.filter { canonicalName($0.name) != canonicalName(gk.name) }

        let defenders = rest.filter { isMatch($0.position, keys: ["df", "def", "back"]) }
        let midfielders = rest.filter { isMatch($0.position, keys: ["mf", "mid"]) }
        let forwards = rest.filter { isMatch($0.position, keys: ["fw", "st", "att", "wing", "for"]) }
        let used = Set(defenders.map(\.id) + midfielders.map(\.id) + forwards.map(\.id))
        let others = rest.filter { !used.contains($0.id) }

        var queue = defenders + midfielders + forwards + others

        func pop(_ count: Int) -> [OverviewViewModel.LineupRow] {
            guard !queue.isEmpty else { return [] }
            let takeCount = min(count, queue.count)
            let chunk = Array(queue.prefix(takeCount))
            queue.removeFirst(takeCount)
            return chunk
        }

        let defLine = pop(4)
        let midLine = pop(3)
        let fwdLine = pop(3)

        var lines: [[OverviewViewModel.LineupRow]] = [[gk]]
        if !defLine.isEmpty { lines.append(defLine) }
        if !midLine.isEmpty { lines.append(midLine) }
        if !fwdLine.isEmpty { lines.append(fwdLine) }
        return lines
    }

    private func lineupMarker(row: OverviewViewModel.LineupRow) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.95))

                if let urlString = row.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "person.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(numberColor)
                        }
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(numberColor)
                }
            }
            .frame(width: 46, height: 46)
            .clipShape(Circle())

            Text(shortName(from: row.name))
                .font(.custom("Inter-Medium", size: 11))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 64)
        }
        .frame(maxWidth: .infinity)
    }

    private func isMatch(_ position: String, keys: [String]) -> Bool {
        let p = position.lowercased()
        return keys.contains { p.contains($0) }
    }

    private func canonicalName(_ name: String) -> String {
        let lowered = name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        return String(lowered.filter { allowed.contains($0) })
    }

    private func uniqueRowsByName(_ rows: [OverviewViewModel.LineupRow]) -> [OverviewViewModel.LineupRow] {
        var seen = Set<String>()
        var out: [OverviewViewModel.LineupRow] = []
        for row in rows {
            let key = canonicalName(row.name)
            if key.isEmpty || seen.contains(key) { continue }
            seen.insert(key)
            out.append(row)
            if out.count == 11 { break }
        }
        return out
    }

    private func shortName(from fullName: String) -> String {
        let parts = fullName.split(separator: " ")
        guard parts.count > 1 else { return fullName }
        return String(parts.last ?? "")
    }
}

private struct PitchLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 8, height: 8))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addEllipse(in: CGRect(x: rect.midX - 34, y: rect.midY - 34, width: 68, height: 68))
        path.addRect(CGRect(x: rect.midX - 70, y: rect.minY, width: 140, height: 70))
        path.addRect(CGRect(x: rect.midX - 70, y: rect.maxY - 70, width: 140, height: 70))
        return path
    }
}

private struct ScheduleCard: View {
    let previous: [MatchRow]
    let next: [MatchRow]

    var body: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "Previous 10")
            if previous.isEmpty {
                EmptySection(text: "No verified previous matches found")
            } else {
                VStack(spacing: 8) {
                    ForEach(previous) { row in
                        NavigationLink(value: route(from: row)) {
                            MatchCard(match: row)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SectionHeader(title: "Next 10")
            if next.isEmpty {
                EmptySection(text: "No verified upcoming matches found")
            } else {
                VStack(spacing: 8) {
                    ForEach(next) { row in
                        NavigationLink(value: route(from: row)) {
                            MatchCard(match: row)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func route(from row: MatchRow) -> MatchRoute {
        MatchRoute(
            fixtureId: row.fixtureId,
            league: row.league,
            homeName: row.left.name,
            awayName: row.right.name,
            homeScore: row.scoreLeft,
            awayScore: row.scoreRight
        )
    }
}

private struct MetaCard: View {
    let venue: String
    let dateText: String
    let status: String
    let videoURL: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(venue)
                .font(.custom("Inter-SemiBold", size: 13))
                .foregroundStyle(.white.opacity(0.85))
            Text(dateText)
                .font(.custom("Inter-SemiBold", size: 13))
                .foregroundStyle(.white.opacity(0.75))
            Text(status)
                .font(.custom("Inter-SemiBold", size: 13))
                .foregroundStyle(.white.opacity(0.75))

            if let videoURL, !videoURL.isEmpty, let url = URL(string: videoURL) {
                Link(destination: url) {
                    Text("Watch Highlights")
                        .font(.custom("Inter-SemiBold", size: 13))
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(CardBackground())
    }
}

private struct EmptySection: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Inter-SemiBold", size: 12))
            .foregroundStyle(.white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(CardBackground())
    }
}

@MainActor
final class PlayerProfileViewModel: ObservableObject {
    @Published var name = "Player"
    @Published var team = "-"
    @Published var position = "-"
    @Published var nationality = "-"
    @Published var born = "-"
    @Published var description = ""
    @Published var imageURL: String?
    @Published var honours: [String] = []
    @Published var milestones: [String] = []
    @Published var isLoading = false
    @Published var errorText: String?

    private let service: TheSportsDBServicing

    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func load(playerId: Int, fallbackName: String) async {
        isLoading = true
        errorText = nil
        if name == "Player" {
            name = fallbackName
        }
        defer { isLoading = false }

        if playerId <= 0 {
            do {
                let payload = try await service.fetchPlayer(playerName: fallbackName)
                name = payload.player.strPlayer ?? fallbackName
                team = payload.player.strTeam ?? "-"
                position = payload.player.strPosition ?? "-"
                nationality = payload.player.strNationality ?? "-"
                born = payload.player.dateBorn ?? "-"
                description = payload.player.strDescriptionEN ?? ""
                imageURL = payload.player.strThumb ?? payload.player.strCutout
                honours = payload.honours.compactMap {
                    if let h = $0.strHonour, let s = $0.strSeason, !h.isEmpty {
                        return "\(h) (\(s))"
                    }
                    return $0.strHonour
                }
                milestones = payload.milestones.compactMap {
                    if let m = $0.strMilestone, let s = $0.strSeason, !m.isEmpty {
                        return "\(m) (\(s))"
                    }
                    return $0.strMilestone
                }
                return
            } catch {
                errorText = "Failed to load player."
                return
            }
        }

        do {
            let payload = try await service.fetchPlayer(playerId: playerId)
            name = payload.player.strPlayer ?? "Player"
            team = payload.player.strTeam ?? "-"
            position = payload.player.strPosition ?? "-"
            nationality = payload.player.strNationality ?? "-"
            born = payload.player.dateBorn ?? "-"
            description = payload.player.strDescriptionEN ?? ""
            imageURL = payload.player.strThumb ?? payload.player.strCutout
            honours = payload.honours.compactMap {
                if let h = $0.strHonour, let s = $0.strSeason, !h.isEmpty {
                    return "\(h) (\(s))"
                }
                return $0.strHonour
            }
            milestones = payload.milestones.compactMap {
                if let m = $0.strMilestone, let s = $0.strSeason, !m.isEmpty {
                    return "\(m) (\(s))"
                }
                return $0.strMilestone
            }
        } catch {
            if !name.isEmpty, name != "Player" {
                do {
                    let payload = try await service.fetchPlayer(playerName: name)
                    name = payload.player.strPlayer ?? name
                    team = payload.player.strTeam ?? "-"
                    position = payload.player.strPosition ?? "-"
                    nationality = payload.player.strNationality ?? "-"
                    born = payload.player.dateBorn ?? "-"
                    description = payload.player.strDescriptionEN ?? ""
                    imageURL = payload.player.strThumb ?? payload.player.strCutout
                    honours = payload.honours.compactMap {
                        if let h = $0.strHonour, let s = $0.strSeason, !h.isEmpty {
                            return "\(h) (\(s))"
                        }
                        return $0.strHonour
                    }
                    milestones = payload.milestones.compactMap {
                        if let m = $0.strMilestone, let s = $0.strSeason, !m.isEmpty {
                            return "\(m) (\(s))"
                        }
                        return $0.strMilestone
                    }
                    return
                } catch { }
            }
            errorText = "Failed to load player."
        }
    }
}

struct PlayerProfileView: View {
    let route: PlayerRoute
    @StateObject private var vm = PlayerProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    playerTopBar

                    if vm.isLoading {
                        ProgressView().tint(Color.primary)
                    } else if let error = vm.errorText {
                        Text(LocalizedStringKey(error))
                            .font(.custom("Inter-SemiBold", size: 12))
                            .foregroundStyle(Color.secondary)
                    }

                    playerHeroCard
                    playerInfoCard

                    if !vm.honours.isEmpty {
                        playerFactsCard(title: "Honours", items: vm.honours)
                    }

                    if !vm.milestones.isEmpty {
                        playerFactsCard(title: "Milestones", items: vm.milestones)
                    }

                    if !vm.description.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Bio")
                                .font(.custom("Inter-Bold", size: 18))
                                .foregroundStyle(Color.primary)
                            Text(vm.description)
                                .font(.custom("Inter-Regular", size: 13))
                                .foregroundStyle(Color.secondary)
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .background(overviewCardBackground)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 90)
            }
        }
        .task {
            await vm.load(playerId: route.playerId, fallbackName: route.playerName)
        }
        .navigationBarHidden(true)
    }

    private var playerTopBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.primary.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.04))
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Player Profile")
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(Color.primary)

            Spacer()

            ShareLink(
                item: "\(vm.name) • \(vm.position) • \(vm.team)",
                preview: SharePreview(vm.name)
            ) {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.primary.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.04))
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
    }

    private var playerHeroCard: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.03))
                    Circle()
                        .stroke(Color(red: 0.18, green: 0.58, blue: 1).opacity(0.6), lineWidth: 2)
                    RemoteCircleImage(urlString: vm.imageURL, systemName: "person.fill")
                        .padding(8)
                }
                .frame(width: 86, height: 86)

                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.name)
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)

                    HStack(spacing: 20) {
                        Text(vm.position)
                        Text(vm.team)
                    }
                    .font(.custom("Inter-Regular", size: 13))
                    .foregroundStyle(Color.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                playerMetric(value: safeValue(vm.nationality), title: "Nationality", tint: .white)
                playerMetric(value: safeValue(vm.born), title: "Born", tint: Color(red: 0.34, green: 1, blue: 0.24))
                playerMetric(value: "\(vm.honours.count)", title: "Honours", tint: Color(red: 0.18, green: 0.58, blue: 1))
            }
        }
        .padding(16)
        .background(overviewCardBackground)
    }

    private var playerInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Player Details")
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(Color.primary)

            VStack(spacing: 12) {
                playerInfoRow(title: "Team", value: vm.team)
                playerInfoRow(title: "Position", value: vm.position)
                playerInfoRow(title: "Nationality", value: vm.nationality)
                playerInfoRow(title: "Born", value: vm.born)
            }
        }
        .padding(16)
        .background(overviewCardBackground)
    }

    private func playerMetric(value: String, title: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.custom("Inter-Bold", size: 16))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.custom("Inter-Regular", size: 12))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func playerInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.custom("Inter-Medium", size: 13))
                .foregroundStyle(Color.secondary)

            Spacer()

            Text(safeValue(value))
                .font(.custom("Inter-SemiBold", size: 14))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func playerFactsCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Inter-Bold", size: 18))
                .foregroundStyle(Color.primary)

            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.custom("Inter-Regular", size: 13))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
            }
        }
        .padding(16)
        .background(overviewCardBackground)
    }

    private func safeValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "-" ? "Unknown" : trimmed
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
