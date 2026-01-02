# Models Documentation

Sports Biff uses 5 core models for data persistence.

## Quick Reference

| Model | Purpose | Key Fields |
|-------|---------|------------|
| [User](./user.md) | Authentication + personalization | favorite_sports, favorite_teams, subscription_tier |
| [Chat](./chat.md) | Conversations + team channels | user_id, team_id, is_team_channel |
| [Message](./message.md) | Chat messages | chat_id, role, content, tokens_used |
| [Team](./team.md) | Sports team metadata | name, sport, api_id, colors, logo_url |
| [OddsCache](./odds-cache.md) | Betting odds cache | sport, event_id, data (JSONB), fetched_at |

## Database Schema

See: [db/schema.rb](../../db/schema.rb:1) for full schema.

## Relationships

```
User
 ├─ has_many :chats
 └─ (JSONB) favorite_teams references Team.api_id

Chat
 ├─ belongs_to :user
 ├─ belongs_to :team (optional, via api_id)
 └─ has_many :messages

Message
 └─ belongs_to :chat

Team
 └─ (referenced by Chat.team_id and User.favorite_teams)

OddsCache
 └─ (standalone cache table)
```

## JSONB Usage

### User.favorite_teams
```json
[
  {"sport": "NFL", "team_id": "nyg", "team_name": "New York Giants"},
  {"sport": "NBA", "team_id": "lal", "team_name": "Los Angeles Lakers"}
]
```

### Team.colors
```json
{
  "primary": "#0B2265",
  "secondary": "#A71930"
}
```

### OddsCache.data
```json
{
  "id": "abc123",
  "sport_key": "americanfootball_nfl",
  "home_team": "Dallas Cowboys",
  "away_team": "New York Giants",
  "bookmakers": [...]
}
```
