# SportsDataIO NFL API - Complete Reference Guide

## PURPOSE
This document provides complete knowledge of SportsDataIO's NFL API to answer ANY NFL-related question accurately. It maps question types to specific endpoints and provides reasoning rules to prevent inference errors.

**CRITICAL PRINCIPLE:** Always fetch data from the appropriate endpoint. Never infer or guess when definitive data exists.

---

## TABLE OF CONTENTS
1. [Critical Reasoning Rules](#critical-reasoning-rules)
2. [API Basics](#api-basics)
3. [Question → Endpoint Quick Reference](#question-endpoint-quick-reference)
4. [Competition Feeds](#competition-feeds)
5. [Event Feeds](#event-feeds)
6. [Player Feeds](#player-feeds)
7. [Betting Feeds](#betting-feeds)
8. [Fantasy Feeds](#fantasy-feeds)
9. [News & Media](#news-media)
10. [Utility Endpoints](#utility-endpoints)
11. [Data Reasoning Patterns](#data-reasoning-patterns)
12. [Edge Cases & Gotchas](#edge-cases)

---

## CRITICAL REASONING RULES

### RULE 1: USE DEFINITIVE FIELDS, NEVER INFER
| Question Type | WRONG Approach | RIGHT Approach |
|--------------|----------------|----------------|
| Playoff status | Infer from W-L record | Check `DivisionRank`, `ConferenceRank` |
| Game final? | Check if 4th quarter ended | Check `IsClosed === true` |
| Player injured? | Assume from news | Check `InjuryStatus` field |
| Player starting? | Guess from depth | Check `DepthOrder === 1` |
| Bet result | Calculate manually | Use Betting Results endpoint |

### RULE 2: DIVISION WINNERS ALWAYS MAKE PLAYOFFS
`DivisionRank === 1` = automatic playoff berth, regardless of record.
Example: 8-9 team can make playoffs if they won their division.

### RULE 3: COMBINE ENDPOINTS FOR COMPLETE ANSWERS
Many questions require multiple endpoint calls:
- "How did injured players do?" → Injuries + PlayerGameStats
- "Playoff team's schedule" → Standings + Schedules
- "Best value DFS picks" → Projections + DFS Slates + Injuries

### RULE 4: CHECK DATA FRESHNESS
- Live scores: 15-20 sec delay
- Final stats: 5-10 min post-game
- Season stats: ~1 hour post-game
- Stat corrections: Thursday morning

### RULE 5: HANDLE NULLS GRACEFULLY
Many fields can be null (game not started, data not available). Always check before making claims.

---

## API BASICS

### Base URL
```
https://api.sportsdata.io/v3/nfl/{format}/
```
- `{format}` = `json` or `xml`

### Authentication
```
Header: Ocp-Apim-Subscription-Key: {your-api-key}
OR
Query: ?key={your-api-key}
```

### Season Types
| Value | Meaning |
|-------|---------|
| 1 | Regular Season |
| 2 | Preseason |
| 3 | Postseason |
| 4 | Offseason |
| 5 | All-Star (Pro Bowl) |

### Week Numbers
- Regular Season: 1-18
- Preseason: 0-4 (0-3 after 2021)
- Postseason: 1-4 (Wild Card, Divisional, Conference, Super Bowl)

---

## QUESTION → ENDPOINT QUICK REFERENCE

### Standings & Playoffs
| Question | Endpoint(s) |
|----------|-------------|
| Did team X make playoffs? | `Standings/{season}` → check `ConferenceRank ≤ 7` |
| Who won NFC East? | `Standings/{season}` → filter `Division="East"`, `Conference="NFC"`, `DivisionRank=1` |
| What's team X's record? | `Standings/{season}` |
| What seed is team X? | `Standings/{season}` → `ConferenceRank` field |
| Wild card teams? | `Standings/{season}` → `ConferenceRank` 5, 6, 7 |
| Division standings? | `Standings/{season}` → filter by Division |
| Playoff picture? | `Standings/{season}` → both conferences, rank ≤ 7 |

### Games & Scores
| Question | Endpoint(s) |
|----------|-------------|
| What's the score? | `ScoresByWeek/{season}/{week}` or `BoxScore/{scoreid}` |
| Who plays today? | `ScoresByDate/{date}` |
| Week X schedule? | `ScoresByWeek/{season}/{week}` |
| Full season schedule? | `Schedules/{season}` |
| Is game final? | Check `IsClosed === true` in Scores |
| What channel? | `Schedules` → `Channel` field |
| Game in progress? | `Scores` → `Status === "InProgress"` |
| Overtime games? | `Scores` → `IsOvertime === true` |
| Final score with quarters? | `BoxScore/{scoreid}` → includes quarter breakdown |

### Player Stats
| Question | Endpoint(s) |
|----------|-------------|
| How did player X do? | `PlayerGameStatsByPlayer/{season}/{week}/{playerid}` |
| Week X stats all players? | `PlayerGameStatsByWeek/{season}/{week}` |
| Season leaders? | `PlayerSeasonStats/{season}` → sort by stat |
| Career stats? | Multiple `PlayerSeasonStats` calls by year |
| Team's players stats? | `PlayerSeasonStatsByTeam/{season}/{team}` |
| Red zone stats? | `PlayerGameStats` → `RushingYardsInsideRedZone`, `ReceivingYardsInsideRedZone`, etc. |
| Snap counts? | `PlayerGameStats` → `SnapCounts` (available morning after games) |

### Team Stats
| Question | Endpoint(s) |
|----------|-------------|
| Team offensive stats? | `TeamSeasonStats/{season}` |
| Team vs team comparison? | `TeamSeasonStats` for both teams |
| Week X team stats? | `TeamGameStats/{season}/{week}` |
| Defensive rankings? | `TeamSeasonStats` → sort by defensive fields |
| Turnover differential? | `TeamSeasonStats` → `TurnoverDifferential` |
| Points per game? | `TeamSeasonStats` → `Score / Games` |

### Injuries
| Question | Endpoint(s) |
|----------|-------------|
| Is player X injured? | `Injuries/{season}/{week}` or `Player/{playerid}` |
| Team injuries? | `InjuriesByTeam/{season}/{week}/{team}` |
| Who's out this week? | `Injuries` → `InjuryStatus === "Out"` |
| Questionable players? | `Injuries` → `InjuryStatus === "Questionable"` |

### Betting & Odds
| Question | Endpoint(s) |
|----------|-------------|
| Point spread? | `GameOddsByWeek/{season}/{week}` |
| Moneyline? | `GameOddsByWeek` → `HomeMoneyLine`, `AwayMoneyLine` |
| Over/under? | `GameOddsByWeek` → `OverUnder` |
| Line movement? | `GameOddsLineMovement/{scoreid}` |
| Player props? | `BettingPlayerPropsByGameID/{gameid}` |

---

## STANDINGS - KEY FIELDS

**Endpoint:** `GET /Standings/{season}`

| Field | Type | Description | Reasoning Rule |
|-------|------|-------------|----------------|
| `Team` | string | Team abbreviation | |
| `Wins` | int | Total wins | NOT definitive for playoffs |
| `Losses` | int | Total losses | NOT definitive for playoffs |
| `Ties` | int | Total ties | |
| `Percentage` | decimal | Win percentage | |
| `DivisionRank` | int | Rank in division | **1 = DIVISION WINNER = PLAYOFFS** |
| `ConferenceRank` | int | Rank in conference | **1-7 = PLAYOFFS** |
| `DivisionWins` | int | Division record wins | Tiebreaker |
| `DivisionLosses` | int | Division record losses | Tiebreaker |
| `ConferenceWins` | int | Conference record wins | Tiebreaker |
| `ConferenceLosses` | int | Conference record losses | Tiebreaker |
| `PointsFor` | int | Total points scored | Tiebreaker |
| `PointsAgainst` | int | Total points allowed | Tiebreaker |
| `Conference` | string | "AFC" or "NFC" | |
| `Division` | string | "North", "South", "East", "West" | |

**Playoff Logic:**
- `ConferenceRank <= 7` = playoff team
- `DivisionRank === 1` = division winner (automatic playoff berth)
- `ConferenceRank >= 5 && ConferenceRank <= 7` = wild card
- `ConferenceRank === 1` = #1 seed (bye week in old format)

---

## EDGE CASES & GOTCHAS

### 1. Losing Record Playoff Teams
**NEVER** assume a losing record = no playoffs.
Carolina Panthers made 2024-25 playoffs at 8-9 as NFC South winner.
**ALWAYS** check `DivisionRank` and `ConferenceRank`.

### 2. Game Status vs IsClosed
`Status === "Final"` means game ended, but stats may still be updating.
`IsClosed === true` means game is verified and finalized.
**Use IsClosed for bet settling.**

### 3. Injury Status vs Roster Status
- `Status` = roster designation (Active, IR, PUP)
- `InjuryStatus` = game availability (Out, Doubtful, Questionable)

A player can be `Status: Active` but `InjuryStatus: Out`.

### 4. Bye Week Handling
Teams on bye won't appear in weekly game endpoints.
Check `Teams` → `ByeWeek` or `Byes/{season}`.

### 5. Stat Corrections
NFL official corrections published Thursday morning.
Stats may change after initial final.

### 6. Null vs Zero
Many fields are null when game hasn't started.
After game: 0 means zero stats, null means no data.

---

## VERSION INFO
- API Version: v3
- Document Date: January 2026
- Coverage: 2015-present (full)
