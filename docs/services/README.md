# Services Documentation

Business logic services for Sports Biff.

## Quick Reference

| Service | Purpose | File |
|---------|---------|------|
| [ResponseBuilder](./response-builder.md) | Orchestrates AI response generation | app/services/response_builder.rb |
| [ContextBuilder](./context-builder.md) | Assembles real-time sports context | app/services/context_builder.rb |
| [AiService](./ai-service.md) | OpenAI GPT-4o mini integration | app/services/ai_service.rb |
| [SportsDataService](./sports-data-service.md) | ESPN API integration | app/services/sports_data_service.rb |
| [NewsService](./news-service.md) | ESPN news fetching | app/services/news_service.rb |
| [OddsApiService](./odds-api-service.md) | The Odds API integration | app/services/odds_api_service.rb |

## Service Architecture

```
ResponseBuilder (orchestration)
  ├─ ContextBuilder (data assembly)
  │   ├─ SportsDataService (scores, standings, injuries)
  │   ├─ NewsService (headlines)
  │   └─ OddsApiService (betting odds)
  └─ AiService (OpenAI)
```

## Usage Pattern

All services are stateless and called as class methods:

```ruby
# Orchestration
response = ResponseBuilder.build(user:, chat:, question:)
# => {content: "...", tokens_used: 123}

# Context assembly
context = ContextBuilder.build(user:, question:)
# => {favorite_teams: [...], todays_games: [...], ...}

# AI call
result = AiService.chat(messages:, system_prompt:)
# => {content: "...", tokens_used: 123}

# Sports data
games = SportsDataService.todays_games(["nyg", "dal"])
# => [{game_id: "...", home_team: "...", ...}]

# News
headlines = NewsService.headlines(["nyg"], limit: 5)
# => [{title: "...", link: "...", description: "..."}]

# Odds
odds = OddsApiService.fetch_event(event_id: "abc123")
# => {home_team: "...", away_team: "...", bookmakers: [...]}
```
