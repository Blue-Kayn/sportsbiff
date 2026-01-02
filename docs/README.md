# Sports Biff Documentation

> Your personalized sports companion - Real-time news, scores, and market intelligence tailored to your favorite teams.

## Quick Start

### Prerequisites
- Ruby 3.4.5+
- PostgreSQL 17+
- OpenAI API Key (required)
- The Odds API Key (optional - for betting market data)

### Installation

```bash
# Clone the repository
git clone https://github.com/Blue-Kayn/sportsbiff.git
cd sportsbiff

# Install dependencies
bundle install

# Set up database
rails db:create
rails db:migrate
rails db:seed

# Configure API keys in .env file
echo "OPENAI_API_KEY=your_key_here" >> .env
echo "ODDS_API_KEY=your_key_here" >> .env  # optional

# Start the development server
bin/dev
```

### Demo Accounts

After seeding:
- **Demo Account**: `demo@sportsbiff.com` / `demo123456` (Pro tier, 500 queries/day, onboarded)
- **Test Account**: `test@example.com` / `password123` (Free tier, 10 queries/day, not onboarded)

## Project Overview

Sports Biff is a Rails 8 SaaS application that provides personalized sports intelligence through:

- **Personalized Chat Interface** - AI-powered conversations about your favorite teams
- **Team Channels** - Auto-updating news feeds for each favorite team
- **Real-time Sports Data** - Scores, schedules, standings from ESPN
- **Market Intelligence** - Betting odds as information (not advice)
- **Smart Context** - AI responses use only real, verified data (no hallucinations)

## Tech Stack

- **Backend**: Ruby on Rails 8.0.3, PostgreSQL
- **Frontend**: TailwindCSS, Hotwire (Turbo + Stimulus)
- **AI**: OpenAI GPT-4o mini
- **APIs**: ESPN (unofficial), The Odds API
- **Deployment**: Kamal + Docker

## Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ (Turbo Streams)
┌──────▼──────────────┐
│   Controllers       │
│ ├─ Chats            │
│ ├─ Messages         │
│ └─ Onboarding       │
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│   Services          │
│ ├─ ResponseBuilder  │ ← Orchestration
│ ├─ ContextBuilder   │ ← Data gathering
│ ├─ AiService        │ ← OpenAI
│ ├─ SportsDataService│ ← ESPN API
│ ├─ NewsService      │ ← ESPN News
│ └─ OddsApiService   │ ← The Odds API
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│   Background Jobs   │
│ └─ GenerateResponseJob
└─────────────────────┘
```

## Documentation Structure

- [CHANGELOG.md](../CHANGELOG.md) - Project history and changes
- [architecture/](./architecture/) - System design and data flow
- [models/](./models/) - Database models documentation
- [services/](./services/) - Business logic services
- [controllers/](./controllers/) - HTTP request handling
- [jobs/](./jobs/) - Background job documentation
- [features/](./features/) - Feature-specific guides
- [decisions/](./decisions/) - Architecture Decision Records (ADRs)

## Key Commands

```bash
# Development
bin/dev                    # Start server + Tailwind watcher
rails console              # Rails console

# Database
rails db:migrate           # Run migrations
rails db:seed              # Seed demo data
rails db:reset             # Reset database

# Testing
rails test                 # Run tests
rails test:system          # Run system tests

# Code Quality
bin/rubocop                # Lint Ruby code
bin/brakeman --no-pager    # Security scan
```

## Supported Sports

- NFL (American Football)
- NBA (Basketball)
- MLB (Baseball)
- NHL (Hockey)
- EPL (English Premier League)
- MLS (Major League Soccer)

## Rate Limits

| Tier  | Queries/Day |
|-------|-------------|
| Free  | 10          |
| Basic | 50          |
| Pro   | 500         |

## Environment Variables

Required:
```bash
OPENAI_API_KEY=sk-...     # OpenAI API key
```

Optional:
```bash
ODDS_API_KEY=...          # The Odds API key
RAILS_ENV=development     # Environment
DATABASE_URL=...          # Database connection
```

## Project Goals

**MVP Goal**: Build a beloved daily-use app for sports fans

**Success Metrics**:
- Daily active usage
- User retention
- Query engagement

**Long-term Vision**: £10M+ acquisition target

## Contributing

See [CLAUDE.md](../CLAUDE.md) for development workflow and AI assistant guidelines.

## License

Proprietary - All rights reserved
