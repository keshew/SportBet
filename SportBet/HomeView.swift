import SwiftUI
import UserNotifications

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
    let body: String
    let sport: String
    let league: String
}

@MainActor
final class HomeViewModel: ObservableObject {
    private let maxLoadAttempts = 3

    private struct Snapshot {
        let featured: FeaturedScore
        let todays: [MatchRow]
        let recent: [MatchRow]
        let stats: TeamStats
        let news: [NewsItem]
        let errorText: String?
    }

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
    @Published var isRefreshing = false
    @Published var errorText: String?
    @Published var lastUpdatedAt: Date?

    private let service: TheSportsDBServicing
    private var loadedKeys = Set<String>()
    private var cachedSnapshots: [String: Snapshot] = [:]
    private var cachedSignatures: [String: String] = [:]
    private var cachedUpdatedAt: [String: Date] = [:]
    private var currentLeague: League = .football
    private var currentCacheKey = ""
    private var currentCompetitionIDs = Set<String>()

    init(service: TheSportsDBServicing = LiveTheSportsDBService.shared) {
        self.service = service
    }

    func load(competitionIDs: Set<String> = []) async {
        let initialCompetitionIDs = relevantCompetitionIDs(for: .football, from: competitionIDs)
        currentLeague = .football
        currentCompetitionIDs = initialCompetitionIDs
        currentCacheKey = cacheKey(for: .football, tournament: nil, competitionIDs: initialCompetitionIDs)
        await ensureLoaded(for: .football, tournament: nil, competitionIDs: initialCompetitionIDs)
    }

    func preloadHomeSports(selectedCompetitionIDs: Set<String> = []) async {
        async let football: Void = ensureLoaded(
            for: .football,
            tournament: nil,
            competitionIDs: relevantCompetitionIDs(for: .football, from: selectedCompetitionIDs)
        )
        async let basketball: Void = ensureLoaded(
            for: .basketball,
            tournament: nil,
            competitionIDs: relevantCompetitionIDs(for: .basketball, from: selectedCompetitionIDs)
        )
        async let hockey: Void = ensureLoaded(
            for: .iceHockey,
            tournament: nil,
            competitionIDs: relevantCompetitionIDs(for: .iceHockey, from: selectedCompetitionIDs)
        )
        _ = await (football, basketball, hockey)
    }

    func select(league: League, competitionIDs: Set<String> = []) async {
        currentLeague = league
        currentCompetitionIDs = competitionIDs
        let key = cacheKey(for: league, tournament: nil, competitionIDs: competitionIDs)
        currentCacheKey = key
        if let snapshot = cachedSnapshots[key] {
            apply(snapshot, updatedAt: cachedUpdatedAt[key])
            return
        }
        await ensureLoaded(for: league, tournament: nil, competitionIDs: competitionIDs)
    }

    func ensureLoaded(for league: League, tournament: FootballTournament?, competitionIDs: Set<String> = []) async {
        let key = cacheKey(for: league, tournament: tournament, competitionIDs: competitionIDs)
        if let cached = cachedSnapshots[key] {
            if currentCacheKey == key {
                apply(cached, updatedAt: cachedUpdatedAt[key])
            }
            return
        }
        guard !loadedKeys.contains(key) else { return }
        await load(for: league, tournament: tournament, competitionIDs: competitionIDs, force: true)
    }

    func load(for league: League, tournament: FootballTournament?, competitionIDs: Set<String> = [], force: Bool = false) async {
        let key = cacheKey(for: league, tournament: tournament, competitionIDs: competitionIDs)
        if currentCacheKey == key {
            currentLeague = league
            currentCompetitionIDs = competitionIDs
        }
        if !force, let cached = cachedSnapshots[key] {
            if currentCacheKey == key {
                apply(cached, updatedAt: cachedUpdatedAt[key])
            }
            return
        }

        let shouldPresentLoading = currentCacheKey == key
        let shouldShowBlockingLoader = shouldPresentLoading && !hasVisibleContent
        let shouldShowRefreshState = shouldPresentLoading && hasVisibleContent
        if shouldShowBlockingLoader {
            isLoading = true
            errorText = nil
        } else if shouldShowRefreshState {
            isRefreshing = true
        }
        defer {
            if shouldShowBlockingLoader {
                isLoading = false
            }
            if shouldShowRefreshState {
                isRefreshing = false
            }
        }
        do {
            let snapshot = try await loadStableSnapshot(for: league, tournament: tournament, competitionIDs: competitionIDs)
            let nextSignature = signature(for: snapshot)
            let previousSignature = cachedSignatures[key]
            let updatedAt = Date()

            cachedSnapshots[key] = snapshot
            cachedSignatures[key] = nextSignature
            cachedUpdatedAt[key] = updatedAt
            loadedKeys.insert(key)
            if currentCacheKey == key {
                if previousSignature != nextSignature || errorText != nil {
                    apply(snapshot, updatedAt: updatedAt)
                } else {
                    errorText = nil
                    lastUpdatedAt = updatedAt
                }
            }
        } catch is CancellationError {
            return
        } catch {
            if let cached = cachedSnapshots[key], currentCacheKey == key {
                apply(cached, updatedAt: cachedUpdatedAt[key])
                errorText = nil
                return
            }
            loadedKeys.remove(key)
            if currentCacheKey == key {
                errorText = "Failed to load data. Pull to retry."
            }
        }
    }

    func refreshCurrentSelectionIfNeeded(maxAge: TimeInterval = 30) async {
        guard shouldAutoRefresh else { return }
        if let lastUpdatedAt, Date().timeIntervalSince(lastUpdatedAt) < maxAge {
            return
        }
        await load(
            for: currentLeague,
            tournament: nil,
            competitionIDs: currentCompetitionIDs,
            force: true
        )
    }

    var shouldAutoRefresh: Bool {
        statusIndicatesLive(featured.status)
    }

    private func apply(_ snapshot: Snapshot, updatedAt: Date?) {
        featured = snapshot.featured
        todays = snapshot.todays
        recent = snapshot.recent
        stats = snapshot.stats
        news = snapshot.news
        errorText = snapshot.errorText
        isLoading = false
        isRefreshing = false
        lastUpdatedAt = updatedAt
    }

    func preferredNews() -> NewsItem? {
        if let selected = cachedSnapshots[currentCacheKey]?.news.first {
            return selected
        }
        if let anyNews = cachedSnapshots.values.first(where: { !$0.news.isEmpty })?.news.first {
            return anyNews
        }
        if let snapshot = cachedSnapshots[currentCacheKey] {
            return NewsItem(
                author: snapshot.featured.league,
                time: snapshot.featured.eventDate ?? NSLocalizedString("Today", comment: ""),
                sport: currentLeague.apiSport,
                league: snapshot.featured.league,
                title: "\(snapshot.featured.left.name) vs \(snapshot.featured.right.name)",
                subtitle: NSLocalizedString("Latest match updates and lineups", comment: ""),
                body: NSLocalizedString("Match coverage, lineups, momentum shifts, and result context will appear here as new events arrive.", comment: ""),
                imageURL: nil,
                likes: 0,
                bookmarked: false
            )
        }
        return nil
    }

    private func makeFeatured(from event: TheSportsDBEvent, badges: [String: String]) -> FeaturedScore {
        let homeName = sanitizedTeamName(event.strHomeTeam, fallback: "Home")
        let awayName = sanitizedTeamName(event.strAwayTeam, fallback: "Away")
        return FeaturedScore(
            fixtureId: Int(event.idEvent) ?? 0,
            league: sanitizedLeagueName(event.strLeague),
            left: TeamMini(name: homeName, imageURL: badges[homeName]),
            right: TeamMini(name: awayName, imageURL: badges[awayName]),
            leftScore: event.homeScoreInt ?? 0,
            rightScore: event.awayScoreInt ?? 0,
            status: sanitizedStatus(event.strStatus),
            eventDate: event.dateEvent,
            eventTime: event.strTime
        )
    }

    private func makeMatch(from event: TheSportsDBEvent, badges: [String: String]) -> MatchRow {
        let homeName = sanitizedTeamName(event.strHomeTeam, fallback: "Home")
        let awayName = sanitizedTeamName(event.strAwayTeam, fallback: "Away")
        return MatchRow(
            fixtureId: Int(event.idEvent) ?? 0,
            left: TeamMini(name: homeName, imageURL: badges[homeName]),
            right: TeamMini(name: awayName, imageURL: badges[awayName]),
            scoreLeft: event.homeScoreInt,
            scoreRight: event.awayScoreInt,
            league: sanitizedLeagueName(event.strLeague),
            showScore: event.homeScoreInt != nil && event.awayScoreInt != nil,
            eventDate: event.dateEvent,
            eventTime: event.strTime
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
        let title = sanitizedNewsTitle(event)
        let subtitle = makeNewsSubtitle(from: event)
        return NewsItem(
            author: sanitizedLeagueName(event.strLeague),
            time: event.dateEvent ?? NSLocalizedString("Today", comment: ""),
            sport: event.strSport ?? currentLeague.apiSport,
            league: sanitizedLeagueName(event.strLeague),
            title: title,
            subtitle: subtitle,
            body: makeNewsBody(from: event, title: title, subtitle: subtitle),
            imageURL: event.strThumb,
            likes: Int(event.idEvent.suffix(2)) ?? 10,
            bookmarked: true
        )
    }

    private func makeNewsSubtitle(from event: TheSportsDBEvent) -> String {
        let matchup = [event.strHomeTeam, event.strAwayTeam]
            .compactMap { $0 }
            .map { sanitizedTeamName($0, fallback: "") }
            .filter { !$0.isEmpty }
            .joined(separator: " vs ")
        let status = event.strStatus?
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let score: String? = {
            guard let homeScore = event.homeScoreInt, let awayScore = event.awayScoreInt else { return nil }
            return "\(homeScore):\(awayScore)"
        }()

        return [sanitizedLeagueName(event.strLeague), matchup.isEmpty ? nil : matchup, score, status]
            .compactMap { value in
                guard let value else { return nil }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .joined(separator: " • ")
    }

    private func makeNewsBody(from event: TheSportsDBEvent, title: String, subtitle: String) -> String {
        let home = sanitizedTeamName(event.strHomeTeam, fallback: "Home side")
        let away = sanitizedTeamName(event.strAwayTeam, fallback: "Away side")
        let league = sanitizedLeagueName(event.strLeague, fallback: "the competition")
        let status = event.strStatus?
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let venue = event.strVenue?.trimmingCharacters(in: .whitespacesAndNewlines)
        let official = event.strOfficial?.trimmingCharacters(in: .whitespacesAndNewlines)

        let opening = "\(title) headlines the latest update from \(league). \(subtitle)"
        let matchContext: String
        if let homeScore = event.homeScoreInt, let awayScore = event.awayScoreInt {
            matchContext = "\(home) and \(away) are separated by a \(homeScore)-\(awayScore) scoreline, with the live status currently marked as \(status ?? "in progress")."
        } else {
            matchContext = "\(home) and \(away) are on the schedule, with kickoff context and team storylines driving this update."
        }

        let extraBits = [venue, official]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let closing = extraBits.isEmpty
            ? "Open the match page for lineups, stats, and deeper event context."
            : "\(extraBits). Open the match page for lineups, stats, and deeper event context."

        return [opening, matchContext, closing].joined(separator: "\n\n")
    }

    private func loadStableSnapshot(for league: League, tournament: FootballTournament?, competitionIDs: Set<String>) async throws -> Snapshot {
        var lastSnapshot: Snapshot?

        for attempt in 0..<maxLoadAttempts {
            let basePayload: TheSportsDBHomePayload
            if league == .football, let tournament {
                basePayload = try await service.fetchHomePayload(leagueId: tournament.leagueId)
            } else {
                basePayload = try await service.fetchHomePayload(sport: league.apiSport)
            }

            let payload = try await mergedPayload(
                basePayload: basePayload,
                league: league,
                tournament: tournament,
                competitionIDs: competitionIDs
            )

            let snapshot = await makeSnapshot(from: payload, sport: league.apiSport)
            lastSnapshot = snapshot

            if snapshotIsMeaningful(snapshot) {
                return snapshot
            }

            if attempt < maxLoadAttempts - 1 {
                try await Task.sleep(nanoseconds: 350_000_000)
            }
        }

        if let lastSnapshot, snapshotIsMeaningful(lastSnapshot) {
            return lastSnapshot
        }

        throw URLError(.badServerResponse)
    }

    private func mergedPayload(
        basePayload: TheSportsDBHomePayload,
        league: League,
        tournament: FootballTournament?,
        competitionIDs: Set<String>
    ) async throws -> TheSportsDBHomePayload {
        guard tournament == nil else { return basePayload }

        let competitions = competitionIDs
            .compactMap { BrowseCatalog.competition(for: $0) }
            .filter { $0.sport == league }

        let resolvedLeagueIDs = await resolveLeagueIDs(for: competitions)

        let uniqueLeagueIDs = Array(resolvedLeagueIDs).sorted()
        guard !uniqueLeagueIDs.isEmpty else { return basePayload }

        var payloads = [basePayload]
        let extraPayloads = await fetchAdditionalPayloads(leagueIDs: uniqueLeagueIDs)
        payloads.append(contentsOf: extraPayloads)

        return mergeHomePayloads(payloads)
    }

    private func resolveLeagueIDs(for competitions: [BrowseCompetition]) async -> Set<Int> {
        await withTaskGroup(of: Int?.self) { group in
            for competition in competitions {
                group.addTask { [service] in
                    if let apiLeagueId = competition.apiLeagueId {
                        return apiLeagueId
                    }
                    if let direct = await service.fetchLeagueId(
                        leagueName: competition.title,
                        sport: competition.sport.apiSport
                    ) {
                        return direct
                    }
                    for alias in competition.aliases {
                        if let resolved = await service.fetchLeagueId(
                            leagueName: alias,
                            sport: competition.sport.apiSport
                        ) {
                            return resolved
                        }
                    }
                    return nil
                }
            }

            var resolved = Set<Int>()
            for await leagueID in group {
                if let leagueID {
                    resolved.insert(leagueID)
                }
            }
            return resolved
        }
    }

    private func fetchAdditionalPayloads(leagueIDs: [Int]) async -> [TheSportsDBHomePayload] {
        await withTaskGroup(of: TheSportsDBHomePayload?.self) { group in
            for leagueID in leagueIDs {
                group.addTask { [service] in
                    try? await service.fetchHomePayload(leagueId: leagueID)
                }
            }

            var payloads: [TheSportsDBHomePayload] = []
            for await payload in group {
                if let payload {
                    payloads.append(payload)
                }
            }
            return payloads
        }
    }

    private func mergeHomePayloads(_ payloads: [TheSportsDBHomePayload]) -> TheSportsDBHomePayload {
        let featuredPool = payloads.flatMap { [$0.featured] + $0.todaysMatches + $0.recentMatches }
        let todaysPool = payloads.flatMap(\.todaysMatches)
        let recentPool = payloads.flatMap(\.recentMatches)
        let newsPool = payloads.flatMap(\.news)
        let stats = payloads.first(where: { !$0.stats.isEmpty })?.stats ?? []

        return TheSportsDBHomePayload(
            featured: uniqueEvents(featuredPool).first ?? payloads.first?.featured ?? fallbackHomeEvent(),
            todaysMatches: Array(uniqueEvents(todaysPool).prefix(24)),
            recentMatches: Array(uniqueEvents(recentPool).prefix(24)),
            stats: stats,
            news: Array(uniqueEvents(newsPool).prefix(20))
        )
    }

    private func uniqueEvents(_ events: [TheSportsDBEvent]) -> [TheSportsDBEvent] {
        var seen = Set<String>()
        var result: [TheSportsDBEvent] = []

        for event in events {
            guard hasDisplayableTeams(event) else { continue }
            guard seen.insert(eventIdentity(event)).inserted else { continue }
            result.append(event)
        }

        return result
    }

    private func fallbackHomeEvent() -> TheSportsDBEvent {
        TheSportsDBEvent(
            idEvent: "1001",
            idLeague: nil,
            idHomeTeam: nil,
            idAwayTeam: nil,
            strLeague: "League",
            strEvent: nil,
            strHomeTeam: "Home",
            strAwayTeam: "Away",
            intHomeScore: nil,
            intAwayScore: nil,
            dateEvent: nil,
            strTime: nil,
            strStatus: "Final",
            strVenue: nil,
            strThumb: nil
        )
    }

    private func makeSnapshot(from payload: TheSportsDBHomePayload, sport: String) async -> Snapshot {
        let allEvents = [payload.featured] + payload.todaysMatches + payload.recentMatches
        let badges = await badgeMap(for: allEvents, sport: sport)

        let statRows = payload.stats.map(makeStatRow).filter { $0.left != 0 || $0.right != 0 }
        let snapshotStats = TeamStats(
            rows: statRows,
            leftImageURL: badges[payload.featured.strHomeTeam ?? ""],
            rightImageURL: badges[payload.featured.strAwayTeam ?? ""]
        )
        let snapshotFeatured = makeFeatured(from: payload.featured, badges: badges)
        let snapshotTodays = payload.todaysMatches.map { makeMatch(from: $0, badges: badges) }
        let snapshotRecent = payload.recentMatches.map { makeMatch(from: $0, badges: badges) }
        let snapshotNews = payload.news.map(makeNews)
        let snapshotError = snapshotTodays.isEmpty && snapshotRecent.isEmpty
            ? "No matches for selected sport right now."
            : nil

        return Snapshot(
            featured: snapshotFeatured,
            todays: snapshotTodays,
            recent: snapshotRecent,
            stats: snapshotStats,
            news: snapshotNews,
            errorText: snapshotError
        )
    }

    private func snapshotIsMeaningful(_ snapshot: Snapshot) -> Bool {
        if !snapshot.todays.isEmpty || !snapshot.recent.isEmpty {
            return true
        }
        if snapshot.featured.fixtureId > 0,
           snapshot.featured.left.name != "Home",
           snapshot.featured.right.name != "Away" {
            return true
        }
        return false
    }

    private func hasDisplayableTeams(_ event: TheSportsDBEvent) -> Bool {
        let home = normalizedIdentityValue(event.strHomeTeam)
        let away = normalizedIdentityValue(event.strAwayTeam)
        let invalid = Set(["home", "away", "team", "tbd", "vs"])
        return !home.isEmpty && !away.isEmpty && !invalid.contains(home) && !invalid.contains(away)
    }

    private func eventIdentity(_ event: TheSportsDBEvent) -> String {
        let rawId = event.idEvent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !rawId.isEmpty, rawId != "0" {
            return rawId
        }

        return [
            normalizedIdentityValue(event.strHomeTeam),
            normalizedIdentityValue(event.strAwayTeam),
            normalizedIdentityValue(event.strLeague),
            event.dateEvent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            event.strTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        ].joined(separator: "|")
    }

    private func normalizedIdentityValue(_ value: String?) -> String {
        (value ?? "")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func sanitizedTeamName(_ value: String?, fallback: String) -> String {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return fallback }
        let normalized = normalizedIdentityValue(trimmed)
        if ["home", "away", "team", "tbd"].contains(normalized) {
            return fallback
        }
        return trimmed
    }

    private func sanitizedLeagueName(_ value: String?, fallback: String = "League") -> String {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func sanitizedStatus(_ value: String?) -> String {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Scheduled" : trimmed
    }

    private func sanitizedNewsTitle(_ event: TheSportsDBEvent) -> String {
        let explicit = event.strEvent?
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !explicit.isEmpty {
            return explicit
        }

        let home = sanitizedTeamName(event.strHomeTeam, fallback: "")
        let away = sanitizedTeamName(event.strAwayTeam, fallback: "")
        if !home.isEmpty && !away.isEmpty {
            return "\(home) vs \(away)"
        }

        return NSLocalizedString("Sports News", comment: "")
    }

    private func badgeMap(for events: [TheSportsDBEvent], sport: String) async -> [String: String] {
        let names = Set(
            events.flatMap {
                [
                    sanitizedTeamName($0.strHomeTeam, fallback: ""),
                    sanitizedTeamName($0.strAwayTeam, fallback: "")
                ]
            }
        ).filter { !$0.isEmpty }
        var map: [String: String] = [:]

        func mergeBadges(_ badges: [String: String], into map: inout [String: String]) {
            for (rawName, badge) in badges {
                let sanitizedName = sanitizedTeamName(rawName, fallback: "")
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

        let leagues = Array(Set(events.map { sanitizedLeagueName($0.strLeague, fallback: "") }.filter { !$0.isEmpty })).prefix(3)
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

    private func cacheKey(for league: League, tournament: FootballTournament?, competitionIDs: Set<String>) -> String {
        let relevantCompetitionIDs = competitionIDs
            .compactMap { BrowseCatalog.competition(for: $0)?.sport == league ? $0 : nil }
            .sorted()
            .joined(separator: "|")
        return "\(league.rawValue)|\(tournament?.rawValue ?? "none")|\(relevantCompetitionIDs)"
    }

    private func relevantCompetitionIDs(for league: League, from competitionIDs: Set<String>) -> Set<String> {
        Set(
            competitionIDs.filter {
                BrowseCatalog.competition(for: $0)?.sport == league
            }
        )
    }

    private var hasVisibleContent: Bool {
        !todays.isEmpty || !recent.isEmpty || featured.fixtureId != 1001
    }

    private func statusIndicatesLive(_ status: String) -> Bool {
        let normalized = status.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return false }
        if normalized.contains("not started") || normalized == "ns" || normalized.contains("postponed") {
            return false
        }
        if normalized.contains("live") || normalized == "ht" || normalized == "1h" || normalized == "2h" {
            return true
        }
        return normalized.contains("'")
    }

    private func signature(for snapshot: Snapshot) -> String {
        let featuredSignature = [
            String(snapshot.featured.fixtureId),
            snapshot.featured.league,
            snapshot.featured.left.name,
            snapshot.featured.right.name,
            String(snapshot.featured.leftScore),
            String(snapshot.featured.rightScore),
            snapshot.featured.status,
            snapshot.featured.eventDate ?? "",
            snapshot.featured.eventTime ?? ""
        ].joined(separator: "|")

        let todaysSignature = snapshot.todays.map(signature(for:)).joined(separator: "||")
        let recentSignature = snapshot.recent.map(signature(for:)).joined(separator: "||")
        let statsSignature = snapshot.stats.rows.map {
            [$0.title, String($0.left), String($0.right)].joined(separator: "|")
        }.joined(separator: "||")
        let newsSignature = snapshot.news.map {
            [$0.author, $0.time, $0.title, $0.subtitle, $0.imageURL ?? ""].joined(separator: "|")
        }.joined(separator: "||")

        return [
            featuredSignature,
            todaysSignature,
            recentSignature,
            statsSignature,
            newsSignature,
            snapshot.errorText ?? ""
        ].joined(separator: "###")
    }

    private func signature(for match: MatchRow) -> String {
        [
            String(match.fixtureId),
            match.left.name,
            match.right.name,
            match.league,
            String(match.scoreLeft ?? -1),
            String(match.scoreRight ?? -1),
            String(match.showScore),
            match.eventDate ?? "",
            match.eventTime ?? ""
        ].joined(separator: "|")
    }
}


struct HomeView: View {
    @ObservedObject private var vm: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var navigationPath = NavigationPath()
    @State private var selectedLeague: League = .football
    @State private var selectedDay: HomeDayFilter = .today
    @AppStorage("home.favoriteLeagues") private var favoriteLeaguesStorage = ""
    @AppStorage("home.matchNotifications") private var notificationFixturesStorage = ""
    @AppStorage("browse.selectedCompetitionIDs") private var selectedCompetitionIDsStorage = ""

    init(viewModel: HomeViewModel) {
        _vm = ObservedObject(wrappedValue: viewModel)
    }

    private let homeSports: [League] = [.football, .basketball, .iceHockey]
    private var featuredFixtureId: Int { vm.featured.fixtureId }
    private var selectedCompetitionIDs: Set<String> {
        let stored = Set(selectedCompetitionIDsStorage.split(separator: "|").map(String.init))
        return stored.isEmpty ? BrowseCatalog.defaultCompetitionIDs : stored
    }
    private var selectedCompetitionIDsForCurrentSport: Set<String> {
        Set(
            selectedCompetitionIDs.filter {
                BrowseCatalog.competition(for: $0)?.sport == selectedLeague
            }
        )
    }
    private var todaysMatches: [MatchRow] {
        filterMatchesForSelection(deduplicatedMatches(vm.todays, excluding: [featuredFixtureId]))
    }
    private var recentMatches: [MatchRow] {
        filterMatchesForSelection(deduplicatedMatches(vm.recent, excluding: [featuredFixtureId]))
    }

    private var activeMatches: [MatchRow] {
        switch selectedDay {
        case .yesterday:
            return recentMatches
        case .today:
            return todaysMatches
        case .tomorrow:
            let upcomingOnly = todaysMatches.filter { !$0.showScore }
            return upcomingOnly.isEmpty ? todaysMatches : upcomingOnly
        }
    }

    private var groupedMatches: [(league: String, matches: [MatchRow])] {
        let source = activeMatches.isEmpty ? todaysMatches : activeMatches
        var order: [String] = []
        var grouped: [String: [MatchRow]] = [:]

        for match in source.prefix(8) {
            if grouped[match.league] == nil {
                order.append(match.league)
            }
            grouped[match.league, default: []].append(match)
        }

        return order.map { ($0, grouped[$0] ?? []) }
    }

    private var liveCards: [HomeLiveCardModel] {
        var cards: [HomeLiveCardModel] = []

        if matchesBrowseSelection(vm.featured.league) {
            cards.append(
                HomeLiveCardModel(
                    route: route(from: vm.featured),
                    league: vm.featured.league,
                    homeName: vm.featured.left.name,
                    awayName: vm.featured.right.name,
                    homeImageURL: vm.featured.left.imageURL,
                    awayImageURL: vm.featured.right.imageURL,
                    homeScore: vm.featured.leftScore,
                    awayScore: vm.featured.rightScore,
                    minuteText: liveStatusText,
                    statTitle: featuredStatTitle,
                    statValue: featuredStatValue
                )
            )
        }

        for match in todaysMatches.prefix(cards.isEmpty ? 4 : 3) {
            cards.append(
                HomeLiveCardModel(
                    route: route(from: match),
                    league: match.league,
                    homeName: match.left.name,
                    awayName: match.right.name,
                    homeImageURL: match.left.imageURL,
                    awayImageURL: match.right.imageURL,
                    homeScore: match.scoreLeft ?? 0,
                    awayScore: match.scoreRight ?? 0,
                    minuteText: match.showScore ? "FT" : generatedKickoffTime(for: match),
                    statTitle: match.showScore ? "Shots on Target" : "Kickoff",
                    statValue: match.showScore ? "\(max(match.scoreLeft ?? 0, match.scoreRight ?? 0) + 3)" : generatedKickoffTime(for: match)
                )
            )
        }

        return cards
    }

    private var featuredStatTitle: String {
        guard isLiveStatus(vm.featured.status) else { return "Kickoff" }
        return vm.stats.rows.first?.title ?? "Possession"
    }

    private var featuredStatValue: String {
        guard isLiveStatus(vm.featured.status) else {
            return scheduledText(eventDate: vm.featured.eventDate, eventTime: vm.featured.eventTime, fallback: "Today")
        }
        guard let row = vm.stats.rows.first else { return "62%" }
        return row.left >= row.right ? "\(row.left)%" : "\(row.right)%"
    }

    private var liveStatusText: String {
        if vm.featured.status.isEmpty {
            return "72'"
        }
        return vm.featured.status
    }

    private var currentNewsItem: NewsItem? {
        vm.preferredNews()
    }

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                HomeBackground()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            MatchesBrandHeader()

                            SportFilterBar(
                                items: homeSports,
                                selected: $selectedLeague
                            )

                            DayFilterBar(selectedDay: $selectedDay)

                            if vm.isRefreshing || vm.shouldAutoRefresh {
                                LiveDataStatusStrip(
                                    isRefreshing: vm.isRefreshing,
                                    lastUpdatedAt: vm.lastUpdatedAt,
                                    autoRefreshEnabled: vm.shouldAutoRefresh,
                                    palette: palette
                                )
                            }

                            if vm.isLoading {
                                ProgressView()
                                    .tint(palette.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 10)
                            } else if let error = vm.errorText {
                                Text(LocalizedStringKey(error))
                                    .font(.custom("Inter-Regular", size: 13))
                                    .foregroundStyle(palette.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            VStack(alignment: .leading, spacing: 14) {
                                HomeLiveNowHeader()

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(Array(liveCards.enumerated()), id: \.offset) { index, card in
                                            Button {
                                                navigationPath.append(card.route)
                                            } label: {
                                                LiveNowMatchCard(model: card, isPrimary: index == 0)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            VStack(spacing: 18) {
                                ForEach(Array(groupedMatches.enumerated()), id: \.offset) { index, section in
                                    VStack(spacing: 10) {
                                        LeagueMatchesHeader(
                                            title: section.league,
                                            flag: flagEmoji(for: section.league),
                                            isFavorite: isFavoriteLeague(section.league)
                                        ) {
                                            toggleFavoriteLeague(section.league)
                                        }

                                        ForEach(section.matches) { match in
                                            MatchFeedRow(
                                                match: match,
                                                primaryText: primaryMeta(for: match),
                                                secondaryText: secondaryMeta(for: match),
                                                trailingIcon: trailingIcon(for: match),
                                                homeAccent: teamAccent(for: match.left.name),
                                                awayAccent: teamAccent(for: match.right.name),
                                                trailingHighlighted: isNotificationEnabled(for: match)
                                            ) {
                                                navigationPath.append(route(from: match))
                                            } onTrailingTap: {
                                                handleTrailingAction(for: match)
                                            }
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Trending News")
                                    .font(.custom("Inter-Bold", size: 18))
                                    .foregroundStyle(palette.primaryText)

                                if let firstNews = currentNewsItem {
                                    Button {
                                        navigationPath.append(
                                            NewsRoute(
                                                title: firstNews.title,
                                                subtitle: firstNews.subtitle,
                                                author: firstNews.author,
                                                time: firstNews.time,
                                                imageURL: firstNews.imageURL,
                                                body: firstNews.body,
                                                sport: firstNews.sport,
                                                league: firstNews.league
                                            )
                                        )
                                    } label: {
                                        TrendingNewsCard(item: firstNews)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 110)
                    }
                    .refreshable {
                        await vm.load(
                            for: selectedLeague,
                            tournament: nil,
                            competitionIDs: selectedCompetitionIDsForCurrentSport,
                            force: true
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: MatchRoute.self) { route in
                Overview(route: route)
            }
            .navigationDestination(for: NewsRoute.self) { route in
                NewsStoryDetailView(route: route)
            }
            .task {
                if selectedCompetitionIDsStorage.isEmpty {
                    selectedCompetitionIDsStorage = BrowseCatalog.defaultCompetitionIDs.sorted().joined(separator: "|")
                }
                await vm.select(league: selectedLeague, competitionIDs: selectedCompetitionIDsForCurrentSport)
            }
            .task(id: selectedLeague) {
                await vm.select(league: selectedLeague, competitionIDs: selectedCompetitionIDsForCurrentSport)
            }
            .task(id: selectedCompetitionIDsStorage) {
                await vm.select(league: selectedLeague, competitionIDs: selectedCompetitionIDsForCurrentSport)
            }
            .task(id: homeRefreshTaskKey) {
                guard scenePhase == .active, vm.shouldAutoRefresh else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                    guard !Task.isCancelled, scenePhase == .active else { return }
                    await vm.refreshCurrentSelectionIfNeeded()
                }
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                Task {
                    await vm.refreshCurrentSelectionIfNeeded(maxAge: 10)
                }
            }
        }
    }

    private var homeRefreshTaskKey: String {
        [
            selectedLeague.rawValue,
            selectedCompetitionIDsStorage,
            vm.shouldAutoRefresh ? "live" : "idle",
            scenePhase == .active ? "active" : "inactive"
        ].joined(separator: "|")
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

    private func primaryMeta(for match: MatchRow) -> String {
        if match.showScore || selectedDay == .yesterday {
            return "FT"
        }
        return generatedKickoffTime(for: match)
    }

    private func secondaryMeta(for match: MatchRow) -> String {
        if match.showScore || selectedDay == .yesterday {
            return generatedDateStamp(for: match)
        }
        return selectedDay == .today ? "Today" : "Tomorrow"
    }

    private func trailingIcon(for match: MatchRow) -> String {
        if match.showScore || selectedDay == .yesterday {
            return "play.fill"
        }
        return isNotificationEnabled(for: match) ? "bell.fill" : "bell"
    }

    private func generatedKickoffTime(for match: MatchRow) -> String {
        scheduledText(
            eventDate: match.eventDate,
            eventTime: match.eventTime,
            fallback: fallbackKickoffTime(for: match.fixtureId)
        )
    }

    private func generatedDateStamp(for match: MatchRow) -> String {
        if let scheduled = MatchNotificationManager.shared.scheduledDate(for: match) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: scheduled)
        }
        let day = 10 + abs(match.fixtureId % 18)
        let month = 10 + abs(match.fixtureId % 2)
        return String(format: "%02d/%02d", day, month)
    }

    private func deduplicatedMatches(_ matches: [MatchRow], excluding excludedIds: Set<Int> = []) -> [MatchRow] {
        var seenFixtureIds = excludedIds
        var seenKeys = Set<String>()
        var unique: [MatchRow] = []

        for match in matches {
            let key = [
                normalizedMatchValue(match.left.name),
                normalizedMatchValue(match.right.name),
                normalizedMatchValue(match.league),
                match.eventDate ?? "",
                match.eventTime ?? ""
            ].joined(separator: "|")

            if match.fixtureId > 0 {
                guard seenFixtureIds.insert(match.fixtureId).inserted else { continue }
            }
            guard seenKeys.insert(key).inserted else { continue }
            unique.append(match)
        }

        return unique
    }

    private func normalizedMatchValue(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func filterMatchesForSelection(_ matches: [MatchRow]) -> [MatchRow] {
        guard !selectedCompetitionIDsForCurrentSport.isEmpty else { return matches }
        return matches.filter { matchesBrowseSelection($0.league) }
    }

    private func matchesBrowseSelection(_ leagueName: String) -> Bool {
        BrowseCatalog.matchesSelection(
            competitionIDs: selectedCompetitionIDsForCurrentSport,
            leagueName: leagueName,
            sport: selectedLeague
        )
    }

    private func scheduledText(eventDate: String?, eventTime: String?, fallback: String) -> String {
        if let scheduled = MatchNotificationManager.shared.scheduledDate(
            eventDate: eventDate,
            eventTime: eventTime
        ) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: scheduled)
        }
        return fallback
    }

    private func fallbackKickoffTime(for fixtureId: Int) -> String {
        let hour = 12 + abs(fixtureId % 9)
        let minute = abs(fixtureId % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }

    private func isLiveStatus(_ status: String) -> Bool {
        let normalized = status.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return false }
        if normalized.contains("not started") || normalized == "ns" || normalized.contains("postponed") {
            return false
        }
        if normalized.contains("live") || normalized == "ht" || normalized == "1h" || normalized == "2h" {
            return true
        }
        return normalized.contains("'")
    }

    private func teamAccent(for name: String) -> Color {
        let palette: [Color] = [
            Color(red: 1, green: 0.33, blue: 0.33),
            Color(red: 0.24, green: 0.51, blue: 1),
            Color(red: 0.57, green: 0.19, blue: 0.87),
            Color(red: 0.17, green: 0.91, blue: 0.28),
            Color(red: 1, green: 0.78, blue: 0.2),
            Color.white
        ]
        let index = abs(name.hashValue) % palette.count
        return palette[index]
    }

    private func flagEmoji(for league: String) -> String {
        let lowercased = league.lowercased()
        if lowercased.contains("premier") { return "🇬🇧" }
        if lowercased.contains("la liga") { return "🇪🇸" }
        if lowercased.contains("serie a") { return "🇮🇹" }
        if lowercased.contains("bundesliga") { return "🇩🇪" }
        if lowercased.contains("ligue 1") { return "🇫🇷" }
        if lowercased.contains("nba") { return "🇺🇸" }
        if lowercased.contains("nhl") { return "🇺🇸" }
        return "🏳️"
    }

    private func favoriteLeagues() -> Set<String> {
        Set(favoriteLeaguesStorage.split(separator: "|").map(String.init))
    }

    private func isFavoriteLeague(_ league: String) -> Bool {
        favoriteLeagues().contains(league)
    }

    private func toggleFavoriteLeague(_ league: String) {
        var updated = favoriteLeagues()
        if updated.contains(league) {
            updated.remove(league)
        } else {
            updated.insert(league)
        }
        favoriteLeaguesStorage = updated.sorted().joined(separator: "|")
    }

    private func notificationFixtures() -> Set<String> {
        Set(notificationFixturesStorage.split(separator: "|").map(String.init))
    }

    private func isNotificationEnabled(for match: MatchRow) -> Bool {
        notificationFixtures().contains(String(match.fixtureId))
    }

    private func handleTrailingAction(for match: MatchRow) {
        if match.showScore || selectedDay == .yesterday {
            navigationPath.append(route(from: match))
            return
        }
        toggleNotification(for: match)
    }

    private func toggleNotification(for match: MatchRow) {
        let key = String(match.fixtureId)
        var updated = notificationFixtures()
        if updated.contains(key) {
            updated.remove(key)
            notificationFixturesStorage = updated.sorted().joined(separator: "|")
            MatchNotificationManager.shared.removeNotification(for: match)
            return
        }

        notificationFixturesStorage = updated.union([key]).sorted().joined(separator: "|")
        MatchNotificationManager.shared.requestAndScheduleNotification(for: match)
    }
}

private enum HomeDayFilter: CaseIterable {
    case yesterday
    case today
    case tomorrow

    var title: String {
        switch self {
        case .yesterday: return "Yesterday"
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        }
    }
}

private struct HomeLiveCardModel {
    let route: MatchRoute
    let league: String
    let homeName: String
    let awayName: String
    let homeImageURL: String?
    let awayImageURL: String?
    let homeScore: Int
    let awayScore: Int
    let minuteText: String
    let statTitle: String
    let statValue: String
}

private struct HomeBackground: View {
    var body: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 260, style: .continuous)
                    .fill(Color(red: 0.07, green: 0.18, blue: 0.31).opacity(0.22))
                    .frame(width: 220, height: 680)
                    .blur(radius: 75)
                    .offset(x: -110, y: 120)
            }
    }
}

private struct MatchesBrandHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 70 / 255, green: 153 / 255, blue: 1), Color(red: 43 / 255, green: 107 / 255, blue: 238 / 255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "bolt.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)
            .shadow(color: Color(red: 36 / 255, green: 155 / 255, blue: 1).opacity(0.34), radius: 18, y: 10)

            HStack(spacing: 0) {
                Text("LiveScores")
                    .foregroundStyle(palette.primaryText)
                Text(" Pro")
                    .foregroundStyle(Color(red: 36 / 255, green: 155 / 255, blue: 1))
            }
            .font(.custom("Inter-Bold", size: 22))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

private struct SportFilterBar: View {
    let items: [League]
    @Binding var selected: League
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { league in
                Button {
                    selected = league
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: icon(for: league))
                            .font(.system(size: 15, weight: .semibold))
                        Text(LocalizedStringKey(title(for: league)))
                            .font(.custom("Inter-Bold", size: 13))
                    }
                    .foregroundStyle(selected == league ? palette.primaryText : palette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selected == league ? palette.iconBackground : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.iconBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        )
    }

    private func title(for league: League) -> String {
        switch league {
        case .football: return "Football"
        case .basketball: return "Basketball"
        case .iceHockey: return "Hockey"
        default: return league.rawValue
        }
    }

    private func icon(for league: League) -> String {
        switch league {
        case .football: return "soccerball"
        case .basketball: return "basketball.fill"
        case .iceHockey: return "opticaldisc.fill"
        default: return "sportscourt"
        }
    }
}

private struct DayFilterBar: View {
    @Binding var selectedDay: HomeDayFilter
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        ZStack {
            HStack {
                Button {
                    selectedDay = .yesterday
                } label: {
                    Text(LocalizedStringKey(HomeDayFilter.yesterday.title))
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundStyle(selectedDay == .yesterday ? palette.primaryText : palette.secondaryText)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    selectedDay = .tomorrow
                } label: {
                    Text(LocalizedStringKey(HomeDayFilter.tomorrow.title))
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundStyle(selectedDay == .tomorrow ? palette.primaryText : palette.secondaryText)
                }
                .buttonStyle(.plain)
            }

            Button {
                selectedDay = .today
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .bold))
                    Text(todayTitle)
                        .font(.custom("Inter-Bold", size: 14))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(palette.primaryText)
                .padding(.horizontal, 20)
                .frame(height: 48)
                .background(
                    Capsule(style: .continuous)
                        .fill(palette.iconBackground)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(palette.divider, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 52)
        .padding(.bottom, 6)
    }

    private var todayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return String(format: NSLocalizedString("Today, %@", comment: ""), formatter.string(from: Date()))
    }
}

private struct HomeLiveNowHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(red: 1, green: 0.31, blue: 0.23))
                .frame(width: 12, height: 12)

            Text("Live Now")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundStyle(palette.primaryText)

            Spacer()
        }
    }
}

private struct LiveNowMatchCard: View {
    let model: HomeLiveCardModel
    let isPrimary: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 22, height: 22)
                        .overlay {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(palette.primaryText.opacity(0.9))
                        }

                    Text(model.league)
                        .font(.custom("Inter-Bold", size: 13))
                        .foregroundStyle(palette.primaryText.opacity(0.86))
                        .lineLimit(1)
                }

                Spacer()

                Text(model.minuteText)
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.27))
            }

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 16) {
                    LiveNowTeamRow(name: model.homeName, imageURL: model.homeImageURL)
                    LiveNowTeamRow(name: model.awayName, imageURL: model.awayImageURL)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 18) {
                    Text("\(model.homeScore)")
                        .font(.custom("Inter-Bold", size: 20))
                        .foregroundStyle(palette.primaryText)
                    Text("\(model.awayScore)")
                        .font(.custom("Inter-Bold", size: 20))
                        .foregroundStyle(palette.primaryText)
                }
            }

            HStack {
                Text(LocalizedStringKey(model.statTitle))
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundStyle(palette.secondaryText.opacity(0.85))

                Spacer()

                Text(model.statValue)
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundStyle(Color(red: 36 / 255, green: 155 / 255, blue: 1))
            }
            .padding(.top, 4)
            .padding(.bottom, 2)
        }
        .padding(16)
        .frame(width: isPrimary ? 310 : 244, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.iconBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        )
    }
}

private struct LiveNowTeamRow: View {
    let name: String
    let imageURL: String?
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                RemoteCircleImage(urlString: imageURL, systemName: "shield", fallbackText: name)
            }
            .frame(width: 38, height: 38)

            Text(name)
                .font(.custom("Inter-Bold", size: 15))
                .foregroundStyle(palette.primaryText)
                .lineLimit(1)
        }
    }
}

private struct LeagueMatchesHeader: View {
    let title: String
    let flag: String
    let isFavorite: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text(flag)
                            .font(.system(size: 12))
                    }

                Text(title)
                    .font(.custom("Inter-Bold", size: 15))
                    .foregroundStyle(palette.primaryText)
            }

            Spacer()

            Button(action: action) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isFavorite ? Color.green : palette.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MatchFeedRow: View {
    let match: MatchRow
    let primaryText: String
    let secondaryText: String
    let trailingIcon: String
    let homeAccent: Color
    let awayAccent: Color
    let trailingHighlighted: Bool
    let onTap: () -> Void
    let onTrailingTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(LocalizedStringKey(primaryText))
                            .font(.custom("Inter-Bold", size: 15))
                            .foregroundStyle(palette.primaryText)

                        Text(LocalizedStringKey(secondaryText))
                            .font(.custom("Inter-Regular", size: 12))
                            .foregroundStyle(palette.secondaryText)
                    }
                    .frame(width: 46)

                    Rectangle()
                        .fill(palette.divider)
                        .frame(width: 1, height: 42)

                    VStack(alignment: .leading, spacing: 12) {
                        MatchFeedTeamRow(name: match.left.name, accent: homeAccent)
                        MatchFeedTeamRow(name: match.right.name, accent: awayAccent)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 12) {
                        Text(match.scoreLeft.map { String($0) } ?? "–")
                            .font(.custom("Inter-Bold", size: 17))
                            .foregroundStyle(palette.primaryText)

                        Text(match.scoreRight.map { String($0) } ?? "–")
                            .font(.custom("Inter-Bold", size: 17))
                            .foregroundStyle(match.showScore && (match.scoreRight ?? 0) > (match.scoreLeft ?? 0) ? Color.green : palette.primaryText)
                    }
                }
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(palette.divider)
                .frame(width: 1, height: 42)

            Button(action: onTrailingTap) {
                Image(systemName: trailingIcon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(trailingHighlighted ? Color(red: 36 / 255, green: 155 / 255, blue: 1) : palette.secondaryText)
                    .frame(width: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.iconBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        )
    }
}

private struct MatchFeedTeamRow: View {
    let name: String
    let accent: Color
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "tshirt.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)

            Text(name)
                .font(.custom("Inter-Medium", size: 15))
                .foregroundStyle(palette.primaryText)
                .lineLimit(1)
        }
    }
}

private struct TrendingNewsCard: View {
    let item: NewsItem
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                RemoteRectImage(urlString: item.imageURL, systemName: "photo")
                    .frame(width: 96, height: 96)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Circle()
                    .fill(Color.black.opacity(0.72))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Transfer Talk")
                    .font(.custom("Inter-Bold", size: 12))
                    .foregroundStyle(Color(red: 36 / 255, green: 155 / 255, blue: 1))

                Text(item.title)
                    .font(.custom("Inter-Bold", size: 15))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(3)

                HStack {
                    Text(item.author)
                    Spacer()
                    Text(item.time)
                }
                .font(.custom("Inter-Regular", size: 12))
                .foregroundStyle(palette.secondaryText)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.iconBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        )
    }
}

final class MatchNotificationManager {
    static let shared = MatchNotificationManager()
    private let recordsStorageKey = "home.matchNotificationRecords"

    private init() {}

    func requestAndScheduleNotification(for match: MatchRow) {
        saveRecord(for: match)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            self.scheduleNotification(for: match)
        }
    }

    func removeNotification(for match: MatchRow) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier(for: match)]
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [identifier(for: match)]
        )
        removeRecord(fixtureId: match.fixtureId)
    }

    private func scheduleNotification(for match: MatchRow) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Match Started", comment: "")
        content.body = String(
            format: NSLocalizedString("%@ vs %@ has started.", comment: ""),
            match.left.name,
            match.right.name
        )
        content.sound = .default
        content.userInfo = [
            "fixtureId": match.fixtureId,
            "league": match.league,
            "homeName": match.left.name,
            "awayName": match.right.name
        ]

        let trigger: UNNotificationTrigger
        if let date = scheduledDate(for: match) {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: identifier(for: match),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func identifier(for match: MatchRow) -> String {
        "match-start-\(match.fixtureId)"
    }

    func scheduledDate(for match: MatchRow) -> Date? {
        scheduledDate(eventDate: match.eventDate, eventTime: match.eventTime)
    }

    func scheduledDate(eventDate: String?, eventTime: String?) -> Date? {
        guard let dateString = eventDate, let timeString = eventTime else { return nil }
        let rawTime = timeString.trimmingCharacters(in: .whitespacesAndNewlines)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let isoDate = isoFormatter.date(from: "\(dateString)T\(rawTime)"), isoDate > Date() {
            return isoDate
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let isoDate = isoFormatter.date(from: "\(dateString)T\(rawTime)"), isoDate > Date() {
            return isoDate
        }

        let normalizedTime = rawTime
            .replacingOccurrences(of: "Z", with: "")
            .split(separator: "+")
            .first
            .map(String.init) ?? rawTime

        let candidates = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm"
        ]

        for format in candidates {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let date = formatter.date(from: "\(dateString) \(normalizedTime)"), date > Date() {
                return date
            }
        }
        return nil
    }

    func inboxSnapshot() async -> MatchNotificationInboxSnapshot {
        let records = storedRecords()
        let pendingIdentifiers = Set(await pendingRequests().map(\.identifier))
        let deliveredNotifications = await deliveredNotifications()
        let deliveredDates = Dictionary(
            uniqueKeysWithValues: deliveredNotifications.map { notification in
                (notification.request.identifier, notification.date)
            }
        )

        return MatchNotificationInboxSnapshot(
            records: records,
            pendingIdentifiers: pendingIdentifiers,
            deliveredDates: deliveredDates
        )
    }

    func clearAll() {
        let identifiers = storedRecords().map(\.id)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        UserDefaults.standard.removeObject(forKey: recordsStorageKey)
    }

    static func identifier(for fixtureId: Int) -> String {
        "match-start-\(fixtureId)"
    }

    private func saveRecord(for match: MatchRow) {
        var records = storedRecords().filter { $0.fixtureId != match.fixtureId }
        records.append(
            MatchNotificationRecord(
                fixtureId: match.fixtureId,
                league: match.league,
                homeName: match.left.name,
                awayName: match.right.name,
                homeImageURL: match.left.imageURL,
                awayImageURL: match.right.imageURL,
                eventDate: match.eventDate,
                eventTime: match.eventTime,
                scheduledAt: scheduledDate(for: match),
                createdAt: Date()
            )
        )
        storeRecords(records)
    }

    private func removeRecord(fixtureId: Int) {
        let updated = storedRecords().filter { $0.fixtureId != fixtureId }
        storeRecords(updated)
    }

    private func storedRecords() -> [MatchNotificationRecord] {
        guard
            let data = UserDefaults.standard.data(forKey: recordsStorageKey),
            let records = try? JSONDecoder().decode([MatchNotificationRecord].self, from: data)
        else {
            return []
        }
        return records
    }

    private func storeRecords(_ records: [MatchNotificationRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: recordsStorageKey)
    }

    private func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private func deliveredNotifications() async -> [UNNotification] {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }
    }
}

struct MatchNotificationRecord: Codable, Hashable, Identifiable {
    let fixtureId: Int
    let league: String
    let homeName: String
    let awayName: String
    let homeImageURL: String?
    let awayImageURL: String?
    let eventDate: String?
    let eventTime: String?
    let scheduledAt: Date?
    let createdAt: Date

    var id: String {
        MatchNotificationManager.identifier(for: fixtureId)
    }
}

struct MatchNotificationInboxSnapshot {
    let records: [MatchNotificationRecord]
    let pendingIdentifiers: Set<String>
    let deliveredDates: [String: Date]
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
    var eventDate: String? = nil
    var eventTime: String? = nil
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
    var eventDate: String? = nil
    var eventTime: String? = nil
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
    var league: String = ""
    var title: String
    var subtitle: String
    var body: String = ""
    var imageURL: String? = nil
    var likes: Int
    var bookmarked: Bool
}


struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack {
            Text(LocalizedStringKey(text))
                .font(.custom("Inter-SemiBold", size: 16))
                .foregroundStyle(Color.primary)
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
                        .foregroundStyle(Color.primary)
                    Text(":")
                        .font(.custom("Inter-SemiBold", size: 20))
                        .foregroundStyle(Color.secondary)
                    Text("\(model.rightScore)")
                        .font(.custom("Inter-SemiBold", size: 28))
                        .foregroundStyle(Color.primary)
                }
                Text(model.status)
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(Color.secondary)
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
                .foregroundStyle(Color.secondary)
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
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
            }
            .frame(width: 84)

            Spacer()

            VStack(spacing: 4) {
                if match.showScore, let l = match.scoreLeft, let r = match.scoreRight {
                    HStack(spacing: 6) {
                        Text("\(l)")
                            .font(.custom("Inter-SemiBold", size: 18))
                            .foregroundStyle(Color.primary)
                        Text(":")
                            .font(.custom("Inter-SemiBold", size: 14))
                            .foregroundStyle(Color.secondary)
                        Text("\(r)")
                            .font(.custom("Inter-SemiBold", size: 18))
                            .foregroundStyle(Color.primary)
                    }
                } else {
                    Text("—  :  —")
                        .font(.custom("Inter-SemiBold", size: 16))
                        .foregroundStyle(Color.secondary)
                }

                Text(match.league)
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 104)

            Spacer()

            VStack(spacing: 10) {
                CircleIcon(urlString: match.right.imageURL)
                Text(match.right.name)
                    .font(.custom("Inter-SemiBold", size: 12))
                    .foregroundStyle(Color.primary)
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
            Circle().fill(Color.primary.opacity(0.06))
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
                    .foregroundStyle(Color.primary)
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
                .foregroundStyle(Color.primary)
                .frame(width: 30, alignment: .leading)

            StatBar(
                progress: leftProgress,
                height: 8,
                fillFromRight: true,
                width: barWidth
            )

            Text(title)
                .font(.custom("Inter-SemiBold", size: 12))
                .foregroundStyle(Color.secondary)
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
                .foregroundStyle(Color.primary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct StatBar: View {
    let progress: CGFloat
    let height: CGFloat
    let fillFromRight: Bool
    let width: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.primary.opacity(0.06))
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
    let fallbackText: String?

    init(urlString: String? = nil, fallbackText: String? = nil) {
        self.urlString = urlString
        self.fallbackText = fallbackText
    }

    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.35))
            RemoteCircleImage(urlString: urlString, systemName: "photo", fallbackText: fallbackText)
        }
        .frame(width: 32, height: 32)
        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

struct StatsCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.primary.opacity(0.05), Color.primary.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
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
                            imageURL: item.imageURL,
                            body: item.body,
                            sport: item.sport,
                            league: item.league
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
                        .foregroundStyle(Color.secondary)
                    Text("\(item.author)  •  \(item.time)")
                        .font(.custom("Inter-SemiBold", size: 11))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }

                Text(item.title)
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)

                HStack {
                    Label("\(item.likes)", systemImage: "hand.thumbsup.fill")
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(Color.secondary)

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
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        appPalette(for: colorScheme)
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(palette.primaryText)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("Sports News")
                            .font(.custom("Inter-SemiBold", size: 16))
                            .foregroundStyle(palette.primaryText)
                        Spacer()
                        Color.clear.frame(width: 18, height: 18)
                    }
                    .padding(.top, 6)

                    RemoteRectImage(urlString: route.imageURL, systemName: "photo")
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack(spacing: 8) {
                        Text(route.author)
                        Text("•")
                        Text(route.time)
                        if !route.sport.isEmpty {
                            Text("•")
                            Text(route.sport)
                        }
                    }
                        .font(.custom("Inter-SemiBold", size: 12))
                        .foregroundStyle(palette.secondaryText)

                    Text(route.title)
                        .font(.custom("Inter-SemiBold", size: 30))
                        .foregroundStyle(palette.primaryText)

                    Text(route.subtitle)
                        .font(.custom("Inter-SemiBold", size: 15))
                        .foregroundStyle(palette.secondaryText)

                    if !route.league.isEmpty {
                        Text(route.league)
                            .font(.custom("Inter-SemiBold", size: 13))
                            .foregroundStyle(palette.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(palette.accent.opacity(0.16))
                            )
                    }

                    Text(route.body)
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundStyle(palette.primaryText)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }
}


struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.primary.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
    }
}

struct RemoteCircleImage: View {
    let urlString: String?
    let systemName: String
    var fallbackText: String? = nil

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    fallbackContent
                }
            }
            .clipShape(Circle())
        } else {
            fallbackContent
        }
    }

    @ViewBuilder
    private var fallbackContent: some View {
        if let initials = placeholderInitials(from: fallbackText) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.10))
                Text(initials)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.primary)
            }
        } else {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
    }

    private func placeholderInitials(from value: String?) -> String? {
        let tokens = (value ?? "")
            .split(whereSeparator: { $0.isWhitespace || $0 == "-" || $0 == "_" })
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else { return nil }
        let initials = tokens.prefix(2).compactMap(\.first).map { String($0).uppercased() }.joined()
        return initials.isEmpty ? nil : initials
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
                        .foregroundStyle(Color.secondary)
                }
            }
        } else {
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.secondary)
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
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(isSelected ? Color.blue : Color.primary.opacity(0.06)))
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color.primary.opacity(0.12), lineWidth: 1)
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

            TextField(LocalizedStringKey(placeholder), text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(Color.primary)
                .tint(Color.primary)

            Button { text = "" } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .opacity(text.isEmpty ? 0.6 : 1.0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.primary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
}

struct LiveDataStatusStrip: View {
    let isRefreshing: Bool
    let lastUpdatedAt: Date?
    let autoRefreshEnabled: Bool
    let palette: AppThemePalette

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.custom("Inter-Medium", size: 12))
                .foregroundStyle(palette.secondaryText)

            Spacer(minLength: 12)

            if autoRefreshEnabled {
                Text("Auto-refresh on")
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(palette.primaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        )
    }

    private var statusColor: Color {
        if isRefreshing {
            return Color(red: 0.23, green: 0.65, blue: 1.0)
        }
        if autoRefreshEnabled {
            return Color(red: 0.18, green: 0.84, blue: 0.37)
        }
        return palette.secondaryText.opacity(0.65)
    }

    private var statusText: String {
        if isRefreshing {
            return "Updating live data..."
        }
        guard let lastUpdatedAt else {
            return autoRefreshEnabled ? "Waiting for first live sync" : "Live sync is idle"
        }
        return "Updated \(Self.timeFormatter.string(from: lastUpdatedAt))"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

#Preview("Home") {
    HomeView(viewModel: HomeViewModel())
}
