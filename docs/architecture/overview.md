# System Architecture Overview

## High-Level Architecture

Sports Biff follows a traditional Rails MVC architecture with service objects for business logic and background jobs for async processing.

```
┌──────────────────────────────────────────────────────────────┐
│                          Browser                              │
│  (Hotwire Turbo Streams for real-time updates)              │
└───────────────────────┬──────────────────────────────────────┘
                        │ HTTP / WebSocket
┌───────────────────────▼──────────────────────────────────────┐
│                     Rails Application                         │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                  Controllers Layer                       │ │
│  │  • ChatsController         • MessagesController         │ │
│  │  • OnboardingController    • ProfileController          │ │
│  │  • DashboardController     • HomeController             │ │
│  └──────────────┬──────────────────────────────────────────┘ │
│                 │                                             │
│  ┌──────────────▼──────────────────────────────────────────┐ │
│  │                   Services Layer                         │ │
│  │  • ResponseBuilder (orchestration)                       │ │
│  │  • ContextBuilder (data assembly)                        │ │
│  │  • AiService (OpenAI integration)                        │ │
│  │  • SportsDataService (ESPN API)                          │ │
│  │  • NewsService (ESPN News)                               │ │
│  │  • OddsApiService (The Odds API)                         │ │
│  └──────────────┬──────────────────────────────────────────┘ │
│                 │                                             │
│  ┌──────────────▼──────────────────────────────────────────┐ │
│  │                   Models Layer                           │ │
│  │  • User (authentication + personalization)               │ │
│  │  • Chat (conversations + team channels)                  │ │
│  │  • Message (user/assistant messages)                     │ │
│  │  • Team (sports team metadata)                           │ │
│  │  • OddsCache (betting market cache)                      │ │
│  └──────────────┬──────────────────────────────────────────┘ │
│                 │                                             │
│  ┌──────────────▼──────────────────────────────────────────┐ │
│  │                Background Jobs                           │ │
│  │  • GenerateResponseJob (async AI responses)              │ │
│  │  • OddsSyncJob (scheduled odds caching)                  │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────┬──────────────────────────────────────┘
                        │
┌───────────────────────▼──────────────────────────────────────┐
│                    PostgreSQL Database                        │
│  • Users, Chats, Messages, Teams, OddsCache tables           │
│  • JSONB columns for flexible data (favorites, colors, etc.) │
└───────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    External APIs                              │
│  • OpenAI (GPT-4o mini) - AI responses                       │
│  • ESPN (unofficial) - Sports data, scores, news             │
│  • The Odds API - Betting market intelligence                │
└──────────────────────────────────────────────────────────────┘
```

## Core Patterns

### 1. Service Objects
Business logic is extracted into service objects to keep controllers thin and models focused on data.

**Services:**
- **AiService**: OpenAI API integration
- **ContextBuilder**: Assembles real-time sports data
- **ResponseBuilder**: Orchestrates AI response generation
- **SportsDataService**: ESPN API integration
- **NewsService**: ESPN news fetching
- **OddsApiService**: Betting odds API integration

### 2. JSONB for Flexibility
PostgreSQL JSONB columns store complex, nested data without requiring separate tables.

**Usage:**
- `User.favorite_sports` → Array of sport strings
- `User.favorite_teams` → Array of team objects
- `Team.colors` → Primary/secondary color hex codes
- `OddsCache.data` → Full API response from The Odds API

### 3. Async Jobs with Turbo Streams
Long-running operations (AI responses) run in background jobs and push updates via Turbo Streams.

**Flow:**
1. User submits message
2. Controller creates message, returns "thinking" indicator
3. Background job generates AI response
4. Job broadcasts response via Turbo Streams
5. Browser receives and displays response in real-time

### 4. Smart Caching
Different cache strategies for different data types:

| Data Type | Cache Duration | Storage |
|-----------|---------------|---------|
| Live games | 5 minutes | Rails.cache |
| Past games | 1 hour | Rails.cache |
| Standings | 30 minutes | Rails.cache |
| Injuries | 15 minutes | Rails.cache |
| News | 15 minutes | Rails.cache |
| Betting odds | 1 hour | OddsCache model |

### 5. Context Injection Pattern
AI responses use only real, verified data to prevent hallucinations.

**How it works:**
1. User asks question
2. ContextBuilder analyzes question intent
3. Fetches only relevant data from APIs
4. Formats data as text
5. Injects into system prompt as {CONTEXT_DATA}
6. AI responds using only injected context

**Smart filtering:**
- Betting questions → include odds data
- Standings questions → include league standings
- Injury questions → include injury reports
- Always include: today's games, recent results, news

## Technology Stack

### Backend
- **Ruby 3.4.5**
- **Rails 8.0.3**
- **PostgreSQL 17+**
- **Puma** web server
- **Solid Queue** for background jobs
- **Solid Cache** for caching
- **Solid Cable** for WebSockets

### Frontend
- **TailwindCSS 4.1** for styling
- **Hotwire Turbo** for SPA-like experience
- **Stimulus.js** for JavaScript interactions
- **Importmap** for JavaScript modules
- **Propshaft** for asset pipeline

### Authentication
- **Devise** for user authentication

### External APIs
- **OpenAI GPT-4o mini** via ruby-openai gem
- **ESPN Unofficial API** (no auth required)
- **The Odds API** (API key required)

### Deployment
- **Kamal** for Docker deployment
- **Thruster** for HTTP asset caching
- **Docker** for containerization

## Data Flow Patterns

### Chat Message Flow
```
User → MessagesController → Check rate limit → Create Message
    → Queue GenerateResponseJob → ContextBuilder fetches data
    → AiService calls OpenAI → Create assistant Message
    → Broadcast via Turbo Streams → Browser displays
```

### Onboarding Flow
```
Signup → Select sports → Select teams → Mark onboarded
    → Redirect to chats → Auto-create team channels
```

### Team Channel Display
```
Load chat → Detect is_team_channel → Fetch team data
    → Fetch news, results, upcoming games → Render read-only view
```

## Security Considerations

1. **Rate Limiting**: Per-user query limits by subscription tier
2. **Authentication**: Devise handles secure authentication
3. **API Keys**: Stored in Rails credentials or environment variables
4. **CSRF Protection**: Rails default protection enabled
5. **SQL Injection**: Parameterized queries via ActiveRecord
6. **XSS Protection**: Rails auto-escapes HTML in views

## Scalability Considerations

### Current Architecture
- Synchronous API calls in services
- Single PostgreSQL database
- In-memory caching (Rails.cache)
- Single server deployment

### Future Improvements
- Redis for distributed caching
- Background job queueing for all API calls
- API response caching layer (CDN)
- Database read replicas
- Horizontal scaling with load balancer
- Rate limiting via Redis

## Performance Optimizations

1. **API Caching**: Reduces external API calls
2. **JSONB Queries**: Fast querying of nested data
3. **Eager Loading**: N+1 query prevention
4. **Turbo Streams**: Avoids full page reloads
5. **Asset Pipeline**: Compiled and minified assets
6. **Database Indexes**: On foreign keys and frequently queried fields

## Monitoring & Observability

### Current
- Rails logs (log/development.log)
- Database query logging

### Recommended
- Application Performance Monitoring (APM) - New Relic, Datadog, etc.
- Error tracking - Sentry, Rollbar, etc.
- Uptime monitoring - Pingdom, UptimeRobot, etc.
- Log aggregation - Papertrail, Loggly, etc.

## Related Documentation

- [Data Flow](./data-flow.md) - Detailed request/response flows
- [API Integrations](./api-integrations.md) - External API documentation
- [Services Documentation](../services/) - Individual service docs
- [Models Documentation](../models/) - Database schema details
