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

struct TheSportsDBTimelineResponse: Decodable {
    let timeline: [TheSportsDBTimelineItem]?

    private enum CodingKeys: String, CodingKey { case timeline }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBTimelineItem>.self, forKey: .timeline)
        timeline = lossy?.elements
    }
}

struct TheSportsDBLineupResponse: Decodable {
    let lineup: [TheSportsDBLineupItem]?

    private enum CodingKeys: String, CodingKey { case lineup }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBLineupItem>.self, forKey: .lineup)
        lineup = lossy?.elements
    }
}

struct TheSportsDBPlayersResponse: Decodable {
    let player: [TheSportsDBPlayer]?
    let players: [TheSportsDBPlayer]?
    let playerhonours: [TheSportsDBPlayerHonour]?
    let milestones: [TheSportsDBPlayerMilestone]?

    private enum CodingKeys: String, CodingKey { case player, players, playerhonours, milestones }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        player = (try? container.decodeIfPresent(LossyArray<TheSportsDBPlayer>.self, forKey: .player))?.elements
        players = (try? container.decodeIfPresent(LossyArray<TheSportsDBPlayer>.self, forKey: .players))?.elements
        playerhonours = (try? container.decodeIfPresent(LossyArray<TheSportsDBPlayerHonour>.self, forKey: .playerhonours))?.elements
        milestones = (try? container.decodeIfPresent(LossyArray<TheSportsDBPlayerMilestone>.self, forKey: .milestones))?.elements
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

struct TheSportsDBLeagueDetailsResponse: Decodable {
    let leagues: [TheSportsDBLeagueDetail]?

    private enum CodingKeys: String, CodingKey { case leagues }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lossy = try? container.decodeIfPresent(LossyArray<TheSportsDBLeagueDetail>.self, forKey: .leagues)
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
    let strVideo: String?
    let strOfficial: String?
    let intSpectators: String?
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
        strVideo: String? = nil,
        strOfficial: String? = nil,
        intSpectators: String? = nil,
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
        self.strVideo = strVideo
        self.strOfficial = strOfficial
        self.intSpectators = intSpectators
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
        case strVideo, strOfficial, intSpectators
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
        strVideo = c.decodeLossyString(forKey: .strVideo)
        strOfficial = c.decodeLossyString(forKey: .strOfficial)
        intSpectators = c.decodeLossyString(forKey: .intSpectators)
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

struct TheSportsDBTimelineItem: Decodable, Identifiable {
    let idTimeline: String?
    let strTimeline: String?
    let strTimelineDetail: String?
    let strEvent: String?
    let strPlayer: String?
    let strPlayer2: String?
    let strTime: String?
    let intTime: String?
    let strTeam: String?
    let strType: String?

    var id: String { idTimeline ?? UUID().uuidString }

    private enum CodingKeys: String, CodingKey {
        case idTimeline, strTimeline, strTimelineDetail, strEvent, strPlayer, strPlayer2, strTime, intTime, strTeam, strType
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idTimeline = c.decodeLossyString(forKey: .idTimeline)
        strTimeline = c.decodeLossyString(forKey: .strTimeline)
        strTimelineDetail = c.decodeLossyString(forKey: .strTimelineDetail)
        strEvent = c.decodeLossyString(forKey: .strEvent)
        strPlayer = c.decodeLossyString(forKey: .strPlayer)
        strPlayer2 = c.decodeLossyString(forKey: .strPlayer2)
        strTime = c.decodeLossyString(forKey: .strTime)
        intTime = c.decodeLossyString(forKey: .intTime)
        strTeam = c.decodeLossyString(forKey: .strTeam)
        strType = c.decodeLossyString(forKey: .strType)
    }
}

struct TheSportsDBLineupItem: Decodable, Identifiable {
    let idLineup: String?
    let idPlayer: String?
    let idTeam: String?
    let strPlayer: String?
    let strPosition: String?
    let strFormation: String?
    let strSubstitute: String?
    let intSquadNumber: String?
    let strCutout: String?
    let strThumb: String?

    var id: String { idLineup ?? (idPlayer ?? UUID().uuidString) }

    private enum CodingKeys: String, CodingKey {
        case idLineup, idPlayer, idTeam, strPlayer, strPosition, strFormation, strSubstitute, intSquadNumber, strCutout, strThumb
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idLineup = c.decodeLossyString(forKey: .idLineup)
        idPlayer = c.decodeLossyString(forKey: .idPlayer)
        idTeam = c.decodeLossyString(forKey: .idTeam)
        strPlayer = c.decodeLossyString(forKey: .strPlayer)
        strPosition = c.decodeLossyString(forKey: .strPosition)
        strFormation = c.decodeLossyString(forKey: .strFormation)
        strSubstitute = c.decodeLossyString(forKey: .strSubstitute)
        intSquadNumber = c.decodeLossyString(forKey: .intSquadNumber)
        strCutout = c.decodeLossyString(forKey: .strCutout)
        strThumb = c.decodeLossyString(forKey: .strThumb)
    }
}

struct TheSportsDBPlayer: Decodable, Identifiable {
    let idPlayer: String
    let strPlayer: String?
    let strPosition: String?
    let strTeam: String?
    let strNationality: String?
    let dateBorn: String?
    let strDescriptionEN: String?
    let strThumb: String?
    let strCutout: String?

    var id: String { idPlayer }

    private enum CodingKeys: String, CodingKey {
        case idPlayer, strPlayer, strPosition, strTeam, strNationality, dateBorn, strDescriptionEN, strThumb, strCutout
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idPlayer = c.decodeLossyString(forKey: .idPlayer) ?? UUID().uuidString
        strPlayer = c.decodeLossyString(forKey: .strPlayer)
        strPosition = c.decodeLossyString(forKey: .strPosition)
        strTeam = c.decodeLossyString(forKey: .strTeam)
        strNationality = c.decodeLossyString(forKey: .strNationality)
        dateBorn = c.decodeLossyString(forKey: .dateBorn)
        strDescriptionEN = c.decodeLossyString(forKey: .strDescriptionEN)
        strThumb = c.decodeLossyString(forKey: .strThumb)
        strCutout = c.decodeLossyString(forKey: .strCutout)
    }
}

struct TheSportsDBPlayerHonour: Decodable, Identifiable {
    let id: String
    let strHonour: String?
    let strSeason: String?

    private enum CodingKeys: String, CodingKey { case id, strHonour, strSeason }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? UUID().uuidString
        strHonour = c.decodeLossyString(forKey: .strHonour)
        strSeason = c.decodeLossyString(forKey: .strSeason)
    }
}

struct TheSportsDBPlayerMilestone: Decodable, Identifiable {
    let id: String
    let strMilestone: String?
    let strSeason: String?

    private enum CodingKeys: String, CodingKey { case id, strMilestone, strSeason }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? UUID().uuidString
        strMilestone = c.decodeLossyString(forKey: .strMilestone)
        strSeason = c.decodeLossyString(forKey: .strSeason)
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

struct TheSportsDBLeagueDetail: Decodable {
    let idLeague: String?
    let strBadge: String?
    let strLogo: String?
    let strPoster: String?
    let strFanart1: String?
    let strBanner: String?

    private enum CodingKeys: String, CodingKey {
        case idLeague, strBadge, strLogo, strPoster, strFanart1, strBanner
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idLeague = c.decodeLossyString(forKey: .idLeague)
        strBadge = c.decodeLossyString(forKey: .strBadge)
        strLogo = c.decodeLossyString(forKey: .strLogo)
        strPoster = c.decodeLossyString(forKey: .strPoster)
        strFanart1 = c.decodeLossyString(forKey: .strFanart1)
        strBanner = c.decodeLossyString(forKey: .strBanner)
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
    let timeline: [TheSportsDBTimelineItem]
    let lineup: [TheSportsDBLineupItem]
    let h2hEvents: [TheSportsDBEvent]
    let leaguePastEvents: [TheSportsDBEvent]
    let previousEvents: [TheSportsDBEvent]
    let nextEvents: [TheSportsDBEvent]
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

struct TheSportsDBPlayerPayload {
    let player: TheSportsDBPlayer
    let honours: [TheSportsDBPlayerHonour]
    let milestones: [TheSportsDBPlayerMilestone]
}


protocol TheSportsDBServicing: Sendable {
    func fetchHomePayload() async throws -> TheSportsDBHomePayload
    func fetchHomePayload(sport: String) async throws -> TheSportsDBHomePayload
    func fetchHomePayload(leagueId: Int) async throws -> TheSportsDBHomePayload
    func fetchOverviewPayload(fixtureId: Int) async throws -> TheSportsDBOverviewPayload
    func fetchMatchesPayload(leagueId: Int) async throws -> TheSportsDBMatchesPayload
    func fetchMatchesPayload(sport: String) async throws -> TheSportsDBMatchesPayload
    func fetchSports() async throws -> [TheSportsDBSport]
    func fetchNews(for sport: String) async throws -> [TheSportsDBEvent]
    func fetchTeamProfile(teamId: Int) async throws -> TheSportsDBTeamProfilePayload
    func fetchTeamProfile(sport: String) async throws -> TheSportsDBTeamProfilePayload
    func fetchTeamProfile(leagueId: Int) async throws -> TheSportsDBTeamProfilePayload
    func fetchPlayer(playerId: Int) async throws -> TheSportsDBPlayerPayload
    func fetchPlayer(playerName: String) async throws -> TheSportsDBPlayerPayload
    func fetchTeamBadge(teamName: String) async -> String?
    func fetchTeamBadges(leagueName: String, sport: String) async -> [String: String]
    func fetchLeagueArtwork(leagueId: Int) async -> String?
    func fetchLeagueArtwork(leagueName: String, sport: String) async -> String?
    func fetchLeagueId(leagueName: String, sport: String) async -> Int?
}

private struct TheSportsDBEndpoint: Sendable {
    enum Version: Sendable, Hashable {
        case v1
        case v2
    }

    struct CachePolicy: Sendable {
        let ttl: TimeInterval
        let staleTTL: TimeInterval

        static let none = CachePolicy(ttl: 0, staleTTL: 0)

        static func timed(ttl: TimeInterval, staleTTL: TimeInterval) -> CachePolicy {
            CachePolicy(ttl: ttl, staleTTL: staleTTL)
        }
    }

    struct RetryPolicy: Sendable {
        let maxAttempts: Int
        let baseDelay: TimeInterval
        let maxDelay: TimeInterval

        static let standard = RetryPolicy(maxAttempts: 2, baseDelay: 0.25, maxDelay: 1.1)
        static let relaxed = RetryPolicy(maxAttempts: 3, baseDelay: 0.35, maxDelay: 1.8)
        static let none = RetryPolicy(maxAttempts: 1, baseDelay: 0, maxDelay: 0)
    }

    let version: Version
    let path: String
    let query: [(String, String)]
    let headers: [String: String]
    let timeout: TimeInterval
    let cachePolicy: CachePolicy
    let retryPolicy: RetryPolicy
}

private struct TheSportsDBRequestKey: Hashable, Sendable {
    let version: TheSportsDBEndpoint.Version
    let path: String
    let query: [String]
    let headers: [String]

    init(endpoint: TheSportsDBEndpoint) {
        version = endpoint.version
        path = endpoint.path
        query = endpoint.query.sorted { lhs, rhs in
            if lhs.0 == rhs.0 { return lhs.1 < rhs.1 }
            return lhs.0 < rhs.0
        }
        .map { "\($0.0)=\($0.1)" }
        headers = endpoint.headers.sorted { lhs, rhs in lhs.key < rhs.key }
            .map { "\($0.key)=\($0.value)" }
    }
}

private struct TheSportsDBCacheEntry: Sendable {
    let data: Data
    let expirationDate: Date
    let staleExpirationDate: Date

    func isFresh(at date: Date) -> Bool {
        date <= expirationDate
    }

    func canServeStale(at date: Date) -> Bool {
        date <= staleExpirationDate
    }
}

private enum TheSportsDBNetworkError: Error {
    case invalidURL
    case invalidResponse
    case unacceptableStatus(code: Int)
    case transport(URLError)
    case decoding(Error)
}

private actor TheSportsDBRequestLimiter {
    private let limit: Int
    private var available: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) {
        self.limit = max(1, limit)
        self.available = max(1, limit)
    }

    func withPermit<T>(_ operation: @Sendable () async throws -> T) async throws -> T {
        await acquire()
        defer { release() }
        return try await operation()
    }

    private func acquire() async {
        if available > 0 {
            available -= 1
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    private func release() {
        if let continuation = waiters.first {
            waiters.removeFirst()
            continuation.resume()
            return
        }
        available = min(limit, available + 1)
    }
}

private actor TheSportsDBHTTPClient {
    private let apiKey: String
    private let baseURL: String
    private let v2BaseURL: String
    private let session: URLSession
    private let limiter = TheSportsDBRequestLimiter(limit: 6)

    private var inFlight: [TheSportsDBRequestKey: Task<Data, Error>] = [:]
    private var cache: [TheSportsDBRequestKey: TheSportsDBCacheEntry] = [:]

    init(apiKey: String, baseURL: String, v2BaseURL: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.v2BaseURL = v2BaseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 16
        configuration.waitsForConnectivity = false
        configuration.httpMaximumConnectionsPerHost = 6
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(
            memoryCapacity: 16 * 1024 * 1024,
            diskCapacity: 64 * 1024 * 1024,
            diskPath: "TheSportsDBURLCache"
        )
        session = URLSession(configuration: configuration)
    }

    func request<T: Decodable>(_ endpoint: TheSportsDBEndpoint, as type: T.Type = T.self) async throws -> T {
        let data = try await data(for: endpoint)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw TheSportsDBNetworkError.decoding(error)
        }
    }

    func data(for endpoint: TheSportsDBEndpoint) async throws -> Data {
        let key = TheSportsDBRequestKey(endpoint: endpoint)
        let now = Date()

        if let entry = cache[key], entry.isFresh(at: now) {
            return entry.data
        }

        if let task = inFlight[key] {
            do {
                return try await task.value
            } catch {
                if let stale = cache[key], stale.canServeStale(at: Date()) {
                    return stale.data
                }
                throw error
            }
        }

        let session = self.session
        let requestBuilder = makeURLRequest(for: endpoint)
        let limiter = self.limiter
        let task = Task<Data, Error> {
            let request = try requestBuilder()
            return try await Self.performRequest(
                with: session,
                limiter: limiter,
                request: request,
                retryPolicy: endpoint.retryPolicy
            )
        }

        inFlight[key] = task

        do {
            let data = try await task.value
            inFlight[key] = nil
            storeCachedResponse(data, for: key, policy: endpoint.cachePolicy)
            return data
        } catch {
            inFlight[key] = nil
            if let stale = cache[key], stale.canServeStale(at: Date()) {
                return stale.data
            }
            throw error
        }
    }

    private func makeURLRequest(for endpoint: TheSportsDBEndpoint) -> @Sendable () throws -> URLRequest {
        let apiKey = self.apiKey
        let baseURL = self.baseURL
        let v2BaseURL = self.v2BaseURL

        return {
            let rawBaseURL: String
            switch endpoint.version {
            case .v1:
                rawBaseURL = "\(baseURL)/\(apiKey)/\(endpoint.path)"
            case .v2:
                rawBaseURL = "\(v2BaseURL)/\(endpoint.path)"
            }

            var components = URLComponents(string: rawBaseURL)
            if !endpoint.query.isEmpty {
                components?.queryItems = endpoint.query.map { URLQueryItem(name: $0.0, value: $0.1) }
            }

            guard let url = components?.url else {
                throw TheSportsDBNetworkError.invalidURL
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = endpoint.timeout
            for (header, value) in endpoint.headers {
                request.setValue(value, forHTTPHeaderField: header)
            }
            return request
        }
    }

    private func storeCachedResponse(
        _ data: Data,
        for key: TheSportsDBRequestKey,
        policy: TheSportsDBEndpoint.CachePolicy
    ) {
        guard policy.ttl > 0 else { return }

        let now = Date()
        cache[key] = TheSportsDBCacheEntry(
            data: data,
            expirationDate: now.addingTimeInterval(policy.ttl),
            staleExpirationDate: now.addingTimeInterval(policy.ttl + max(0, policy.staleTTL))
        )

        if cache.count > 256 {
            pruneCache(referenceDate: now)
        }
    }

    private func pruneCache(referenceDate: Date) {
        cache = cache.filter { $0.value.canServeStale(at: referenceDate) }
    }

    private static func performRequest(
        with session: URLSession,
        limiter: TheSportsDBRequestLimiter,
        request: URLRequest,
        retryPolicy: TheSportsDBEndpoint.RetryPolicy
    ) async throws -> Data {
        var lastError: Error?

        for attempt in 0..<max(1, retryPolicy.maxAttempts) {
            do {
                return try await limiter.withPermit {
                    let (data, response) = try await session.data(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw TheSportsDBNetworkError.invalidResponse
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        throw TheSportsDBNetworkError.unacceptableStatus(code: http.statusCode)
                    }
                    return data
                }
            } catch let error as CancellationError {
                throw error
            } catch {
                lastError = normalize(error)
                let shouldRetry = attempt < retryPolicy.maxAttempts - 1 && Self.shouldRetry(lastError)
                guard shouldRetry else { break }
                let delay = backoffDelay(forAttempt: attempt, policy: retryPolicy)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? URLError(.unknown)
    }

    private static func normalize(_ error: Error) -> Error {
        if let networkError = error as? TheSportsDBNetworkError {
            return networkError
        }
        if let urlError = error as? URLError {
            return TheSportsDBNetworkError.transport(urlError)
        }
        return error
    }

    private static func shouldRetry(_ error: Error?) -> Bool {
        guard let error else { return false }

        switch error {
        case TheSportsDBNetworkError.transport(let urlError):
            return [
                .timedOut,
                .networkConnectionLost,
                .notConnectedToInternet,
                .cannotConnectToHost,
                .cannotFindHost,
                .dnsLookupFailed,
                .resourceUnavailable,
                .internationalRoamingOff
            ].contains(urlError.code)
        case TheSportsDBNetworkError.unacceptableStatus(let code):
            return code == 408 || code == 425 || code == 429 || (500...599).contains(code)
        default:
            return false
        }
    }

    private static func backoffDelay(
        forAttempt attempt: Int,
        policy: TheSportsDBEndpoint.RetryPolicy
    ) -> TimeInterval {
        guard policy.baseDelay > 0 else { return 0 }
        let exponential = min(policy.maxDelay, policy.baseDelay * pow(2, Double(attempt)))
        let jitter = Double.random(in: 0.85...1.15)
        return exponential * jitter
    }
}

private actor TheSportsDBAssetStore {
    private var badgeCache: [String: String] = [:]
    private var leagueArtworkCache: [Int: String] = [:]
    private var leagueIdCache: [String: Int] = [:]

    func badge(for teamName: String) -> String? {
        badgeCache[normalizedName(teamName)]
    }

    func cacheBadge(_ badge: String, for teamName: String) {
        badgeCache[normalizedName(teamName)] = badge
    }

    func cacheBadges(_ badges: [String: String]) {
        for (name, badge) in badges {
            badgeCache[normalizedName(name)] = badge
        }
    }

    func leagueArtwork(for leagueId: Int) -> String? {
        leagueArtworkCache[leagueId]
    }

    func cacheLeagueArtwork(_ artwork: String, for leagueId: Int) {
        leagueArtworkCache[leagueId] = artwork
    }

    func leagueId(for leagueName: String, sport: String?) -> Int? {
        leagueIdCache[leagueKey(name: leagueName, sport: sport)]
    }

    func cacheLeagueId(_ leagueId: Int, for leagueName: String, sport: String?) {
        leagueIdCache[leagueKey(name: leagueName, sport: sport)] = leagueId
    }

    private func normalizedName(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func leagueKey(name: String, sport: String?) -> String {
        "\(normalizedName(name))|\(normalizedName(sport ?? ""))"
    }
}

final class LiveTheSportsDBService: TheSportsDBServicing, @unchecked Sendable {
    static let shared = LiveTheSportsDBService(apiKey: "138900")

    private let apiKey: String
    private static let baseURL = "https://www.thesportsdb.com/api/v1/json"
    private static let v2BaseURL = "https://www.thesportsdb.com/api/v2/json"
    private let client: TheSportsDBHTTPClient
    private let assetStore = TheSportsDBAssetStore()

    init(apiKey: String) {
        self.apiKey = apiKey
        self.client = TheSportsDBHTTPClient(
            apiKey: apiKey,
            baseURL: Self.baseURL,
            v2BaseURL: Self.v2BaseURL
        )
    }

    func fetchHomePayload() async throws -> TheSportsDBHomePayload {
        try await fetchHomePayload(sport: "Soccer")
    }

    func fetchHomePayload(sport: String) async throws -> TheSportsDBHomePayload {
        let safeSport = normalizedSport(sport)
        async let eventBucketsResult: ([TheSportsDBEvent], [TheSportsDBEvent])? = try? await fetchSportEventBuckets(sport: safeSport)
        async let fetchedNewsResult: [TheSportsDBEvent]? = try? await fetchNews(for: safeSport)

        let (today, yesterday) = await eventBucketsResult ?? ([], [])
        let fetchedNews = await fetchedNewsResult ?? []
        let news = fetchedNews.isEmpty ? uniqueEvents(today + yesterday) : fetchedNews

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

    func fetchHomePayload(leagueId: Int) async throws -> TheSportsDBHomePayload {
        async let pastEvents = fetchEvents(path: "eventspastleague.php", query: [("id", "\(leagueId)")])
        async let nextEvents = fetchEvents(path: "eventsnextleague.php", query: [("id", "\(leagueId)")])
        let past = (try? await pastEvents) ?? []
        let next = (try? await nextEvents) ?? []
        let combined = next + past
        let featured = combined.first ?? fallbackEvent(id: "1001")
        let stats = await statsForFirstAvailableEvent(events: combined)

        return TheSportsDBHomePayload(
            featured: featured,
            todaysMatches: Array(next.prefix(10)),
            recentMatches: Array(past.prefix(10)),
            stats: stats,
            news: Array(combined.prefix(10))
        )
    }

    func fetchOverviewPayload(fixtureId: Int) async throws -> TheSportsDBOverviewPayload {
        let events = (try? await fetchEvents(path: "lookupevent.php", query: [("id", "\(fixtureId)")])) ?? []
        let event = events.first ?? fallbackEvent(id: "\(fixtureId)")

        async let timelineRows = fetchTimeline(eventId: event.idEvent)
        async let lineupRows = fetchLineup(eventId: event.idEvent)
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
                    let neighbors = (try? await fetchEvents(
                        path: "eventspastleague.php",
                        query: [("id", "\(leagueId)")],
                        timeout: 6
                    )) ?? []
                    let sampled = Array(([event] + neighbors).prefix(12))
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

        return TheSportsDBOverviewPayload(
            event: event,
            stats: stats,
            statsSource: source,
            timeline: await timelineRows,
            lineup: await lineupRows,
            h2hEvents: [],
            leaguePastEvents: [],
            previousEvents: [],
            nextEvents: []
        )
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
            finals: Array(past.prefix(10)),
            upcoming: Array(next.prefix(10)),
            stats: stats,
            standings: table
        )
    }

    func fetchMatchesPayload(sport: String) async throws -> TheSportsDBMatchesPayload {
        let safeSport = normalizedSport(sport)
        async let eventBucketsResult: ([TheSportsDBEvent], [TheSportsDBEvent])? = try? await fetchSportEventBuckets(sport: safeSport)
        async let tomorrowResult: [TheSportsDBEvent]? = try? await fetchDayEvents(sport: safeSport, offsetDays: 1)

        let (today, yesterday) = await eventBucketsResult ?? ([], [])
        let tomorrow = await tomorrowResult ?? []

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
        let safeSport = normalizedSport(sport).replacingOccurrences(of: " ", with: "_")
        let offsets = [0, -1, -2, -3, 1]
        let aggregated = await withTaskGroup(of: [TheSportsDBEvent].self) { group in
            for offset in offsets {
                let day = dateString(offsetDays: offset)
                group.addTask { [self] in
                    async let highlightsResponse: TheSportsDBEventsResponse? = try? await request(
                        path: "eventshighlights.php",
                        query: [("d", day), ("s", safeSport)]
                    )
                    async let eventsResponse: TheSportsDBEventsResponse? = try? await request(
                        path: "eventsday.php",
                        query: [("d", day), ("s", safeSport)]
                    )
                    let highlights = await highlightsResponse?.events ?? []
                    let events = await eventsResponse?.events ?? []
                    return highlights + events
                }
            }

            var combined: [TheSportsDBEvent] = []
            for await chunk in group {
                combined.append(contentsOf: chunk)
            }
            return combined
        }

        let unique = uniqueEvents(aggregated)
        return unique.sorted { lhs, rhs in
            let leftDate = parseNewsDate(event: lhs) ?? .distantPast
            let rightDate = parseNewsDate(event: rhs) ?? .distantPast
            return leftDate > rightDate
        }
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
            return try await fetchTeamProfile(teamId: 133604)
        }

        let countries = ["England", "United States", "Spain", "Germany", "Italy", "France"]
        var selectedTeam = await withTaskGroup(of: TheSportsDBTeam?.self) { group in
            for country in countries {
                group.addTask { [self] in
                    let teams = try? await fetchTeams(
                        path: "search_all_teams.php",
                        query: [("s", safeSport), ("c", country)]
                    )
                    return teams?.first
                }
            }

            for await team in group {
                if let team {
                    return Optional(team)
                }
            }
            return Optional<TheSportsDBTeam>.none
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

    func fetchTeamProfile(leagueId: Int) async throws -> TheSportsDBTeamProfilePayload {
        async let pastEvents: [TheSportsDBEvent]? = try? await fetchEvents(
            path: "eventspastleague.php",
            query: [("id", "\(leagueId)")]
        )
        async let nextEvents: [TheSportsDBEvent]? = try? await fetchEvents(
            path: "eventsnextleague.php",
            query: [("id", "\(leagueId)")]
        )
        let past = await pastEvents ?? []
        let next = await nextEvents ?? []
        let candidate = (past + next).first
        let teamId = Int(candidate?.idHomeTeam ?? "") ?? Int(candidate?.idAwayTeam ?? "") ?? 133604
        return try await fetchTeamProfile(teamId: teamId)
    }

    func fetchPlayer(playerId: Int) async throws -> TheSportsDBPlayerPayload {
        let playersResponse: TheSportsDBPlayersResponse = try await request(
            path: "lookupplayer.php",
            query: [("id", "\(playerId)")]
        )
        guard let player = (playersResponse.player?.first ?? playersResponse.players?.first) else {
            throw URLError(.cannotParseResponse)
        }
        let honoursResponse: TheSportsDBPlayersResponse? = try? await request(
            path: "lookuphonours.php",
            query: [("id", "\(playerId)")]
        )
        let milestonesResponse: TheSportsDBPlayersResponse? = try? await request(
            path: "lookupmilestones.php",
            query: [("id", "\(playerId)")]
        )
        return TheSportsDBPlayerPayload(
            player: player,
            honours: honoursResponse?.playerhonours ?? [],
            milestones: milestonesResponse?.milestones ?? []
        )
    }

    func fetchPlayer(playerName: String) async throws -> TheSportsDBPlayerPayload {
        let safeName = playerName.replacingOccurrences(of: " ", with: "_")
        let playersResponse: TheSportsDBPlayersResponse = try await request(
            path: "searchplayers.php",
            query: [("p", safeName)]
        )
        guard let player = (playersResponse.player?.first ?? playersResponse.players?.first),
              let playerId = Int(player.idPlayer) else {
            throw URLError(.cannotParseResponse)
        }
        return try await fetchPlayer(playerId: playerId)
    }

    func fetchTeamBadge(teamName: String) async -> String? {
        if let cached = await assetStore.badge(for: teamName) {
            return cached
        }
        do {
            let safeName = teamName.replacingOccurrences(of: " ", with: "_")
            let teams = try await fetchTeams(path: "searchteams.php", query: [("t", safeName)])
            let badge = teams.first?.strBadge
            if let badge {
                await assetStore.cacheBadge(badge, for: teamName)
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
                    }
                }
                await assetStore.cacheBadges(out)
                return out
            }
        } catch { }

        let countries = ["England", "Spain", "Italy", "Germany", "France", "United States"]
        let fallback = await withTaskGroup(of: [String: String].self) { group in
            for country in countries {
                group.addTask { [self] in
                    let teams = try? await fetchTeams(
                        path: "search_all_teams.php",
                        query: [("s", sport), ("c", country)]
                    )
                    var out: [String: String] = [:]
                    for team in teams ?? [] {
                        if let name = team.strTeam, let badge = team.strBadge {
                            out[name] = badge
                        }
                    }
                    return out
                }
            }

            for await badges in group {
                if !badges.isEmpty {
                    return badges
                }
            }
            return [:]
        }

        if !fallback.isEmpty {
            await assetStore.cacheBadges(fallback)
        }
        return fallback
    }

    func fetchLeagueArtwork(leagueId: Int) async -> String? {
        if let cached = await assetStore.leagueArtwork(for: leagueId) {
            return cached
        }

        do {
            let response: TheSportsDBLeagueDetailsResponse = try await request(
                path: "lookupleague.php",
                query: [("id", "\(leagueId)")]
            )
            guard let league = response.leagues?.first else { return nil }
            let artwork = [
                league.strFanart1,
                league.strPoster,
                league.strBanner,
                league.strBadge,
                league.strLogo
            ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty })

            if let artwork {
                await assetStore.cacheLeagueArtwork(artwork, for: leagueId)
            }
            return artwork
        } catch {
            return nil
        }
    }

    func fetchLeagueArtwork(leagueName: String, sport: String) async -> String? {
        let leagueId = await resolveLeagueId(
            idLeague: nil,
            leagueName: leagueName,
            sport: sport
        )
        guard let leagueId else { return nil }
        return await fetchLeagueArtwork(leagueId: leagueId)
    }

    func fetchLeagueId(leagueName: String, sport: String) async -> Int? {
        await resolveLeagueId(
            idLeague: nil,
            leagueName: leagueName,
            sport: sport
        )
    }


    private func fetchEvents(
        path: String,
        query: [(String, String)],
        timeout: TimeInterval = 10
    ) async throws -> [TheSportsDBEvent] {
        let response: TheSportsDBEventsResponse = try await request(
            path: path,
            query: query,
            timeout: timeout
        )
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

    private func fetchTimeline(eventId: String) async -> [TheSportsDBTimelineItem] {
        guard eventId != "0" else { return [] }
        let response: TheSportsDBTimelineResponse? = try? await request(
            path: "lookuptimeline.php",
            query: [("id", eventId)]
        )
        return response?.timeline ?? []
    }

    private func fetchLineup(eventId: String) async -> [TheSportsDBLineupItem] {
        guard eventId != "0" else { return [] }
        let response: TheSportsDBLineupResponse? = try? await request(
            path: "lookuplineup.php",
            query: [("id", eventId)]
        )
        return response?.lineup ?? []
    }

    private func fetchSportEventBuckets(sport: String) async throws -> ([TheSportsDBEvent], [TheSportsDBEvent]) {
        let preferredIds = preferredLeagueIds(for: sport)
        var today: [TheSportsDBEvent] = []
        var yesterday: [TheSportsDBEvent] = []

        if !preferredIds.isEmpty {
            let leagueBuckets = await withTaskGroup(of: ([TheSportsDBEvent], [TheSportsDBEvent]).self) { group in
                for leagueId in preferredIds {
                    group.addTask { [self] in
                        async let past = try? await fetchEvents(path: "eventspastleague.php", query: [("id", "\(leagueId)")])
                        async let next = try? await fetchEvents(path: "eventsnextleague.php", query: [("id", "\(leagueId)")])
                        return ((await next ?? []), (await past ?? []))
                    }
                }

                var result: [([TheSportsDBEvent], [TheSportsDBEvent])] = []
                for await bucket in group {
                    result.append(bucket)
                }
                return result
            }

            for (next, past) in leagueBuckets {
                yesterday.append(contentsOf: past.prefix(3))
                today.append(contentsOf: next.prefix(3))
            }
        }

        if today.isEmpty {
            async let day0 = try? fetchDayEvents(sport: sport, offsetDays: 0)
            async let dayPlus1 = try? fetchDayEvents(sport: sport, offsetDays: 1)
            today.append(contentsOf: (await day0) ?? [])
            today.append(contentsOf: (await dayPlus1) ?? [])
        }

        if yesterday.isEmpty {
            let dayMinus1 = (try? await fetchDayEvents(sport: sport, offsetDays: -1)) ?? []
            yesterday.append(contentsOf: dayMinus1)
        }

        if today.isEmpty && yesterday.isEmpty {
            let day0 = (try? await fetchDayEvents(sport: sport, offsetDays: 0)) ?? []
            let dayMinus1 = (try? await fetchDayEvents(sport: sport, offsetDays: -1)) ?? []
            let dayPlus1 = (try? await fetchDayEvents(sport: sport, offsetDays: 1)) ?? []
            today = day0 + dayPlus1
            yesterday = dayMinus1
        }

        return (uniqueEvents(today), uniqueEvents(yesterday))
    }

    private func uniqueEvents(_ events: [TheSportsDBEvent]) -> [TheSportsDBEvent] {
        var seen = Set<String>()
        var out: [TheSportsDBEvent] = []
        for event in events {
            guard hasUsableTeams(event) else { continue }
            if seen.insert(eventIdentity(event)).inserted {
                out.append(event)
            }
        }
        return out
    }

    private func fetchHeadToHeadEvents(
        homeName: String,
        awayName: String,
        excludingEventId: String
    ) async -> [TheSportsDBEvent] {
        guard !homeName.isEmpty, !awayName.isEmpty else { return [] }

        let directQuery = matchupQuery(homeName: homeName, awayName: awayName)
        let reverseQuery = matchupQuery(homeName: awayName, awayName: homeName)

        async let directMatches = fetchEvents(path: "searchevents.php", query: [("e", directQuery)])
        async let reverseMatches = fetchEvents(path: "searchevents.php", query: [("e", reverseQuery)])

        let combined = ((try? await directMatches) ?? []) + ((try? await reverseMatches) ?? [])
        let filtered = uniqueEvents(combined).filter { event in
            guard event.idEvent != excludingEventId else { return false }
            let left = canonicalTeamName(event.strHomeTeam)
            let right = canonicalTeamName(event.strAwayTeam)
            let home = canonicalTeamName(homeName)
            let away = canonicalTeamName(awayName)
            return (left == home && right == away) || (left == away && right == home)
        }

        print(
            "[H2H] pair-search home=\(homeName) away=\(awayName) direct=\(directQuery) reverse=\(reverseQuery) " +
            "raw=\(combined.count) unique=\(uniqueEvents(combined).count) matched=\(filtered.count)"
        )

        return filtered.sorted {
            ($0.dateEvent ?? "") > ($1.dateEvent ?? "")
        }
    }

    private func matchupQuery(homeName: String, awayName: String) -> String {
        "\(homeName)_vs_\(awayName)"
            .replacingOccurrences(of: " ", with: "_")
    }

    private func canonicalTeamName(_ name: String?) -> String {
        let lowered = (name ?? "")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        return String(lowered.filter { allowed.contains($0) })
    }

    private func hasUsableTeams(_ event: TheSportsDBEvent) -> Bool {
        let home = canonicalTeamName(event.strHomeTeam)
        let away = canonicalTeamName(event.strAwayTeam)
        guard !home.isEmpty, !away.isEmpty else { return false }
        let invalid = Set(["home", "away", "team", "tbd", "vs"])
        return !invalid.contains(home) && !invalid.contains(away)
    }

    private func eventIdentity(_ event: TheSportsDBEvent) -> String {
        let eventId = event.idEvent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !eventId.isEmpty, eventId != "0" {
            return eventId
        }

        return [
            canonicalTeamName(event.strHomeTeam),
            canonicalTeamName(event.strAwayTeam),
            canonicalTeamName(event.strLeague),
            event.dateEvent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            event.strTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        ].joined(separator: "|")
    }

    private func preferredLeagueIds(for sport: String) -> [Int] {
        switch normalizedSport(sport).lowercased() {
        case "soccer":
            return [4328, 4335, 4331, 4332, 4334]
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
        let response: TheSportsDBEventStatsResponse? = try? await request(
            path: "lookupeventstats.php",
            query: [("id", eventId)]
        )
        let v1 = response?.eventstats ?? []

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
                "Goalkeeper Saves", "Total Passes", "Passes Accurate", "Passes %",
                "Expected Goals", "Goals Prevented"
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
                "totalpasses": "Total Passes",
                "passesaccurate": "Passes Accurate",
                "passes": "Passes %",
                "expectedgoals": "Expected Goals",
                "expectedgoalsxg": "Expected Goals",
                "goalsprevented": "Goals Prevented"
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

    private func request<T: Decodable>(
        path: String,
        query: [(String, String)],
        cachePolicy: TheSportsDBEndpoint.CachePolicy? = nil,
        retryPolicy: TheSportsDBEndpoint.RetryPolicy? = nil,
        timeout: TimeInterval = 15
    ) async throws -> T {
        let endpoint = TheSportsDBEndpoint(
            version: .v1,
            path: path,
            query: query,
            headers: [:],
            timeout: timeout,
            cachePolicy: cachePolicy ?? defaultCachePolicy(for: path, version: .v1),
            retryPolicy: retryPolicy ?? defaultRetryPolicy(for: path, version: .v1)
        )
        do {
            return try await client.request(endpoint, as: T.self)
        } catch {
            throw mapNetworkError(error)
        }
    }

    private func requestDataV2(
        path: String,
        query: [(String, String)] = [],
        headers: [String: String] = [:],
        cachePolicy: TheSportsDBEndpoint.CachePolicy? = nil,
        retryPolicy: TheSportsDBEndpoint.RetryPolicy? = nil,
        timeout: TimeInterval = 15
    ) async throws -> Data {
        let endpoint = TheSportsDBEndpoint(
            version: .v2,
            path: path,
            query: query,
            headers: headers,
            timeout: timeout,
            cachePolicy: cachePolicy ?? defaultCachePolicy(for: path, version: .v2),
            retryPolicy: retryPolicy ?? defaultRetryPolicy(for: path, version: .v2)
        )
        do {
            return try await client.data(for: endpoint)
        } catch {
            throw mapNetworkError(error)
        }
    }

    private func defaultCachePolicy(
        for path: String,
        version: TheSportsDBEndpoint.Version
    ) -> TheSportsDBEndpoint.CachePolicy {
        if version == .v2, path.hasPrefix("lookup/event_stats/") {
            return .timed(ttl: 30, staleTTL: 120)
        }

        switch (version, path) {
        case (.v1, "all_sports.php"), (.v1, "all_leagues.php"):
            return .timed(ttl: 86_400, staleTTL: 604_800)
        case (.v1, "lookupteam.php"),
             (.v1, "searchteams.php"),
             (.v1, "search_all_teams.php"),
             (.v1, "lookupleague.php"),
             (.v1, "lookupplayer.php"),
             (.v1, "lookuphonours.php"),
             (.v1, "lookupmilestones.php"),
             (.v1, "searchplayers.php"):
            return .timed(ttl: 21_600, staleTTL: 172_800)
        case (.v1, "lookuptable.php"):
            return .timed(ttl: 180, staleTTL: 900)
        case (.v1, "lookupevent.php"),
             (.v1, "lookuptimeline.php"),
             (.v1, "lookuplineup.php"),
             (.v1, "lookupeventstats.php"):
            return .timed(ttl: 30, staleTTL: 120)
        case (.v1, "eventsday.php"),
             (.v1, "eventshighlights.php"),
             (.v1, "eventspastleague.php"),
             (.v1, "eventsnextleague.php"),
             (.v1, "eventslast.php"),
             (.v1, "eventsnext.php"),
             (.v1, "searchevents.php"):
            return .timed(ttl: 60, staleTTL: 300)
        default:
            return .timed(ttl: 60, staleTTL: 300)
        }
    }

    private func defaultRetryPolicy(
        for path: String,
        version: TheSportsDBEndpoint.Version
    ) -> TheSportsDBEndpoint.RetryPolicy {
        if version == .v2, path.hasPrefix("lookup/event_stats/") {
            return .relaxed
        }

        switch (version, path) {
        case (.v1, "all_leagues.php"), (.v1, "lookuptable.php"), (.v1, "lookupeventstats.php"):
            return .relaxed
        default:
            return .standard
        }
    }

    private func mapNetworkError(_ error: Error) -> Error {
        switch error {
        case TheSportsDBNetworkError.invalidURL:
            return URLError(.badURL)
        case TheSportsDBNetworkError.invalidResponse,
             TheSportsDBNetworkError.unacceptableStatus:
            return URLError(.badServerResponse)
        case TheSportsDBNetworkError.transport(let urlError):
            return urlError
        case TheSportsDBNetworkError.decoding:
            return URLError(.cannotDecodeRawData)
        default:
            return error
        }
    }

    private func fetchEventStatsV2(eventId: String) async -> [TheSportsDBEventStat] {
        do {
            let data = try await requestDataV2(
                path: "lookup/event_stats/\(eventId)",
                headers: ["X-API-KEY": apiKey],
                cachePolicy: .timed(ttl: 30, staleTTL: 120),
                retryPolicy: .relaxed
            )
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

        if let cached = await assetStore.leagueId(for: leagueName, sport: sport) {
            return cached
        }

        let response: TheSportsDBLeaguesResponse? = try? await request(path: "all_leagues.php", query: [])
        guard let leagues = response?.leagues else { return nil }

        let normalizedLeague = leagueName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSport = sport?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if let exact = leagues.first(where: {
            ($0.strLeague?.lowercased() == normalizedLeague)
            && (normalizedSport == nil || $0.strSport?.lowercased() == normalizedSport)
        }), let id = Int(exact.idLeague) {
            await assetStore.cacheLeagueId(id, for: leagueName, sport: sport)
            return id
        }

        if let loose = leagues.first(where: { $0.strLeague?.lowercased() == normalizedLeague }),
           let id = Int(loose.idLeague) {
            await assetStore.cacheLeagueId(id, for: leagueName, sport: sport)
            return id
        }

        return nil
    }

    private func parseNewsDate(event: TheSportsDBEvent) -> Date? {
        guard let date = event.dateEvent else { return nil }
        let rawTime = event.strTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "00:00:00"

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let isoDate = isoFormatter.date(from: "\(date)T\(rawTime)") {
            return isoDate
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let isoDate = isoFormatter.date(from: "\(date)T\(rawTime)") {
            return isoDate
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let fullDate = formatter.date(from: "\(date) \(rawTime.replacingOccurrences(of: "Z", with: ""))") {
            return fullDate
        }

        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
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
