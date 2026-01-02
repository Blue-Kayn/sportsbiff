# Changelog

All notable changes to Sports Biff will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2025-12-30] - Initial Setup

### Added
- Project cloned from GitHub repository
- Installed Ruby 3.4.8 via Homebrew
- Installed PostgreSQL 17.7 via Homebrew
- Installed all project dependencies (134 gems)
- Created development and test databases
- Ran all database migrations
- Seeded database with:
  - 82 teams (32 NFL, 30 NBA, 20 EPL)
  - 2 demo user accounts
  - Sample chat data
  - Odds cache entries
- Configured OpenAI API key in `.env` file
- Created comprehensive documentation system:
  - `/docs` folder structure (architecture, models, services, controllers, jobs, features, decisions)
  - `/docs/README.md` with quick start guide
  - `CHANGELOG.md` for tracking changes

### Configured
- PostgreSQL user `postgres` with password authentication
- Homebrew paths for Ruby and PostgreSQL in `.zshrc`
- PostgreSQL service started via Homebrew
- Environment variable `OPENAI_API_KEY` for AI functionality

### Documentation System Created
- Created `/docs` folder structure mirroring codebase organization:
  - `docs/architecture/` - System design, data flow, API integrations
  - `docs/models/` - Database models documentation
  - `docs/services/` - Business logic services
  - `docs/controllers/` - HTTP request handling
  - `docs/jobs/` - Background jobs
  - `docs/features/` - Feature-specific guides
  - `docs/decisions/` - Architecture Decision Records (ADRs)
- Created `docs/README.md` with quick start guide and project overview
- Created `docs/architecture/overview.md` with system architecture
- Created `docs/architecture/data-flow.md` with detailed request flows
- Created `docs/architecture/api-integrations.md` with external API documentation
- Created `docs/models/README.md` with model quick reference
- Created `docs/services/README.md` with services quick reference
- Updated `CLAUDE.md` to reference documentation system

### Deployment Ready
- Development environment fully set up
- Database seeded with demo data
- API keys configured
- Ready to run `bin/dev` to start application
- Living documentation system in place

---

## [2025-12-30] - SportsDataIO NFL Integration

### Added
- **SportsDataIO NFL API integration** for comprehensive, accurate NFL data
  - Base client with authentication and caching (`app/services/sports_data_io/base_client.rb`)
  - Cache manager with TTL-based caching (`app/services/sports_data_io/cache_manager.rb`)
  - Endpoint registry with 100+ NFL API endpoints (`app/services/sports_data_io/endpoint_registry.rb`)
  - Context service for season/week bootstrap (`app/services/sports_data_io/context_service.rb`)
  - Query router for intelligent question→endpoint mapping (`app/services/sports_data_io/query_router.rb`)
  - Context builder for AI prompt assembly (`app/services/sports_data_io/builders/context_builder.rb`)
- Environment variable `SPORTSDATA_API_KEY` for SportsDataIO authentication
- Smart caching strategy with TTLs from 3 seconds (live games) to 4 hours (teams)
- Lazy loading architecture - only fetches data needed for each question

### Changed
- Updated `ContextBuilder` to integrate SportsDataIO for NFL teams
- Updated CLAUDE.md with comprehensive SportsDataIO architecture documentation
- Modified `.env` to include SportsDataIO API key placeholder

### Improved
- NFL data accuracy - no more "I don't have the exact date" responses
- Response speed through intelligent caching
- Context relevance through query routing and entity extraction

### Technical Details
Architecture highlights:
- **Lazy Loading**: Only fetches endpoints required for the question
- **Smart Caching**: Different TTLs based on data volatility
- **Query Routing**: Pattern matching to determine needed data
- **Context Assembly**: Formats data for optimal AI consumption

Key endpoints:
- `current_season`/`current_week` - Temporal context (TTL: 5 min)
- `schedules` - Full season schedule (TTL: 3 min)
- `scores_by_week` - Live/recent scores (TTL: 5 sec)
- `standings` - Current standings (TTL: 5 min)
- `injuries_all` - Injury reports (TTL: 5 min)
- `news` - Latest news (TTL: 3 min)

### Notes
- SportsDataIO replaces ESPN unofficial API for NFL data only
- ESPN API still used for NBA and EPL
- Requires API key from sportsdata.io
- Free tier available for development/testing

---

## Template for Future Entries

```markdown
## [YYYY-MM-DD]

### Added
- New features, files, or functionality

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes

### Removed
- Removed features or files

### Security
- Security improvements or patches
```
