# Data Flow Documentation

## Overview

This document describes how data flows through the Sports Biff application for key user interactions.

## 1. Chat Message Flow (Regular Chat)

### User submits a message about their favorite team

```
┌─────────┐
│ Browser │ User types: "How did the Giants do last night?"
└────┬────┘
     │ POST /chats/:id/messages
     ▼
┌─────────────────────┐
│ MessagesController  │
│  #create            │
└────┬────────────────┘
     │ 1. Authenticate user
     │ 2. Check rate limit (can_query?)
     │ 3. Create Message (role: "user", content: "...")
     │ 4. Increment daily_query_count
     │ 5. Return Turbo Streams:
     │    - messages/message (display user message)
     │    - messages/form (clear input)
     │    - messages/thinking (show loading)
     │ 6. Queue GenerateResponseJob
     ▼
┌─────────────────────┐
│ Browser             │ Displays message + "thinking" indicator
└─────────────────────┘

[Background Job Starts]

┌─────────────────────┐
│ GenerateResponseJob │
└────┬────────────────┘
     │ 1. Find chat and user message
     │ 2. Call ResponseBuilder.build()
     ▼
┌─────────────────────┐
│ ResponseBuilder     │
└────┬────────────────┘
     │ 1. Call ContextBuilder.build()
     ▼
┌─────────────────────┐
│ ContextBuilder      │
└────┬────────────────┘
     │ Analyze question for intent:
     │ - Contains "last night" → recent games
     │ - Team: "Giants" → filter to NYG
     │
     │ Fetch data:
     │ 1. SportsDataService.recent_results(["nyg"], days: 7, limit: 5)
     │ 2. NewsService.headlines(["nyg"], limit: 5)
     │ 3. (Skip odds - not a betting question)
     │ 4. (Skip standings - not asked)
     │
     │ Returns context hash
     ▼
┌─────────────────────┐
│ ResponseBuilder     │
│  (continued)        │
└────┬────────────────┘
     │ 1. Format context as text
     │ 2. Load system_prompt.md
     │ 3. Inject context into {CONTEXT_DATA}
     │ 4. Add first-message instruction (if first msg)
     │ 5. Call AiService.chat()
     ▼
┌─────────────────────┐
│ AiService           │
└────┬────────────────┘
     │ 1. POST to OpenAI API
     │ 2. Model: gpt-4o-mini
     │ 3. Messages: [system_prompt, conversation_history]
     │ 4. Parse response
     │ 5. Return {content, tokens_used}
     ▼
┌─────────────────────┐
│ GenerateResponseJob │
│  (continued)        │
└────┬────────────────┘
     │ 1. Create Message (role: "assistant", content, tokens_used)
     │ 2. Update chat title (if first exchange)
     │ 3. Broadcast via Turbo::StreamsChannel
     ▼
┌─────────────────────┐
│ Browser             │ Receives Turbo Stream, displays AI response
└─────────────────────┘
```

**Total Duration**: ~2-5 seconds
- API calls: 1-3 seconds
- OpenAI response: 1-2 seconds
- Database operations: <100ms

---

## 2. Onboarding Flow (New User)

```
┌─────────┐
│ Browser │ User signs up via Devise
└────┬────┘
     │ POST /users
     ▼
┌─────────────────────┐
│ Devise              │ Creates User (onboarded: false)
└────┬────────────────┘
     │ Redirect to root
     ▼
┌─────────────────────┐
│ApplicationController│ before_action :check_onboarding
└────┬────────────────┘
     │ User.onboarded? → false
     │ Redirect to /onboarding
     ▼
┌─────────────────────┐
│OnboardingController │
│  #index             │
└────┬────────────────┘
     │ Render sport selection checkboxes
     ▼
┌─────────┐
│ Browser │ User selects NFL, NBA
└────┬────┘
     │ POST /onboarding/sports
     ▼
┌─────────────────────┐
│OnboardingController │
│  #sports            │
└────┬────────────────┘
     │ 1. user.update(favorite_sports: ["NFL", "NBA"])
     │ 2. Redirect to /onboarding/teams
     ▼
┌─────────────────────┐
│OnboardingController │
│  #teams             │
└────┬────────────────┘
     │ 1. @teams = Team.where(sport: ["NFL", "NBA"])
     │ 2. Group by sport
     │ 3. Render team checkboxes
     ▼
┌─────────┐
│ Browser │ User selects NYG (NFL), LAL (NBA)
└────┬────┘
     │ POST /onboarding/teams
     ▼
┌─────────────────────┐
│OnboardingController │
│  #save_teams        │
└────┬────────────────┘
     │ 1. Build favorite_teams array:
     │    [{sport: "NFL", team_id: "nyg", team_name: "New York Giants"},
     │     {sport: "NBA", team_id: "lal", team_name: "Los Angeles Lakers"}]
     │ 2. user.update(favorite_teams: [...])
     │ 3. Redirect to /onboarding/complete
     ▼
┌─────────────────────┐
│OnboardingController │
│  #complete          │
└────┬────────────────┘
     │ Render completion page
     ▼
┌─────────┐
│ Browser │ User clicks "Get Started"
└────┬────┘
     │ GET /onboarding/finish
     ▼
┌─────────────────────┐
│OnboardingController │
│  #finish            │
└────┬────────────────┘
     │ 1. user.update(onboarded: true)
     │ 2. Redirect to /chats
     ▼
┌─────────────────────┐
│ ChatsController     │
│  #index             │
└────┬────────────────┘
     │ before_action :ensure_team_channels_exist
     │
     │ For each team in user.favorite_teams:
     │   - Check if team channel exists (user_id + team_id)
     │   - If not, create Chat(is_team_channel: true, team_id: ...)
     │
     │ Load @chats (regular chats)
     │ Load @team_channels (team channels)
     │ Render sidebar + empty chat view
     ▼
┌─────────┐
│ Browser │ Shows sidebar with 2 team channels + "New Chat" option
└─────────┘
```

---

## 3. Team Channel Display

```
┌─────────┐
│ Browser │ User clicks "New York Giants" channel
└────┬────┘
     │ GET /chats/:id (where chat.is_team_channel = true)
     ▼
┌─────────────────────┐
│ ChatsController     │
│  #show              │
└────┬────────────────┘
     │ 1. @chat = Chat.find(params[:id])
     │ 2. Check if @chat.is_team_channel?
     │ 3. Call load_team_news
     ▼
┌─────────────────────┐
│ ChatsController     │
│  #load_team_news    │
└────┬────────────────┘
     │ 1. @team = Team.find_by(api_id: @chat.team_id)
     │ 2. NewsService.team_news(@team, limit: 10)
     ▼
┌─────────────────────┐
│ NewsService         │
└────┬────────────────┘
     │ 1. Fetch from ESPN: /apis/site/v2/sports/football/nfl/news
     │ 2. Cache for 15 minutes
     │ 3. Filter by team name variations:
     │    - "New York Giants"
     │    - "Giants"
     │    - "NYG"
     │    - "New York"
     │ 4. Return top 10 headlines
     ▼
┌─────────────────────┐
│ ChatsController     │
│  (continued)        │
└────┬────────────────┘
     │ 3. SportsDataService.recent_results(["nyg"], days: 30, limit: 10)
     ▼
┌─────────────────────┐
│ SportsDataService   │
└────┬────────────────┘
     │ 1. Fetch from ESPN: /apis/site/v2/sports/football/nfl/teams/nyg/schedule
     │ 2. Cache for 1 hour
     │ 3. Filter to completed games
     │ 4. Return last 10 games with scores
     ▼
┌─────────────────────┐
│ ChatsController     │
│  (continued)        │
└────┬────────────────┘
     │ 4. SportsDataService.games_for_teams(["nyg"], Date.today)
     │ 5. Render team_channel.html.erb
     ▼
┌─────────┐
│ Browser │ Displays:
│         │ - Team header (logo, colors, name)
│         │ - Upcoming games
│         │ - Recent results (10 games with W/L)
│         │ - News headlines (10 articles)
│         │ - No message input (read-only)
└─────────┘
```

---

## 4. Rate Limiting Flow

```
┌─────────┐
│ Browser │ User submits 11th message (Free tier, 10/day limit)
└────┬────┘
     │ POST /chats/:id/messages
     ▼
┌─────────────────────┐
│ MessagesController  │
│  #create            │
└────┬────────────────┘
     │ 1. current_user.can_query? → Check limit
     │    - current_user.subscription_tier → "free"
     │    - current_user.daily_limit → 10
     │    - current_user.daily_query_count → 10
     │    - current_user.queries_remaining → 0
     │
     │ 2. can_query? returns false
     │ 3. Render Turbo Stream: messages/rate_limit_error
     ▼
┌─────────┐
│ Browser │ Displays error message:
│         │ "You've reached your daily limit of 10 queries.
│         │  Upgrade to Basic (50/day) or Pro (500/day)."
└─────────┘

[Next Day - Midnight UTC]

┌─────────────────────┐
│ User model          │
│  #can_query?        │
└────┬────────────────┘
     │ before_action :reset_daily_count_if_needed
     │
     │ Check: query_count_reset_date < Date.today?
     │ → true (it's a new day)
     │
     │ Reset:
     │ - daily_query_count = 0
     │ - query_count_reset_date = Date.today
     │
     │ Now can_query? returns true
     └─────────────────────┘
```

---

## 5. Context Injection for Betting Question

```
┌─────────┐
│ Browser │ User asks: "What are the odds for the Giants game?"
└────┬────┘
     │
     ▼
[... standard message flow ...]
     │
     ▼
┌─────────────────────┐
│ ContextBuilder      │
│  #build             │
└────┬────────────────┘
     │ 1. Analyze question:
     │    - Contains "odds" → betting_related? = true
     │    - Team: "Giants" → team_id = "nyg"
     │
     │ 2. Fetch standard data:
     │    - today's games for NYG
     │    - recent results for NYG
     │    - news for NYG
     │
     │ 3. Fetch conditional data (betting_related?):
     │    - OddsApiService.fetch_event(event_id)
     ▼
┌─────────────────────┐
│ OddsApiService      │
└────┬────────────────┘
     │ 1. Check OddsCache for event_id
     │    - If fresh (< 1 hour), return cached data
     │
     │ 2. If stale or missing:
     │    - Call The Odds API: GET /sports/americanfootball_nfl/odds
     │    - Parse response
     │    - Store in OddsCache
     │
     │ 3. Format odds for AI:
     │    "New York Giants vs Dallas Cowboys
     │     Moneyline:
     │       NYG: +150 (DraftKings) ← Best
     │       NYG: +145 (FanDuel)
     │       DAL: -170 (DraftKings)
     │     Spread:
     │       NYG +3.5 (-110)
     │       DAL -3.5 (-110)"
     │
     │ 4. Return formatted text
     ▼
┌─────────────────────┐
│ ContextBuilder      │
│  (continued)        │
└────┬────────────────┘
     │ 4. Build context hash:
     │    {
     │      favorite_teams: [...],
     │      todays_games: [...],
     │      recent_results: [...],
     │      news: [...],
     │      market_data: "..." ← INCLUDED
     │    }
     │
     │ 5. to_prompt_text() formats as:
     │    "USER'S FAVORITE TEAMS:
     │     - New York Giants (NFL)
     │
     │     TODAY'S GAMES:
     │     ...
     │
     │     MARKET INTELLIGENCE:
     │     New York Giants vs Dallas Cowboys
     │     Moneyline: NYG +150..."
     ▼
┌─────────────────────┐
│ AiService           │
└────┬────────────────┘
     │ System prompt includes:
     │ "When discussing odds, frame as information not betting advice.
     │  Use phrases like 'markets favor' not 'you should bet'."
     │
     │ Context data injected into {CONTEXT_DATA} placeholder
     │
     │ AI response:
     │ "Based on the latest market data, the Giants are underdogs
     │  at +150. Markets favor the Cowboys at -170. The spread
     │  is set at Giants +3.5, suggesting a close game."
     ▼
┌─────────┐
│ Browser │ Displays AI response with market context
└─────────┘
```

---

## API Call Patterns

### Parallel Data Fetching (ContextBuilder)
```
ContextBuilder.build() calls:
├─ SportsDataService.todays_games()      [Parallel]
├─ SportsDataService.recent_results()    [Parallel]
├─ NewsService.headlines()                [Parallel]
└─ (Conditional)
   ├─ SportsDataService.standings()       [If question asks]
   ├─ SportsDataService.injuries()        [If question mentions]
   └─ OddsApiService.fetch_event()        [If betting-related]
```

### Caching Strategy
```
Request → Check Rails.cache
           ├─ HIT → Return cached data
           └─ MISS → Call external API
                     └─ Store in Rails.cache with TTL
                        └─ Return data
```

---

## Error Handling Flows

### OpenAI API Failure
```
AiService.chat() → OpenAI API error
  ↓
Rescue Faraday::Error
  ↓
Return {content: "Sorry, I'm having trouble...", tokens_used: 0}
  ↓
GenerateResponseJob creates error message
  ↓
Broadcast error to browser
```

### ESPN API Failure
```
SportsDataService.todays_games() → ESPN API timeout
  ↓
Rescue Faraday::TimeoutError
  ↓
Return empty array []
  ↓
ContextBuilder continues with partial context
  ↓
AI responds: "I'm having trouble fetching live scores..."
```

### Rate Limit Exceeded
```
MessagesController#create → can_query? = false
  ↓
Render Turbo Stream: rate_limit_error partial
  ↓
Browser displays upgrade message
  ↓
No message created, no job queued
```

---

## Related Documentation

- [Architecture Overview](./overview.md)
- [API Integrations](./api-integrations.md)
- [Services Documentation](../services/)
