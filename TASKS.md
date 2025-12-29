# SportsBiff MVP - Task Breakdown

Use these tasks one at a time in Claude Code sessions. Each task should be completable in one session. Commit after each.

---

## Phase 1: Foundation (Day 1-2)

### Task 1.1: Project Setup
```
Create a new Rails 8 app called 'sportsbiff' with PostgreSQL. 
Set up the basic structure:
- Initialize with Rails 8 defaults
- Configure PostgreSQL database
- Add TailwindCSS
- Create a basic home page that just says "SportsBiff - Coming Soon"
- Make sure it runs with bin/dev

Do not add authentication yet.
```

### Task 1.2: Authentication
```
Add Devise authentication to the app:
- Install and configure Devise
- Generate User model with Devise
- Add these extra fields to users: query_count (integer, default 0), daily_query_limit (integer, default 20)
- Create basic sign up and login pages styled with Tailwind
- Add a simple navbar with login/logout links
- Redirect logged-in users to /dashboard (create a placeholder page)
```

### Task 1.3: Chat Data Models
```
Create the data models for the chat system:
- Chat model: belongs_to user, has_many messages, title (string)
- Message model: belongs_to chat, role (string: 'user' or 'assistant'), content (text), tokens_used (integer)
- Add appropriate indexes
- Create and run migrations
- Add model validations
```

---

## Phase 2: Chat Interface (Day 3-4)

### Task 2.1: Basic Chat UI
```
Build the chat interface:
- ChatsController with index, show, create actions
- MessagesController with create action
- Chat index page showing user's chat history (sidebar style)
- Chat show page with:
  - Message history displayed nicely (user messages right-aligned, AI left-aligned)
  - Input field at bottom with send button
  - Use Turbo Frames for the message list
- Style it clean and minimal with Tailwind
- New chat button that creates a chat and redirects to it

No AI integration yet - just store messages with placeholder responses like "AI response coming soon"
```

### Task 2.2: Real-time Messages with Turbo
```
Make the chat feel real-time:
- Use Turbo Streams to append new messages without page reload
- Add a loading indicator while "AI is thinking"
- Auto-scroll to bottom when new messages arrive
- Disable send button while waiting for response
- Add timestamps to messages (relative time like "2 min ago")
```

---

## Phase 3: Odds API Integration (Day 5-6)

### Task 3.1: Odds API Service
```
Create a service to fetch NFL odds from The Odds API:
- OddsApiService class in app/services/
- Initialize with a sport parameter (default: 'americanfootball_nfl')
- Method to fetch upcoming games with odds for given sport
- Method to fetch odds for a specific game
- Method to fetch player props (if available on our plan)
- Parse and structure the response data nicely
- Handle API errors gracefully
- Add the API key to Rails credentials

The service should be sport-agnostic - we'll add NBA, MLB etc later. Don't hardcode NFL.

Test it in the console to make sure it works. The API endpoint is:
https://api.the-odds-api.com/v4/sports/{sport}/odds

Check their docs at https://the-odds-api.com/liveapi/guides/v4/ for parameters.
```

### Task 3.2: Odds Caching
```
Cache odds data to reduce API calls:
- Create OddsCache model: sport (string), event_key (string), data (jsonb), expires_at (datetime)
- Add methods to OddsApiService to check cache before fetching
- Cache odds for 5 minutes
- Add a background job (Sidekiq or Solid Queue) to refresh odds for upcoming games
- Add rake task to manually refresh odds: rails odds:refresh
```

---

## Phase 4: AI Integration (Day 7-9)

### Task 4.1: AI Service Setup
```
Create the AI service to call Claude API:
- AiService class in app/services/
- Method to send a message and get a response
- Use the Anthropic Ruby SDK (anthropic gem)
- Add API key to credentials
- Basic system prompt that says it's a sports betting assistant
- Handle API errors and rate limits
- Return the response text and token count

Test it in console with a simple query like "Who are the favorites this week in the NFL?"
```

### Task 4.2: System Prompt Engineering
```
Create a comprehensive system prompt for the AI:
- Create prompts/system_prompt.md with the full prompt
- The AI should:
  - Be a knowledgeable NFL betting assistant
  - Give concise, actionable answers
  - Include specific odds when relevant
  - Explain the "why" behind recommendations
  - Never guarantee wins, always mention betting is risky
  - Be conversational, not robotic
- Load this prompt in AiService
- Test with various query types:
  - "Who should I bet on this Sunday?"
  - "What's the over/under for Chiefs vs Raiders?"
  - "Any good player props for this week?"
```

### Task 4.3: Connect AI with Odds Data
```
Create a ResponseBuilder service that:
- Takes the user's question
- Fetches relevant odds data from cache/API
- Builds a context block with current NFL odds, upcoming games, relevant stats
- Sends this context + user question to AI
- Returns the AI's response

The AI should have access to:
- Current odds for all upcoming NFL games
- Spreads, moneylines, and totals from multiple bookmakers
- The user's question

Wire this up to the MessagesController so real AI responses appear in chat.
```

---

## Phase 5: Polish & Rate Limiting (Day 10-12)

### Task 5.1: Query Rate Limiting
```
Add rate limiting to prevent abuse:
- Track queries per user per day in the query_count field
- Reset count daily (add a reset_query_count_at datetime field)
- Check limit before processing a message
- Show friendly error if limit exceeded: "You've used all 20 free queries today. Upgrade for more!"
- Display remaining queries somewhere in the UI
- Add a QueryUsage model to track history: user_id, date, count
```

### Task 5.2: UI Polish
```
Make the UI demo-ready:
- Professional looking header/branding (SportsBiff)
- Clean chat interface with good spacing
- Mobile responsive
- Loading states that look good
- Error messages that are helpful
- Empty state for new users ("Ask me anything about NFL betting!")
- Add some example questions users can click to try
```

### Task 5.3: Landing Page
```
Create a landing page for logged-out users:
- Hero section: "Your AI Sports Betting Assistant"
- Brief explanation of what it does
- Example questions it can answer
- CTA to sign up
- Simple, clean, professional
- Make it look like a legit startup, not a side project
```

---

## Phase 6: Demo Prep (Day 13-14)

### Task 6.1: Seed Data & Demo Account
```
Prepare for the demo:
- Create a demo user account with higher query limits
- Seed some example chat conversations showing good interactions
- Make sure odds data is fresh and cached
- Test all the example queries work well
- Fix any bugs found during testing
```

### Task 6.2: Final Testing & Deploy
```
Get it live:
- Set up production environment (Render, Railway, or Heroku)
- Configure production database
- Set environment variables
- Deploy and test on production URL
- Make sure everything works: auth, chat, AI responses, odds data
- Document the demo URL and login credentials
```

---

## How to Use This

1. Start Claude Code in the project directory
2. Copy one task into Claude Code
3. Let it complete the task
4. Test it works
5. Commit: `git add . && git commit -m "Task X.X: description"`
6. Update CLAUDE.md status section
7. Move to next task

If Claude Code loses context, it will read CLAUDE.md and understand the project.
