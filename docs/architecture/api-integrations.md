# API Integrations

## Overview

Sports Biff integrates with three external APIs to provide real-time sports intelligence.

---

## 1. OpenAI API (GPT-4o mini)

### Purpose
Generate conversational AI responses using real-time sports context.

### Configuration
- **Model**: `gpt-4o-mini`
- **Max Tokens**: 1024
- **API Key**: Stored in `ENV["OPENAI_API_KEY"]` or Rails credentials
- **Gem**: `ruby-openai` ~7.0

### Endpoints Used
```
POST https://api.openai.com/v1/chat/completions
```

### Request Format
```ruby
{
  model: "gpt-4o-mini",
  messages: [
    {role: "system", content: "...system prompt with injected context..."},
    {role: "user", content: "How did the Giants do?"},
    {role: "assistant", content: "The Giants won 24-17..."},
    {role: "user", content: "What about injuries?"}
  ],
  max_tokens: 1024
}
```

### Response Format
```ruby
{
  choices: [
    {
      message: {
        role: "assistant",
        content: "The Giants have several key injuries..."
      }
    }
  ],
  usage: {
    prompt_tokens: 450,
    completion_tokens: 87,
    total_tokens: 537
  }
}
```

### Implementation
See: [app/services/ai_service.rb](../../app/services/ai_service.rb:1)

### Error Handling
- **Timeout**: Returns fallback message
- **Rate Limit**: Returns error message
- **Auth Error**: Logs and returns fallback

### Cost Estimates (GPT-4o mini)
- Input: ~$0.15 per 1M tokens
- Output: ~$0.60 per 1M tokens
- Average query: ~500 tokens = $0.0003

---

## 2. ESPN Unofficial API

### Purpose
Fetch real-time sports scores, schedules, standings, injuries, and news.

### Configuration
- **Base URL**: `https://site.api.espn.com`
- **Authentication**: None required
- **Rate Limits**: No official limits (unofficial API)
- **Risk**: Could break without notice

### Sport Mappings
```ruby
SPORT_MAPPINGS = {
  "NFL" => "football/nfl",
  "NBA" => "basketball/nba",
  "MLB" => "baseball/mlb",
  "NHL" => "hockey/nhl",
  "EPL" => "soccer/eng.1",
  "MLS" => "soccer/usa.1"
}
```

### Endpoints Used

#### Today's Games
```
GET /apis/site/v2/sports/{sport}/{league}/scoreboard
```

**Example**: `/apis/site/v2/sports/football/nfl/scoreboard`

**Response** (truncated):
```json
{
  "events": [
    {
      "id": "401547409",
      "name": "New York Giants at Dallas Cowboys",
      "date": "2024-12-30T20:30Z",
      "competitions": [
        {
          "competitors": [
            {
              "team": {"id": "19", "abbreviation": "NYG", "displayName": "New York Giants"},
              "score": "17",
              "homeAway": "away"
            },
            {
              "team": {"id": "6", "abbreviation": "DAL", "displayName": "Dallas Cowboys"},
              "score": "24",
              "homeAway": "home"
            }
          ]
        }
      ]
    }
  ]
}
```

#### Team Schedule (Recent Results)
```
GET /apis/site/v2/sports/{sport}/{league}/teams/{team_id}/schedule
```

**Example**: `/apis/site/v2/sports/football/nfl/teams/nyg/schedule`

#### Standings
```
GET /apis/site/v2/sports/{sport}/{league}/standings
```

**Example**: `/apis/site/v2/sports/football/nfl/standings`

#### Injuries (NFL/NBA only)
```
GET /apis/site/v2/sports/{sport}/{league}/teams/{team_id}/injuries
```

**Example**: `/apis/site/v2/sports/football/nfl/teams/nyg/injuries`

#### News
```
GET /apis/site/v2/sports/{sport}/{league}/news
```

**Example**: `/apis/site/v2/sports/football/nfl/news`

### Team ID Normalization

ESPN uses different ID formats per sport:

| Sport | Format | Example |
|-------|--------|---------|
| NFL | Lowercase abbreviation | `nyg` |
| NBA | `nba_` + lowercase | `nba_ny` |
| MLB | `mlb_` + lowercase | `mlb_nyy` |
| NHL | `nhl_` + lowercase | `nhl_nyr` |
| EPL | `epl_` + lowercase | `epl_ars` |
| MLS | `mls_` + lowercase | `mls_sea` |

### Caching Strategy

| Data Type | Cache Duration | Reason |
|-----------|---------------|--------|
| Live games (in progress) | 5 minutes | Scores change frequently |
| Completed games | 1 hour | Static data |
| Standings | 30 minutes | Changes daily |
| Injuries | 15 minutes | Updates throughout day |
| News | 15 minutes | New articles published often |

### Implementation
See: [app/services/sports_data_service.rb](../../app/services/sports_data_service.rb:1)

### Error Handling
- **Timeout**: Return empty array, log error
- **404**: Team not found, return empty
- **Network Error**: Return cached data if available

---

## 3. The Odds API

### Purpose
Fetch betting odds and market intelligence (framed as information, not betting advice).

### Configuration
- **Base URL**: `https://api.the-odds-api.com/v4`
- **API Key**: Stored in `ENV["ODDS_API_KEY"]` or Rails credentials
- **Rate Limits**: 500 requests/month (free tier)
- **Documentation**: https://the-odds-api.com/liveapi/guides/v4/

### Endpoints Used

#### Upcoming Events
```
GET /sports/{sport}/odds
?apiKey={key}
&regions=us
&markets=h2h,spreads,totals
&oddsFormat=american
```

**Example**: `/sports/americanfootball_nfl/odds`

**Response** (truncated):
```json
{
  "id": "abc123",
  "sport_key": "americanfootball_nfl",
  "commence_time": "2024-12-30T20:30:00Z",
  "home_team": "Dallas Cowboys",
  "away_team": "New York Giants",
  "bookmakers": [
    {
      "key": "draftkings",
      "title": "DraftKings",
      "markets": [
        {
          "key": "h2h",
          "outcomes": [
            {"name": "Dallas Cowboys", "price": -170},
            {"name": "New York Giants", "price": 150}
          ]
        },
        {
          "key": "spreads",
          "outcomes": [
            {"name": "Dallas Cowboys", "price": -110, "point": -3.5},
            {"name": "New York Giants", "price": -110, "point": 3.5}
          ]
        }
      ]
    }
  ]
}
```

### Sport Keys

| Sport | Odds API Key |
|-------|--------------|
| NFL | `americanfootball_nfl` |
| NBA | `basketball_nba` |
| MLB | `baseball_mlb` |
| NHL | `icehockey_nhl` |
| EPL | `soccer_epl` |
| MLS | `soccer_usa_mls` |

### Market Types

- **h2h** (moneyline): Which team will win
- **spreads**: Point spread betting
- **totals**: Over/under total points

### Odds Format

- **American**: -170 (bet $170 to win $100), +150 (bet $100 to win $150)
- **Decimal**: 1.59, 2.50
- **Fractional**: 3/2, 1/2

We use **American** format.

### Caching Strategy

- **Cache Duration**: 1 hour
- **Storage**: `OddsCache` model (JSONB column)
- **Reason**: Reduce API calls (500/month limit)

### Implementation
See: [app/services/odds_api_service.rb](../../app/services/odds_api_service.rb:1)

### Error Handling
- **No API Key**: Return mock data (demo mode)
- **Rate Limit**: Return cached data or empty
- **Timeout**: Return cached data if available

### AI Framing

Odds are presented as **market intelligence**, not betting advice:

**Good**:
- "Markets favor the Cowboys at -170"
- "The spread is set at Giants +3.5"
- "Bookmakers see this as a close game"

**Bad** (avoided):
- "You should bet on the Giants"
- "This is a good bet"
- "Take the over"

See: [prompts/system_prompt.md](../../prompts/system_prompt.md:1)

---

## API Call Flow

### Typical Chat Message

```
User asks: "How are the Giants doing this season?"
  ↓
ContextBuilder analyzes question
  ↓
Parallel API calls:
  ├─ ESPN: GET /sports/football/nfl/teams/nyg/schedule  (recent results)
  ├─ ESPN: GET /sports/football/nfl/standings           (standings)
  └─ ESPN: GET /sports/football/nfl/news                (news)
  ↓
Cache responses (15-30 min TTL)
  ↓
Format as text for AI context
  ↓
OpenAI: POST /chat/completions (with context injected)
  ↓
AI response uses real data, no hallucination
```

### Betting Question

```
User asks: "What are the odds for tonight's Giants game?"
  ↓
ContextBuilder detects "odds" keyword
  ↓
Additional API call:
  └─ The Odds API: GET /sports/americanfootball_nfl/odds
  ↓
Check OddsCache first (1 hour TTL)
  ↓
Format odds for AI context
  ↓
OpenAI generates response with market framing
```

---

## API Monitoring

### Recommended Practices

1. **Log all API calls**
   - Endpoint, duration, status code
   - Track ESPN API reliability

2. **Monitor rate limits**
   - The Odds API: 500/month (track usage)
   - OpenAI: track token usage and cost

3. **Alert on failures**
   - ESPN API down → fallback to cached data
   - OpenAI errors → notify developers

4. **Cache hit rates**
   - Aim for >80% cache hit rate
   - Reduce external API dependency

---

## Cost Analysis

### Monthly Estimates (1000 active users, 10 queries/user)

**OpenAI** (10,000 queries/month):
- Avg 500 tokens/query = 5M tokens
- Cost: ~$1.50/month

**The Odds API** (free tier):
- 500 requests/month limit
- Need paid tier for scale: $50/month (10k requests)

**ESPN API**:
- Free (unofficial, no guarantees)
- Risk: could be shut down

**Total**: ~$2-52/month depending on scale

---

## Future Improvements

1. **ESPN API Replacement**
   - Migrate to official API if/when ESPN releases one
   - Alternative: SportRadar, API-Football, etc.

2. **Odds API Optimization**
   - Batch fetch all events once/hour
   - Store in database, reduce per-query calls
   - Upgrade to paid tier when >500 requests/month

3. **OpenAI Optimization**
   - Fine-tune smaller model on sports domain
   - Reduce token usage with better prompts
   - Consider Claude or other alternatives

---

## Related Documentation

- [Architecture Overview](./overview.md)
- [Data Flow](./data-flow.md)
- [AiService](../services/ai-service.md)
- [SportsDataService](../services/sports-data-service.md)
- [OddsApiService](../services/odds-api-service.md)
