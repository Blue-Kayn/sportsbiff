# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development
bin/dev                          # Start development server (Puma + Tailwind watcher)
rails c                          # Rails console

# Database
rails db:create                  # Create databases
rails db:migrate                 # Run migrations
rails db:test:prepare            # Prepare test database

# Testing
rails test                       # Run unit/integration tests
rails test:system                # Run system tests
rails test test/models/user_test.rb              # Run single test file
rails test test/models/user_test.rb:10           # Run specific test at line

# Code Quality
bin/rubocop                      # Run linter (uses rubocop-rails-omakase)
bin/brakeman --no-pager          # Security scan

# Data refresh
rails sports:refresh             # Manual sports data refresh (scores, schedules)
rails odds:refresh               # Manual odds/market data refresh
```

## Project Overview

**SportsBiff** is a personalized sports companion for serious fans. Users select their favorite teams, get a personalized experience themed to those teams, and can ask natural language questions about sports. The app provides real-time news, scores, schedules, and market intelligence.

**Goal**: Build a beloved daily-use app for sports fans, with potential £10M+ acquisition.

### Core Value Proposition
1. **Personalization** - App adapts to YOUR teams (theming, news priority, notifications)
2. **Opinionated Summaries** - "What matters today" not "everything that happened"
3. **Market Intelligence** - Odds context as information, not betting advice
4. **Conversational** - Ask anything about sports in plain English

### Target Users
- Serious sports fans who follow multiple teams
- People who want curated, relevant updates (not firehose of content)
- Fans who may also bet, but primarily identify as FANS first

## Architecture

### User Onboarding Flow (NEW)
1. User signs up
2. Onboarding wizard: Select favorite sports (NFL, NBA, Premier League, etc.)
3. Select favorite teams per sport (e.g., Giants, Lakers, Arsenal)
4. Optional: Set notification preferences
5. App personalizes: theme colors, news priority, "your teams" dashboard

### Data Model Updates Needed
```ruby
# User additions
- favorite_sports: jsonb        # ["NFL", "NBA", "Premier League"]
- favorite_teams: jsonb         # [{sport: "NFL", team: "Giants", team_id: "xxx"}, ...]
- theme_preference: string      # "team" (use primary team colors) or "dark"/"light"
- notification_prefs: jsonb     # {scores: true, injuries: true, transactions: true}

# New model: Team
- name: string
- sport: string
- api_id: string               # ID from sports data API
- colors: jsonb                # {primary: "#0B2265", secondary: "#A71930"}
- logo_url: string

# New model: SportsNews (cached)
- team_id: references
- headline: string
- summary: text
- source: string
- published_at: datetime
- expires_at: datetime
```

### Request Flow
1. User sends message → `MessagesController#create`
2. `ContextBuilder` (NEW) assembles relevant context:
   - User's favorite teams
   - Recent news for relevant teams
   - Current scores/schedules if game day
   - Market data if betting-related question
3. `ResponseBuilder` sends enriched context + question to `AiService`
4. AI response stored in `Message`, streamed back via Turbo Streams

### Key Services

**Existing (keep)**:
- `OddsApiService` - Market data from The Odds API (reframed as "market intelligence")
- `AiService` - OpenAI GPT-4o mini with injected real-time context
- `OddsCache` - Cached market data

**New services needed**:
- `SportsDataService` - Scores, schedules, standings, rosters (ESPN API or SportRadar)
- `NewsService` - Sports news headlines (NewsAPI or ESPN)
- `ContextBuilder` - Assembles real-time data into prompt context
- `TeamService` - Team metadata, colors, logos

### Solving the Stale Data Problem

GPT-4o mini has old training data. We fix this by INJECTING current data into every prompt:

```ruby
# ContextBuilder assembles this before every AI call:
context = {
  current_date: Date.today,
  user_teams: user.favorite_teams,
  
  # Injected real-time data (fetched from APIs, cached)
  todays_games: SportsDataService.games_for_teams(user.favorite_teams, Date.today),
  recent_scores: SportsDataService.recent_results(user.favorite_teams, days: 3),
  injuries: SportsDataService.injuries(user.favorite_teams),
  news: NewsService.headlines(user.favorite_teams, limit: 5),
  standings: SportsDataService.standings(user.favorite_sports),
  
  # Only if question seems betting-related
  market_data: OddsApiService.odds_for_teams(user.favorite_teams)
}

# This context is prepended to system prompt so AI has current facts
```

## Response Philosophy

### Sports Questions (Default)
Conversational, helpful, opinionated. Like talking to a knowledgeable friend.

```
User: "How are the Giants doing?"

AI: "Rough stretch. They're 2-5 after losing to the Eagles 28-14 on Sunday. 
Daniel Jones has been inconsistent - 2 TDs but 3 INTs in the last two games. 
The offensive line is the real problem. Next up: Cowboys at home, which is 
a must-win if they want any shot at the playoffs. Markets have them as 
3-point underdogs at home, which tells you where expectations are."
```

### Market Intelligence Questions
When users ask about odds, predictions, or betting-related topics, include market context but frame as INFORMATION, not advice:

```
User: "What do the odds look like for the Giants game?"

AI: "Markets aren't loving the Giants this week. Here's where the lines sit:

Cowboys -3 (consensus)
Total: 42.5 points

Line movement: Opened at Cowboys -2.5, moved to -3 after injury news.
Public betting: 65% on Cowboys.

The home underdog angle is interesting historically, but that offensive 
line needs to show up. I'd watch for the line to move if Barkley's 
injury status changes before Sunday."
```

**Key rule**: Never say "bet this" or "I recommend betting." Say "markets show" or "historically" or "the line suggests."

### What NOT to do
- ❌ "I predict the Giants will win"
- ❌ "You should bet on..."
- ❌ "Best bet of the day"
- ✅ "Markets favor..."
- ✅ "The line suggests..."
- ✅ "Historically, home underdogs in this situation..."

## API Integrations

### The Odds API (KEEP)
- Purpose: Market intelligence, line movements, odds comparison
- Base: `https://api.the-odds-api.com/v4/sports/{sport}/odds`
- Key: stored in Rails credentials (`ODDS_API_KEY`)
- Docs: https://the-odds-api.com/liveapi/guides/v4/
- Cache: 5 minutes for live games, 30 minutes otherwise

### Sports Data API (NEW - CHOOSE ONE)

**Option A: ESPN API (Free, unofficial)**
- Scores, schedules, standings, rosters
- No official API key needed
- Base: `https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/`
- Endpoints: scoreboard, teams, news
- Reliability: Good but unofficial, could break

**Option B: SportRadar (Paid, official)**
- Comprehensive official data
- Requires paid API key
- Better for production

**Option C: API-Football / API-Sports (Paid, affordable)**
- Good for soccer/football
- ~$20/month for basic tier

**Recommendation for MVP**: Use ESPN unofficial API (free) + NewsAPI for headlines

### News API (NEW)
- Purpose: Current headlines about teams
- Provider: NewsAPI.org ($0 for dev, $449/mo production) OR ESPN headlines
- Cache: 15 minutes

### OpenAI API
- Model: `gpt-4o-mini`
- Key: stored in credentials (`OPENAI_API_KEY`)
- System prompt: `prompts/system_prompt.md` (needs update for new persona)

## Environment Variables
```
OPENAI_API_KEY=
ODDS_API_KEY=
NEWS_API_KEY=          # If using NewsAPI
DATABASE_URL=          # For production
RAILS_MASTER_KEY=      # For credentials
```

## Personalization Features (MVP Priority)

### P0 - Must have for demo
- [ ] Onboarding: pick favorite teams
- [ ] Inject team context into every AI response
- [ ] "Your teams today" dashboard showing relevant games
- [ ] Real-time scores/schedules injected into AI context

### P1 - Important but can be basic
- [ ] Team-colored theming (use primary team color as accent)
- [ ] News feed filtered to user's teams
- [ ] Basic notifications (game starting, final scores)

### P2 - Nice to have
- [ ] Historical facts/trivia about user's teams
- [ ] "On this day" notifications
- [ ] Rivalry context when relevant matchups

## Sports Supported (MVP)

Start with major US sports + Premier League:
- `americanfootball_nfl` - NFL
- `basketball_nba` - NBA  
- `baseball_mlb` - MLB
- `icehockey_nhl` - NHL
- `soccer_epl` - Premier League
- `soccer_usa_mls` - MLS

Add later: Boxing, Golf, College sports

## Current Status
- [x] Rails 8 app initialized
- [x] TailwindCSS added
- [x] PostgreSQL configured
- [x] Devise auth setup
- [x] Basic chat UI with Turbo Streams
- [x] The Odds API integration (market data working)
- [x] AI service integration (OpenAI GPT-4o mini)
- [x] Rate limiting
- [x] User model with favorite_sports/favorite_teams JSONB columns
- [x] Team model with colors, logos, api_id
- [x] User onboarding wizard (sport selection → team selection)
- [x] ContextBuilder service (assembles real-time data for AI)
- [x] SportsDataService (ESPN API integration)
- [x] NewsService (ESPN news headlines)
- [x] Team channels in sidebar (read-only news feeds per team)
- [x] System prompt updated for sports companion persona
- [ ] **NEXT**: Historical sports data (structured database, not web search)

## Demo Accounts
After running `rails db:seed`:
- **Demo user**: demo@sportsbiff.com / demo123456 (pro tier, 500 queries/day)
- **Test user**: test@example.com / password123 (free tier, 10 queries/day)

## Key Architectural Principle

**The AI should never hallucinate facts.**

Every factual claim (scores, schedules, injuries, odds, standings) must come from:
1. `SportsDataService` (cached API data)
2. `OddsCache` (market data)
3. `NewsService` (headlines)

The AI's job is to SYNTHESIZE and PRESENT this data conversationally, not to make things up.

## Implemented Features

### Team Channels (Sidebar)
Each user's favorite teams get a dedicated read-only channel in the sidebar:
- **Location**: `app/views/chats/_sidebar.html.erb`
- **Controller**: `ChatsController#show` renders `team_channel.html.erb` for team channels
- **Auto-creation**: Team channels created automatically via `ensure_team_channels_exist` callback
- **Features**:
  - Team logo with inline styles (`width: 24px; height: 24px;` - Tailwind classes don't work)
  - Team colors as accent (primary_color from Team model)
  - Recent 10 game results (looks back 120 days)
  - Team-specific news only (filtered by team name mentions)
  - No user input - read-only news feed

### Chat Model Extensions
```ruby
# app/models/chat.rb
belongs_to :team, primary_key: :api_id, foreign_key: :team_id, optional: true
scope :team_channels, -> { where(is_team_channel: true) }
scope :regular_chats, -> { where(is_team_channel: false) }

# Migration: add_team_id_to_chats
- team_id: string (matches Team.api_id)
- is_team_channel: boolean, default: false
- unique index on [user_id, team_id] where team_id IS NOT NULL
```

### Services Architecture

#### SportsDataService (`app/services/sports_data_service.rb`)
Fetches from ESPN unofficial API (no API key needed):
- `todays_games(team_ids)` - Current day's games for teams
- `games_for_teams(team_ids, date)` - Games on specific date
- `recent_results(team_ids, days: 7, limit: 10)` - Past game results
- `standings(sport)` - League standings
- `injuries(team_ids)` - Injury reports (NFL/NBA only)
- Uses Net::HTTP (Faraday blocked by ESPN)
- 5-minute cache for live data

#### NewsService (`app/services/news_service.rb`)
Fetches from ESPN news endpoints:
- `headlines(team_ids, limit: 5)` - News for specific teams
- `team_news(team)` - Filtered news mentioning team name
- `top_headlines(sports:, limit:)` - General sport news
- Filters by team name variations (full name, nickname, abbreviation, city)

#### ContextBuilder (`app/services/context_builder.rb`)
Assembles real-time data for AI prompts:
- User's favorite teams
- Today's games
- Recent results (last 7 days)
- News headlines
- Standings (only if question asks)
- Injuries (only if question asks)
- Market data (only if betting-related question)
- Outputs formatted text for system prompt injection

#### ResponseBuilder (`app/services/response_builder.rb`)
Orchestrates AI responses:
- Builds context via ContextBuilder
- Injects context into system prompt
- Adds first-message instruction to share news proactively
- Calls AiService with enriched context

### Team Model (`app/models/team.rb`)
```ruby
# Fields
- name: string ("Arizona Cardinals")
- sport: string ("NFL")
- api_id: string ("ari") - lowercase abbreviation
- colors: jsonb ({"primary": "#97233F", "secondary": "#000000"})
- logo_url: string (ESPN CDN URL)

# Methods
- primary_color - returns colors["primary"] or default
- secondary_color - returns colors["secondary"] or default
```

### User Model Extensions
```ruby
# JSONB columns
- favorite_sports: ["NFL", "NBA", "EPL"]
- favorite_teams: [{"sport": "NFL", "team_name": "Arizona Cardinals", "team_id": "ari"}, ...]

# Helper methods
- favorite_team_ids - array of team_id strings
- favorite_team_names - array of team names
- onboarding_complete? - has at least one favorite team
```

### Views

#### Team Channel View (`app/views/chats/team_channel.html.erb`)
- Team header with logo and gradient background using team colors
- Today's games section (if any)
- Recent results (last 10 games, formatted with date parsing fallback)
- Latest news (team-specific only)
- AI summary placeholder
- Footer note explaining it's read-only

#### Sidebar (`app/views/chats/_sidebar.html.erb`)
- Team channels section with logos
- Regular chats section
- New chat button
- Active state highlighting with team color border

### Important Technical Notes

1. **Logo sizing**: Must use inline styles (`style="width: 24px;"`) not Tailwind classes - they get ignored
2. **Date handling**: Game dates come as strings, need `respond_to?(:strftime)` check with fallback parsing
3. **ESPN API**: Uses Net::HTTP directly, Faraday gets blocked
4. **Team ID format**:
   - NFL: lowercase abbreviation ("ari", "nyg")
   - NBA: "nba_" prefix ("nba_lal")
   - EPL: "epl_" prefix ("epl_ars")

## Future: Historical Sports Data

**Current limitation**: AI cannot answer historical questions ("Who scored the first TD for the Cardinals?")

**Required architecture** (NOT web search):
1. **Structured database** with tables: teams, players, games, scoring_plays, seasons
2. **Authoritative data sources**: Pro-Football-Reference, SportsDataIO, or Sportradar
3. **Question classifier**: LLM determines intent first, routes to data lookup
4. **Data lookup**: Deterministic database query, no AI guessing
5. **LLM response**: Only explains/presents verified facts

This separates **knowledge** (databases) from **reasoning** (LLM).

## Notes
- This is a SPORTS COMPANION, not a betting app
- Personalization is the differentiator
- "Opinionated summaries" > raw data dumps
- Keep code simple - MVP demo in 2 weeks
- Ask before making architectural changes
- **Never use web search for facts** - use structured databases