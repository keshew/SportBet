import Foundation


struct TheSportsDBEventsResponse: Decodable {
    let events: [TheSportsDBEvent]?

    private enum CodingKeys: String, CodingKey { case events }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBEvent>.self, forKey: .events)
        events = lossy?.elements
    }
}

struct TheSportsDBTeamsResponse: Decodable {
    let teams: [TheSportsDBTeam]?

    private enum CodingKeys: String, CodingKey { case teams }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBTeam>.self, forKey: .teams)
        teams = lossy?.elements
    }
}

struct TheSportsDBTableResponse: Decodable {
    let table: [TheSportsDBTableRow]?

    private enum CodingKeys: String, CodingKey { case table }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBTableRow>.self, forKey: .table)
        table = lossy?.elements
    }
}

struct TheSportsDBEventStatsResponse: Decodable {
    let eventstats: [TheSportsDBEventStat]?

    private enum CodingKeys: String, CodingKey { case eventstats }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBEventStat>.self, forKey: .eventstats)
        eventstats = lossy?.elements
    }
}

struct TheSportsDBSportsResponse: Decodable {
    let sports: [TheSportsDBSport]?

    private enum CodingKeys: String, CodingKey { case sports }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBSport>.self, forKey: .sports)
        sports = lossy?.elements
    }
}

struct TheSportsDBLeaguesResponse: Decodable {
    let leagues: [TheSportsDBLeague]?

    private enum CodingKeys: String, CodingKey { case leagues }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBLeague>.self, forKey: .leagues)
        leagues = lossy?.elements
    }
}

struct TheSportsDBEvent: Decodable, Identifiable {
    let idEvent: String
    let idLeague: String?
    let idHomeTeam: String?
    let idAwayTeam: String?
    let strLeague: String?
    let strEvent: String?
    let strHomeTeam: String?
    let strAwayTeam: String?
    let intHomeScore: String?
    let intAwayScore: String?
    let dateEvent: String?
    let strTime: String?
    let strStatus: String?
    let strVenue: String?
    let strThumb: String?
    let strSport: String?
    let intHomeShots: String?
    let intAwayShots: String?
    let intHomeShotsOnGoal: String?
    let intAwayShotsOnGoal: String?
    let intHomeCorners: String?
    let intAwayCorners: String?
    let intHomeFouls: String?
    let intAwayFouls: String?
    let intHomeOffsides: String?
    let intAwayOffsides: String?
    let intHomeYellowCards: String?
    let intAwayYellowCards: String?
    let intHomeRedCards: String?
    let intAwayRedCards: String?
    let intHomeSaves: String?
    let intAwaySaves: String?

    var id: String { idEvent }
    var homeScoreInt: Int? { intHomeScore.flatMap(Int.init) }
    var awayScoreInt: Int? { intAwayScore.flatMap(Int.init) }

    init(
        idEvent: String,
        idLeague: String?,
        idHomeTeam: String?,
        idAwayTeam: String?,
        strLeague: String?,
        strEvent: String?,
        strHomeTeam: String?,
        strAwayTeam: String?,
        intHomeScore: String?,
        intAwayScore: String?,
        dateEvent: String?,
        strTime: String?,
        strStatus: String?,
        strVenue: String?,
        strThumb: String?,
        strSport: String? = nil,
        intHomeShots: String? = nil,
        intAwayShots: String? = nil,
        intHomeShotsOnGoal: String? = nil,
        intAwayShotsOnGoal: String? = nil,
        intHomeCorners: String? = nil,
        intAwayCorners: String? = nil,
        intHomeFouls: String? = nil,
        intAwayFouls: String? = nil,
        intHomeOffsides: String? = nil,
        intAwayOffsides: String? = nil,
        intHomeYellowCards: String? = nil,
        intAwayYellowCards: String? = nil,
        intHomeRedCards: String? = nil,
        intAwayRedCards: String? = nil,
        intHomeSaves: String? = nil,
        intAwaySaves: String? = nil
    ) {
        self.idEvent = idEvent
        self.idLeague = idLeague
        self.idHomeTeam = idHomeTeam
        self.idAwayTeam = idAwayTeam
        self.strLeague = strLeague
        self.strEvent = strEvent
        self.strHomeTeam = strHomeTeam
        self.strAwayTeam = strAwayTeam
        self.intHomeScore = intHomeScore
        self.intAwayScore = intAwayScore
        self.dateEvent = dateEvent
        self.strTime = strTime
        self.strStatus = strStatus
        self.strVenue = strVenue
        self.strThumb = strThumb
        self.strSport = strSport
        self.intHomeShots = intHomeShots
        self.intAwayShots = intAwayShots
        self.intHomeShotsOnGoal = intHomeShotsOnGoal
        self.intAwayShotsOnGoal = intAwayShotsOnGoal
        self.intHomeCorners = intHomeCorners
        self.intAwayCorners = intAwayCorners
        self.intHomeFouls = intHomeFouls
        self.intAwayFouls = intAwayFouls
        self.intHomeOffsides = intHomeOffsides
        self.intAwayOffsides = intAwayOffsides
        self.intHomeYellowCards = intHomeYellowCards
        self.intAwayYellowCards = intAwayYellowCards
        self.intHomeRedCards = intHomeRedCards
        self.intAwayRedCards = intAwayRedCards
        self.intHomeSaves = intHomeSaves
        self.intAwaySaves = intAwaySaves
    }

    private enum CodingKeys: String, CodingKey {
        case idEvent, idLeague, idHomeTeam, idAwayTeam, strLeague, strEvent, strHomeTeam, strAwayTeam
        case intHomeScore, intAwayScore, dateEvent, strTime, strStatus, strVenue, strThumb, strSport
        case intHomeShots, intAwayShots, intHomeShotsOnGoal, intAwayShotsOnGoal
        case intHomeCorners, intAwayCorners, intHomeFouls, intAwayFouls
        case intHomeOffsides, intAwayOffsides, intHomeYellowCards, intAwayYellowCards
        case intHomeRedCards, intAwayRedCards, intHomeSaves, intAwaySaves
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idEvent = c.decodeLossyString(forKey: .idEvent) ?? UUID().uuidString
        idLeague = c.decodeLossyString(forKey: .idLeague)
        idHomeTeam = c.decodeLossyString(forKey: .idHomeTeam)
        idAwayTeam = c.decodeLossyString(forKey: .idAwayTeam)
        strLeague = c.decodeLossyString(forKey: .strLeague)
        strEvent = c.decodeLossyString(forKey: .strEvent)
        strHomeTeam = c.decodeLossyString(forKey: .strHomeTeam)
        strAwayTeam = c.decodeLossyString(forKey: .strAwayTeam)
        intHomeScore = c.decodeLossyString(forKey: .intHomeScore)
        intAwayScore = c.decodeLossyString(forKey: .intAwayScore)
        dateEvent = c.decodeLossyString(forKey: .dateEvent)
        strTime = c.decodeLossyString(forKey: .strTime)
        strStatus = c.decodeLossyString(forKey: .strStatus)
        strVenue = c.decodeLossyString(forKey: .strVenue)
        strThumb = c.decodeLossyString(forKey: .strThumb)
        strSport = c.decodeLossyString(forKey: .strSport)
        intHomeShots = c.decodeLossyString(forKey: .intHomeShots)
        intAwayShots = c.decodeLossyString(forKey: .intAwayShots)
        intHomeShotsOnGoal = c.decodeLossyString(forKey: .intHomeShotsOnGoal)
        intAwayShotsOnGoal = c.decodeLossyString(forKey: .intAwayShotsOnGoal)
        intHomeCorners = c.decodeLossyString(forKey: .intHomeCorners)
        intAwayCorners = c.decodeLossyString(forKey: .intAwayCorners)
        intHomeFouls = c.decodeLossyString(forKey: .intHomeFouls)
        intAwayFouls = c.decodeLossyString(forKey: .intAwayFouls)
        intHomeOffsides = c.decodeLossyString(forKey: .intHomeOffsides)
        intAwayOffsides = c.decodeLossyString(forKey: .intAwayOffsides)
        intHomeYellowCards = c.decodeLossyString(forKey: .intHomeYellowCards)
        intAwayYellowCards = c.decodeLossyString(forKey: .intAwayYellowCards)
        intHomeRedCards = c.decodeLossyString(forKey: .intHomeRedCards)
        intAwayRedCards = c.decodeLossyString(forKey: .intAwayRedCards)
        intHomeSaves = c.decodeLossyString(forKey: .intHomeSaves)
        intAwaySaves = c.decodeLossyString(forKey: .intAwaySaves)
    }
}

struct TheSportsDBTeam: Decodable, Identifiable {
    let idTeam: String
    let strTeam: String?
    let strSport: String?
    let strLeague: String?
    let idLeague: String?
    let strCountry: String?
    let strBadge: String?
    let strLogo: String?
    let strBanner: String?
    let strFanart1: String?
    let strStadium: String?

    var id: String { idTeam }

    private enum CodingKeys: String, CodingKey {
        case idTeam, strTeam, strSport, strLeague, idLeague, strCountry
        case strBadge, strLogo, strBanner, strFanart1, strStadium
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idTeam = c.decodeLossyString(forKey: .idTeam) ?? UUID().uuidString
        strTeam = c.decodeLossyString(forKey: .strTeam)
        strSport = c.decodeLossyString(forKey: .strSport)
        strLeague = c.decodeLossyString(forKey: .strLeague)
        idLeague = c.decodeLossyString(forKey: .idLeague)
        strCountry = c.decodeLossyString(forKey: .strCountry)
        strBadge = c.decodeLossyString(forKey: .strBadge)
        strLogo = c.decodeLossyString(forKey: .strLogo)
        strBanner = c.decodeLossyString(forKey: .strBanner)
        strFanart1 = c.decodeLossyString(forKey: .strFanart1)
        strStadium = c.decodeLossyString(forKey: .strStadium)
    }
}

struct TheSportsDBTableRow: Decodable, Identifiable {
    let idTeam: String?
    let strTeam: String?
    let intRank: String?
    let intPlayed: String?
    let intWin: String?
    let intDraw: String?
    let intLoss: String?
    let intGoalsFor: String?
    let intGoalsAgainst: String?
    let intGoalDifference: String?
    let intPoints: String?

    var id: String { idTeam ?? UUID().uuidString }

    private enum CodingKeys: String, CodingKey {
        case idTeam, strTeam, intRank, intPlayed, intWin, intDraw, intLoss
        case intGoalsFor, intGoalsAgainst, intGoalDifference, intPoints
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idTeam = c.decodeLossyString(forKey: .idTeam)
        strTeam = c.decodeLossyString(forKey: .strTeam)
        intRank = c.decodeLossyString(forKey: .intRank)
        intPlayed = c.decodeLossyString(forKey: .intPlayed)
        intWin = c.decodeLossyString(forKey: .intWin)
        intDraw = c.decodeLossyString(forKey: .intDraw)
        intLoss = c.decodeLossyString(forKey: .intLoss)
        intGoalsFor = c.decodeLossyString(forKey: .intGoalsFor)
        intGoalsAgainst = c.decodeLossyString(forKey: .intGoalsAgainst)
        intGoalDifference = c.decodeLossyString(forKey: .intGoalDifference)
        intPoints = c.decodeLossyString(forKey: .intPoints)
    }
}

struct TheSportsDBEventStat: Decodable, Identifiable {
    let strStat: String
    let strHome: String?
    let strAway: String?

    var id: String { strStat }

    init(strStat: String, strHome: String?, strAway: String?) {
        self.strStat = strStat
        self.strHome = strHome
        self.strAway = strAway
    }

    private enum CodingKeys: String, CodingKey {
        case strStat, strHome, strAway, intHome, intAway
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        strStat = c.decodeLossyString(forKey: .strStat) ?? "Stat"
        strHome = c.decodeLossyString(forKey: .strHome) ?? c.decodeLossyString(forKey: .intHome)
        strAway = c.decodeLossyString(forKey: .strAway) ?? c.decodeLossyString(forKey: .intAway)
    }
}

struct TheSportsDBSport: Decodable, Identifiable {
    let idSport: String?
    let strSport: String
    let strSportThumb: String?

    var id: String { idSport ?? strSport }

    private enum CodingKeys: String, CodingKey { case idSport, strSport, strSportThumb }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idSport = c.decodeLossyString(forKey: .idSport)
        strSport = c.decodeLossyString(forKey: .strSport) ?? "Sport"
        strSportThumb = c.decodeLossyString(forKey: .strSportThumb)
    }
}

struct TheSportsDBLeague: Decodable, Identifiable {
    let idLeague: String
    let strLeague: String?
    let strSport: String?

    var id: String { idLeague }

    private enum CodingKeys: String, CodingKey { case idLeague, strLeague, strSport }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idLeague = c.decodeLossyString(forKey: .idLeague) ?? UUID().uuidString
        strLeague = c.decodeLossyString(forKey: .strLeague)
        strSport = c.decodeLossyString(forKey: .strSport)
    }
}


struct TheSportsDBHomePayload {
    let featured: TheSportsDBEvent
    let todaysMatches: [TheSportsDBEvent]
    let recentMatches: [TheSportsDBEvent]
    let stats: [TheSportsDBEventStat]
    let news: [TheSportsDBEvent]
}

struct TheSportsDBOverviewPayload {
    let event: TheSportsDBEvent
    let stats: [TheSportsDBEventStat]
    let statsSource: String
}

struct TheSportsDBMatchesPayload {
    let featured: TheSportsDBEvent
    let finals: [TheSportsDBEvent]
    let upcoming: [TheSportsDBEvent]
    let stats: [TheSportsDBEventStat]
    let standings: [TheSportsDBTableRow]
}

struct TheSportsDBTeamProfilePayload {
    let team: TheSportsDBTeam
    let standings: [TheSportsDBTableRow]
    let stats: [TheSportsDBEventStat]
    let recentEvent: TheSportsDBEvent?
}


protocol TheSportsDBServicing {
    func fetchHomePayload() async throws -> TheSportsDBHomePayload
    func fetchHomePayload(sport: String) async throws -> TheSportsDBHomePayload
    func fetchOverviewPayload(fixtureId: Int) async throws -> TheSportsDBOverviewPayload
    func fetchMatchesPayload(leagueId: Int) async throws -> TheSportsDBMatchesPayload
    func fetchMatchesPayload(sport: String) async throws -> TheSportsDBMatchesPayload
    func fetchSports() async throws -> [TheSportsDBSport]
    func fetchNews(for sport: String) async throws -> [TheSportsDBEvent]
    func fetchTeamProfile(teamId: Int) async throws -> TheSportsDBTeamProfilePayload
    func fetchTeamProfile(sport: String) async throws -> TheSportsDBTeamProfilePayload
    func fetchTeamBadge(teamName: String) async -> String?
    func fetchTeamBadges(leagueName: String, sport: String) async -> [String: String]
}


final class LiveTheSportsDBService: TheSportsDBServicing {
    static let shared = LiveTheSportsDBService(apiKey: "138900")

    private let apiKey: String
    private let baseURL = "https://www.thesportsdb.com/api/v1/json"
    private let v2BaseURL = "https://www.thesportsdb.com/api/v2/json"
    private var badgeCache: [String: String] = [:]

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchHomePayload() async throws -> TheSportsDBHomePayload {
        try await fetchHomePayload(sport: "Soccer")
    }

    func fetchHomePayload(sport: String) async throws -> TheSportsDBHomePayload {
        let safeSport = normalizedSport(sport)
        let (today, yesterday) = (try? await fetchSportEventBuckets(sport: safeSport)) ?? ([], [])
        let news = (try? await fetchNews(for: safeSport)) ?? []

        let featured = (today + yesterday).first ?? fallbackEvent(id: "1001")
        let stats = await statsForFirstAvailableEvent(events: today + yesterday)

        return TheSportsDBHomePayload(
            featured: featured,
            todaysMatches: Array(today.prefix(5)),
            recentMatches: Array(yesterday.prefix(5)),
            stats: stats,
            news: Array(news.prefix(10))
        )
    }

    func fetchOverviewPayload(fixtureId: Int) async throws -> TheSportsDBOverviewPayload {
        let events = try await fetchEvents(path: "lookupevent.php", query: [("id", "\(fixtureId)")])
        let event = events.first ?? fallbackEvent(id: "\(fixtureId)")
        var stats = await fetchEventStats(eventId: event.idEvent)
        var source = "eventstats"
        let nonZeroStats = stats.filter {
            let l = numericDoubleValue($0.strHome)
            let r = numericDoubleValue($0.strAway)
            return l != 0 || r != 0
        }

        if nonZeroStats.isEmpty {
            let fallback = fallbackStats(from: event)
            if !fallback.isEmpty {
                stats = fallback
                source = "event_fields_fallback"
            } else {
                let resolvedLeagueId = await resolveLeagueId(
                    idLeague: event.idLeague,
                    leagueName: event.strLeague,
                    sport: event.strSport
                )
                if let leagueId = resolvedLeagueId, leagueId > 0 {
                let neighbors = (try? await fetchEvents(path: "eventspastleague.php", query: [("id", "\(leagueId)")])) ?? []
                let sampled = Array(([event] + neighbors).prefix(20))
                let sampledStats = await statsForFirstAvailableEvent(events: sampled)
                if !sampledStats.isEmpty {
                    stats = sampledStats
                    source = "neighbor_event"
                } else if !stats.isEmpty {
                    source = "raw_only"
                } else {
                    stats = []
                    source = "none"
                }
                } else if !stats.isEmpty {
                    source = "raw_only"
                } else {
                    stats = []
                    source = "none"
                }
            }
        } else {
            stats = nonZeroStats
        }

        stats = normalizeStats(stats, sport: event.strSport)
        return TheSportsDBOverviewPayload(event: event, stats: stats, statsSource: source)
    }

    func fetchMatchesPayload(leagueId: Int) async throws -> TheSportsDBMatchesPayload {
        async let pastEvents = fetchEvents(path: "eventspastleague.php", query: [("id", "\(leagueId)")])
        async let nextEvents = fetchEvents(path: "eventsnextleague.php", query: [("id", "\(leagueId)")])
        async let tableRows = fetchTable(leagueId: leagueId)

        let past = try await pastEvents
        let next = try await nextEvents
        let table = try await tableRows

        let featured = past.first ?? next.first ?? fallbackEvent(id: "2001")
        let stats = await statsForFirstAvailableEvent(events: past + next)

        return TheSportsDBMatchesPayload(
            featured: featured,
            finals: Array(past.prefix(3)),
            upcoming: Array(next.prefix(3)),
            stats: stats,
            standings: table
        )
    }

    func fetchMatchesPayload(sport: String) async throws -> TheSportsDBMatchesPayload {
        let safeSport = normalizedSport(sport)
        let (today, yesterday) = (try? await fetchSportEventBuckets(sport: safeSport)) ?? ([], [])
        let tomorrow = (try? await fetchDayEvents(sport: safeSport, offsetDays: 1)) ?? []

        let featured = (today + yesterday).first ?? fallbackEvent(id: "2001")
        let stats = await statsForFirstAvailableEvent(events: today + yesterday + tomorrow)
        let preferred = preferredLeagueIds(for: safeSport)
        let leagueId = preferred.first ?? Int(featured.idLeague ?? "") ?? (safeSport == "Soccer" ? 4328 : 0)
        let standings = (leagueId > 0) ? ((try? await fetchTable(leagueId: leagueId)) ?? []) : []

        return TheSportsDBMatchesPayload(
            featured: featured,
            finals: Array(yesterday.prefix(5)),
            upcoming: Array((today + tomorrow).prefix(5)),
            stats: stats,
            standings: standings
        )
    }

    func fetchSports() async throws -> [TheSportsDBSport] {
        let response: TheSportsDBSportsResponse = try await request(path: "all_sports.php", query: [])
        return response.sports ?? []
    }

    func fetchNews(for sport: String) async throws -> [TheSportsDBEvent] {
        let today = dateString(offsetDays: 0)
        let safeSport = normalizedSport(sport).replacingOccurrences(of: " ", with: "_")

        let highlights: TheSportsDBEventsResponse? = try? await request(
            path: "eventshighlights.php",
            query: [("d", today), ("s", safeSport)]
        )
        if let events = highlights?.events, !events.isEmpty {
            return events
        }

        let eventsByDay: TheSportsDBEventsResponse? = try? await request(
            path: "eventsday.php",
            query: [("d", today), ("s", safeSport)]
        )
        return eventsByDay?.events ?? []
    }

    func fetchTeamProfile(teamId: Int) async throws -> TheSportsDBTeamProfilePayload {
        let teams = try await fetchTeams(path: "lookupteam.php", query: [("id", "\(teamId)")])
        guard let team = teams.first else {
            throw URLError(.cannotParseResponse)
        }

        let leagueId = Int(team.idLeague ?? "") ?? 4328
        async let tableRows = fetchTable(leagueId: leagueId)
        async let pastEvents = fetchEvents(path: "eventspastleague.php", query: [("id", "\(leagueId)")])

        let table = try await tableRows
        let past = try await pastEvents

        let recent = past.first {
            $0.strHomeTeam == team.strTeam || $0.strAwayTeam == team.strTeam
        } ?? past.first

        let stats = await fetchEventStats(eventId: recent?.idEvent ?? "0")
        return TheSportsDBTeamProfilePayload(
            team: team,
            standings: table,
            stats: stats,
            recentEvent: recent
        )
    }

    func fetchTeamProfile(sport: String) async throws -> TheSportsDBTeamProfilePayload {
        let safeSport = normalizedSport(sport)
        if safeSport.caseInsensitiveCompare("Soccer") == .orderedSame {
            return try await fetchTeamProfile(teamId: 133604) // Arsenal
        }

        let countries = ["England", "United States", "Spain", "Germany", "Italy", "France"]
        var selectedTeam: TheSportsDBTeam?

        for country in countries {
            let teams = try await fetchTeams(
                path: "search_all_teams.php",
                query: [("s", safeSport), ("c", country)]
            )
            if let first = teams.first {
                selectedTeam = first
                break
            }
        }

        if selectedTeam == nil {
            let teams = try await fetchTeams(
                path: "searchteams.php",
                query: [("t", "Arsenal")]
            )
            selectedTeam = teams.first
        }

        guard let selectedTeam, let teamId = Int(selectedTeam.idTeam) else {
            throw URLError(.cannotParseResponse)
        }
        return try await fetchTeamProfile(teamId: teamId)
    }

    func fetchTeamBadge(teamName: String) async -> String? {
        if let cached = badgeCache[teamName] {
            return cached
        }
        do {
            let safeName = teamName.replacingOccurrences(of: " ", with: "_")
            let teams = try await fetchTeams(path: "searchteams.php", query: [("t", safeName)])
            let badge = teams.first?.strBadge
            if let badge {
                badgeCache[teamName] = badge
            }
            return badge
        } catch {
            return nil
        }
    }

    func fetchTeamBadges(leagueName: String, sport: String) async -> [String: String] {
        let safeLeague = leagueName.replacingOccurrences(of: " ", with: "_")
        do {
            let teams = try await fetchTeams(path: "search_all_teams.php", query: [("l", safeLeague)])
            if !teams.isEmpty {
                var out: [String: String] = [:]
                for team in teams {
                    if let name = team.strTeam, let badge = team.strBadge {
                        out[name] = badge
                        badgeCache[name] = badge
                    }
                }
                return out
            }
        } catch { }

        let countries = ["England", "Spain", "Italy", "Germany", "France", "United States"]
        for country in countries {
            do {
                let teams = try await fetchTeams(
                    path: "search_all_teams.php",
                    query: [("s", sport), ("c", country)]
                )
                if !teams.isEmpty {
                    var out: [String: String] = [:]
                    for team in teams {
                        if let name = team.strTeam, let badge = team.strBadge {
                            out[name] = badge
                            badgeCache[name] = badge
                        }
                    }
                    return out
                }
            } catch { }
        }
        return [:]
    }


    private func fetchEvents(path: String, query: [(String, String)]) async throws -> [TheSportsDBEvent] {
        let response: TheSportsDBEventsResponse = try await request(path: path, query: query)
        return response.events ?? []
    }

    private func fetchTeams(path: String, query: [(String, String)]) async throws -> [TheSportsDBTeam] {
        let response: TheSportsDBTeamsResponse = try await request(path: path, query: query)
        return response.teams ?? []
    }

    private func fetchTable(leagueId: Int) async throws -> [TheSportsDBTableRow] {
        let response: TheSportsDBTableResponse = try await request(
            path: "lookuptable.php",
            query: [("l", "\(leagueId)")]
        )
        return response.table ?? []
    }

    private func fetchDayEvents(sport: String, offsetDays: Int) async throws -> [TheSportsDBEvent] {
        let date = dateString(offsetDays: offsetDays)
        let safeSport = normalizedSport(sport)
        let response: TheSportsDBEventsResponse = try await request(
            path: "eventsday.php",
            query: [("d", date), ("s", safeSport)]
        )
        return response.events ?? []
    }

    private func fetchSportEventBuckets(sport: String) async throws -> ([TheSportsDBEvent], [TheSportsDBEvent]) {
        let preferredIds = preferredLeagueIds(for: sport)
        var today: [TheSportsDBEvent] = []
        var yesterday: [TheSportsDBEvent] = []

        for leagueId in preferredIds {
            let past = (try? await fetchEvents(path: "eventspastleague.php", query: [("id", "\(leagueId)")])) ?? []
            let next = (try? await fetchEvents(path: "eventsnextleague.php", query: [("id", "\(leagueId)")])) ?? []
            yesterday.append(contentsOf: past.prefix(3))
            today.append(contentsOf: next.prefix(3))
        }

        if today.isEmpty && yesterday.isEmpty {
            let day0 = try await fetchDayEvents(sport: sport, offsetDays: 0)
            let dayMinus1 = try await fetchDayEvents(sport: sport, offsetDays: -1)
            today = day0
            yesterday = dayMinus1
        }

        return (uniqueEvents(today), uniqueEvents(yesterday))
    }

    private func uniqueEvents(_ events: [TheSportsDBEvent]) -> [TheSportsDBEvent] {
        var seen = Set<String>()
        var out: [TheSportsDBEvent] = []
        for event in events {
            let hasTeams = !(event.strHomeTeam ?? "").isEmpty && !(event.strAwayTeam ?? "").isEmpty
            if !hasTeams { continue }
            if seen.insert(event.idEvent).inserted {
                out.append(event)
            }
        }
        return out
    }

    private func preferredLeagueIds(for sport: String) -> [Int] {
        switch normalizedSport(sport).lowercased() {
        case "soccer":
            return [4328, 4335, 4331, 4332, 4334] // EPL, Serie A, Bundesliga, La Liga, Ligue 1
        case "basketball":
            return [4387]
        case "american football":
            return [4391]
        case "ice hockey":
            return [4380]
        case "baseball":
            return [4424]
        case "motorsport":
            return [4370]
        default:
            return []
        }
    }

    private func fetchEventStats(eventId: String) async -> [TheSportsDBEventStat] {
        guard eventId != "0" else { return [] }
        guard let v1URL = URL(string: "\(baseURL)/\(apiKey)/lookupeventstats.php?id=\(eventId)") else { return [] }
        var v1Request = URLRequest(url: v1URL)
        v1Request.timeoutInterval = 20

        let v1: [TheSportsDBEventStat]
        if let (v1Data, v1Response) = try? await URLSession.shared.data(for: v1Request),
           let http = v1Response as? HTTPURLResponse,
           (200..<300).contains(http.statusCode) {
            let decoded = try? JSONDecoder().decode(TheSportsDBEventStatsResponse.self, from: v1Data)
            v1 = decoded?.eventstats ?? []
        } else {
            v1 = []
        }

        if !v1.isEmpty { return v1 }
        return await fetchEventStatsV2(eventId: eventId)
    }

    private func statsForFirstAvailableEvent(events: [TheSportsDBEvent]) async -> [TheSportsDBEventStat] {
        for event in events.prefix(10) {
            let stats = await fetchEventStats(eventId: event.idEvent)
            let nonZero = stats.filter {
                let l = numericDoubleValue($0.strHome)
                let r = numericDoubleValue($0.strAway)
                return l != 0 || r != 0
            }
            if !nonZero.isEmpty {
                return normalizeStats(nonZero, sport: event.strSport)
            }

            let fallback = fallbackStats(from: event)
            if !fallback.isEmpty {
                return normalizeStats(fallback, sport: event.strSport)
            }
        }
        return []
    }

    private func fallbackStats(from event: TheSportsDBEvent) -> [TheSportsDBEventStat] {
        var rows: [TheSportsDBEventStat] = []

        func add(_ title: String, _ home: String?, _ away: String?) {
            let l = numericDoubleValue(home)
            let r = numericDoubleValue(away)
            if l != 0 || r != 0 {
                rows.append(TheSportsDBEventStat(strStat: title, strHome: home, strAway: away))
            }
        }

        add("Shots", event.intHomeShots, event.intAwayShots)
        add("Shots on Goal", event.intHomeShotsOnGoal, event.intAwayShotsOnGoal)
        add("Corners", event.intHomeCorners, event.intAwayCorners)
        add("Fouls", event.intHomeFouls, event.intAwayFouls)
        add("Offsides", event.intHomeOffsides, event.intAwayOffsides)
        add("Yellow Cards", event.intHomeYellowCards, event.intAwayYellowCards)
        add("Red Cards", event.intHomeRedCards, event.intAwayRedCards)
        add("Saves", event.intHomeSaves, event.intAwaySaves)

        return rows
    }

    private func numericValue(_ raw: String?) -> Int {
        Int(numericDoubleValue(raw).rounded())
    }

    private func numericDoubleValue(_ raw: String?) -> Double {
        guard var raw else { return 0 }
        raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return 0 }
        raw = raw.replacingOccurrences(of: ",", with: ".")
        raw = raw.replacingOccurrences(of: "%", with: "")
        let allowed = Set("0123456789.-")
        let cleaned = String(raw.filter { allowed.contains($0) })
        return Double(cleaned) ?? 0
    }

    private func normalizeStats(_ stats: [TheSportsDBEventStat], sport: String?) -> [TheSportsDBEventStat] {
        guard !stats.isEmpty else { return [] }
        let sportKey = normalizedSport(sport ?? "").lowercased()
        let aliases = statAliases(for: sportKey)
        let preferredOrder = statOrder(for: sportKey)

        var bucket: [String: TheSportsDBEventStat] = [:]
        var fallback: [TheSportsDBEventStat] = []

        for stat in stats {
            let rawName = stat.strStat.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normalizeStatKey(rawName)
            if let canonical = aliases[key] {
                if bucket[canonical] == nil {
                    bucket[canonical] = TheSportsDBEventStat(
                        strStat: canonical,
                        strHome: stat.strHome,
                        strAway: stat.strAway
                    )
                }
            } else {
                fallback.append(stat)
            }
        }

        if bucket.isEmpty {
            return stats
        }

        var result: [TheSportsDBEventStat] = []
        for title in preferredOrder {
            if let row = bucket[title] {
                result.append(row)
            }
        }

        result.append(contentsOf: fallback)
        return result
    }

    private func normalizeStatKey(_ name: String) -> String {
        let lower = name.lowercased()
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        return String(lower.filter { allowed.contains($0) })
    }

    private func statOrder(for sport: String) -> [String] {
        switch sport {
        case "soccer":
            return [
                "Shots on Goal", "Shots off Goal", "Total Shots", "Blocked Shots",
                "Shots insidebox", "Shots outsidebox", "Fouls", "Corner Kicks",
                "Offsides", "Ball Possession", "Yellow Cards", "Red Cards",
                "Goalkeeper Saves", "Total passes", "Passes accurate", "Passes %",
                "expected_goals", "goals_prevented"
            ]
        case "basketball":
            return [
                "Points", "Field Goals", "Field Goal %", "3PT", "3PT %",
                "Free Throws", "Free Throw %", "Rebounds", "Assists",
                "Steals", "Blocks", "Turnovers", "Fouls"
            ]
        case "american football":
            return [
                "Total Yards", "Passing Yards", "Rushing Yards", "First Downs",
                "Turnovers", "Penalties", "Time of Possession"
            ]
        case "ice hockey":
            return ["Shots", "Hits", "Faceoffs Won", "Power Play", "Penalty Minutes", "Blocks"]
        case "baseball":
            return ["Runs", "Hits", "Errors", "Home Runs", "Strikeouts", "Walks", "Left on Base"]
        default:
            return []
        }
    }

    private func statAliases(for sport: String) -> [String: String] {
        switch sport {
        case "soccer":
            return [
                "shotsongoal": "Shots on Goal",
                "shotsoffgoal": "Shots off Goal",
                "totalshots": "Total Shots",
                "blockedshots": "Blocked Shots",
                "shotsinsidebox": "Shots insidebox",
                "shotsoutsidebox": "Shots outsidebox",
                "fouls": "Fouls",
                "cornerkicks": "Corner Kicks",
                "offsides": "Offsides",
                "ballpossession": "Ball Possession",
                "yellowcards": "Yellow Cards",
                "redcards": "Red Cards",
                "goalkeepersaves": "Goalkeeper Saves",
                "totalpasses": "Total passes",
                "passesaccurate": "Passes accurate",
                "passes": "Passes %",
                "expectedgoals": "expected_goals",
                "expectedgoalsxg": "expected_goals",
                "goalsprevented": "goals_prevented"
            ]
        case "basketball":
            return [
                "points": "Points",
                "fieldgoals": "Field Goals",
                "fieldgoal": "Field Goals",
                "fieldgoalpercentage": "Field Goal %",
                "fieldgoalpct": "Field Goal %",
                "3pt": "3PT",
                "3point": "3PT",
                "3pointpercentage": "3PT %",
                "freethrows": "Free Throws",
                "freethrowpercentage": "Free Throw %",
                "rebounds": "Rebounds",
                "assists": "Assists",
                "steals": "Steals",
                "blocks": "Blocks",
                "turnovers": "Turnovers",
                "fouls": "Fouls"
            ]
        case "american football":
            return [
                "totalyards": "Total Yards",
                "passingyards": "Passing Yards",
                "rushingyards": "Rushing Yards",
                "firstdowns": "First Downs",
                "turnovers": "Turnovers",
                "penalties": "Penalties",
                "timeofpossession": "Time of Possession"
            ]
        case "ice hockey":
            return [
                "shots": "Shots",
                "hits": "Hits",
                "faceoffswon": "Faceoffs Won",
                "powerplay": "Power Play",
                "penaltyminutes": "Penalty Minutes",
                "blocks": "Blocks"
            ]
        case "baseball":
            return [
                "runs": "Runs",
                "hits": "Hits",
                "errors": "Errors",
                "homeruns": "Home Runs",
                "strikeouts": "Strikeouts",
                "walks": "Walks",
                "leftonbase": "Left on Base"
            ]
        default:
            return [:]
        }
    }

    private func request<T: Decodable>(path: String, query: [(String, String)]) async throws -> T {
        var comps = URLComponents(string: "\(baseURL)/\(apiKey)/\(path)")
        comps?.queryItems = query.map { URLQueryItem(name: $0.0, value: $0.1) }
        guard let url = comps?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func fetchEventStatsV2(eventId: String) async -> [TheSportsDBEventStat] {
        guard let url = URL(string: "\(v2BaseURL)/lookup/event_stats/\(eventId)") else { return [] }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return []
            }
            return parseV2Stats(data: data)
        } catch {
            return []
        }
    }

    private func parseV2Stats(data: Data) -> [TheSportsDBEventStat] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return [] }

        let arrays = extractCandidateStatArrays(from: json)
        for array in arrays {
            let parsed = array.compactMap(parseStatRow(dict:))
            let nonZero = parsed.filter {
                numericValue($0.strHome) != 0 || numericValue($0.strAway) != 0
            }
            if !nonZero.isEmpty {
                return nonZero
            }
        }
        return []
    }

    private func extractCandidateStatArrays(from json: Any) -> [[[String: Any]]] {
        if let arr = json as? [[String: Any]] {
            return [arr]
        }

        guard let dict = json as? [String: Any] else { return [] }
        var result: [[[String: Any]]] = []

        for key in ["event_stats", "eventstats", "event_statistics", "statistics", "stats", "data"] {
            if let arr = dict[key] as? [[String: Any]] {
                result.append(arr)
            } else if let nested = dict[key] as? [String: Any] {
                result.append(contentsOf: extractCandidateStatArrays(from: nested))
            }
        }

        for (_, value) in dict {
            if let arr = value as? [[String: Any]] {
                result.append(arr)
            }
        }

        return result
    }

    private func parseStatRow(dict: [String: Any]) -> TheSportsDBEventStat? {
        let statName = stringify(dict["strStat"])
            ?? stringify(dict["stat"])
            ?? stringify(dict["type"])
            ?? stringify(dict["name"])

        let home = stringify(dict["strHome"])
            ?? stringify(dict["intHome"])
            ?? stringify(dict["valueHome"])
            ?? stringify(dict["home_value"])
            ?? extractNestedStatValue(dict["home"])

        let away = stringify(dict["strAway"])
            ?? stringify(dict["intAway"])
            ?? stringify(dict["valueAway"])
            ?? stringify(dict["away_value"])
            ?? extractNestedStatValue(dict["away"])

        guard let statName, !statName.isEmpty else { return nil }
        return TheSportsDBEventStat(strStat: statName, strHome: home, strAway: away)
    }

    private func extractNestedStatValue(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let str = stringify(value) { return str }
        if let dict = value as? [String: Any] {
            for key in ["value", "stat", "total", "count", "display"] {
                if let nested = stringify(dict[key]) {
                    return nested
                }
            }
        }
        return nil
    }

    private func stringify(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let v = value as? String { return v }
        if let v = value as? Int { return String(v) }
        if let v = value as? Double {
            return v.rounded(.towardZero) == v ? String(Int(v)) : String(v)
        }
        if let v = value as? Bool { return v ? "true" : "false" }
        if let v = value as? NSNumber { return v.stringValue }
        return nil
    }

    private func dateString(offsetDays: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offsetDays, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func fallbackEvent(id: String) -> TheSportsDBEvent {
        TheSportsDBEvent(
            idEvent: id,
            idLeague: "4328",
            idHomeTeam: nil,
            idAwayTeam: nil,
            strLeague: "Premier League",
            strEvent: "Match",
            strHomeTeam: "Home",
            strAwayTeam: "Away",
            intHomeScore: "0",
            intAwayScore: "0",
            dateEvent: nil,
            strTime: nil,
            strStatus: "Not Started",
            strVenue: nil,
            strThumb: nil
        )
    }

    private func resolveLeagueId(idLeague: String?, leagueName: String?, sport: String?) async -> Int? {
        if let idLeague, let value = Int(idLeague), value > 0 {
            return value
        }
        guard let leagueName, !leagueName.isEmpty else { return nil }

        let response: TheSportsDBLeaguesResponse? = try? await request(path: "all_leagues.php", query: [])
        guard let leagues = response?.leagues else { return nil }

        let normalizedLeague = leagueName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSport = sport?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if let exact = leagues.first(where: {
            ($0.strLeague?.lowercased() == normalizedLeague)
            && (normalizedSport == nil || $0.strSport?.lowercased() == normalizedSport)
        }), let id = Int(exact.idLeague) {
            return id
        }

        if let loose = leagues.first(where: { $0.strLeague?.lowercased() == normalizedLeague }),
           let id = Int(loose.idLeague) {
            return id
        }

        return nil
    }

    private func normalizedSport(_ sport: String) -> String {
        sport.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct LossyArray<Element: Decodable>: Decodable {
    var elements: [Element]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        while !container.isAtEnd {
            if let item = try? container.decode(Element.self) {
                result.append(item)
            } else {
                _ = try? container.decode(JSONDiscard.self)
            }
        }
        elements = result
    }
}

private struct JSONDiscard: Decodable {}

private extension KeyedDecodingContainer {
    func decodeLossyString(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return String(value) }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value.rounded(.towardZero) == value ? String(Int(value)) : String(value)
        }
        if let value = try? decodeIfPresent(Bool.self, forKey: key) { return value ? "true" : "false" }
        return nil
    }
}
