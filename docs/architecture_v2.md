# SportsBiff Complete Architecture Documentation v2.0

> **READ THIS FIRST**: This document replaces all previous architecture decisions. The app has been fundamentally redesigned.

---

## PART 1: WHAT SPORTSBIFF IS

### The Vision

SportsBiff is **ChatGPT for sports fans with betting intelligence**.

Users should feel like they're talking to a knowledgeable sports friend who:
- Knows everything about NFL (and eventually other sports)
- Gives rich, contextual, interesting answers - not database readouts
- Has access to cutting-edge betting data and analysis
- Remembers their favorite teams and preferences
- Asks smart follow-up questions
- Never sounds like a robot or a database

### The User Experience We Want

**User:** "Did the Panthers make the playoffs?"

**BAD (what we had):**
> "The Carolina Panthers have a DivisionRank of 1, which means they won their division. This guarantees them an automatic playoff berth despite their 8-9 record."

**GOOD (what we want):**
> "Yeah! The Panthers snuck in despite going 8-9 - they won the NFC South which gets them an automatic playoff spot. They're actually making history as one of the few teams to ever make the playoffs with a losing record. The 2010 Seahawks did it at 7-9, but this is still wild. They'll host a home playoff game against a team with a better record than them. Gotta love divisional football.
>
> You following the Panthers this season or just curious about the playoff picture?"

The second answer is:
- Conversational and warm
- Packed with context and interesting facts
- Adds historical perspective
- Ends with a natural follow-up question
- Sounds like a sports-savvy friend, not a database

---

## PART 2: THE ARCHITECTURAL DECISION

### Why We Changed Everything

**The Old Approach:**
1. User asks question
2. We call SportsDataIO API
3. We get raw data (DivisionRank: 1, Wins: 8, Losses: 9)
4. We tell the AI to "make it sound nice"
5. Result: Robotic answers that leak field names

**The Problem:**
- Sports journalists have ALREADY written great explanations
- ChatGPT + web search gives better answers than our API approach
- We were reinventing the wheel with a worse wheel
- Users don't want data, they want conversation

**The New Approach:**
1. User asks question
2. 90% of questions → Web search (like ChatGPT does)
3. 10% of questions → API (betting math, live scores, user-specific data)
4. Result: Expert answers with real betting intelligence

### The Simple Rule

| Question Type | Source | Why |
|---------------|--------|-----|
| General Q&A, facts, narratives | Web Search | Journalists already wrote great answers |
| News, rumors, analysis | Web Search | This is what search is for |
| Historical context, records | Web Search | "First team since 2014 to..." |
| Expert picks, predictions | Web Search | Analysts already published these |
| **Betting math** (did spread cover?) | API | Must compute: score + line = result |
| **Prop analysis** (hit rates, trends) | API | Must aggregate across games |
| **Live scores** (in-progress games) | API | Faster than search indexing |
| **User's favorite teams** (stored in DB) | Database | Personalization |
| **User's bet history** | Database + API | Tracking feature |

---

## PART 3: THE ROUTING SYSTEM

### How to Decide: Web Search or API?

```
DECISION TREE:

User asks question
      |
      v
+-------------------------------------------------------------+
| Does the question require COMPUTATION or LIVE DATA?         |
|                                                             |
| Computation = math on betting lines, aggregating stats      |
| Live Data = current score of in-progress game               |
+-------------------------------------------------------------+
      |
      +-- YES --> Use API
      |
      +-- NO ---> Use Web Search
```

### Specific Routing Rules

**ALWAYS USE WEB SEARCH FOR:**

```
- "Did [team] make the playoffs?"
- "Who won [game]?"
- "Is [player] injured?"
- "Who's the best [position]?"
- "Who should win [matchup]?"
- "What are experts saying about [game]?"
- "Tell me about [player]'s season"
- "Why are the [team] so good/bad?"
- "What's the story with [player/team]?"
- "Who's the MVP favorite?"
- "Any trade rumors?"
- "What happened in [game]?"
- "Who has the best record?"
- "Playoff picture/standings?"
- "Historical facts about [team/player]"
- "Records, streaks, milestones"
- "Draft news"
- "Coaching changes"
- "Anything asking for analysis or opinion"
- "Anything asking for context or narrative"
- "Anything a sports journalist would write about"
```

**ALWAYS USE API FOR:**

```
- "Did [team] cover the spread?"
- "Did the over/under hit?"
- "What's [player]'s prop hit rate?"
- "Show me teams that cover as underdogs"
- "Line movement on [game]"
- "What's the spread/total/moneyline right now?"
- "Compare odds across sportsbooks"
- "My bet history / ROI"
- "Track this bet for me"
- "What props have been hitting?"
- "Current score of [in-progress game]"
- "Live odds during game"
- "Anything requiring: actual_result vs betting_line"
- "Anything requiring: aggregation across multiple games"
- "Anything requiring: real-time data (within minutes)"
- "Anything about the user's stored teams/preferences"
```

### The Hybrid Case

Some questions need BOTH:

**"Should I bet the over on Chiefs vs Bills?"**

1. **API** -> Get the current over/under line, recent over/under results for both teams
2. **Web Search** -> Get weather report, injury news, expert analysis
3. **Combine** -> "The total is 52.5. Chiefs games have gone over in 7 of their last 10, and both offenses are healthy. Weather looks fine - 45F, no wind. Most experts like the over here. That said, Bills defense has been stingy lately, holding opponents under 20 in three straight."

---

## PART 4: WEB SEARCH IMPLEMENTATION

### How Web Search Should Work

When using web search, the AI should:

1. **Search smartly** - Use specific queries that will find good sources
2. **Synthesize, don't copy** - Read multiple sources, combine into original answer
3. **Add personality** - Sound like a knowledgeable friend, not a search result
4. **Cite when useful** - "According to ESPN..." but don't overdo it
5. **Follow up naturally** - Ask relevant questions to continue conversation

### Web Search Query Strategy

**BAD QUERIES:**
```
"Panthers playoffs 2024"  <- Too vague
"did the panthers make the playoffs"  <- Too literal
```

**GOOD QUERIES:**
```
"Panthers NFC South 2024 playoff clinch"
"Panthers 8-9 record playoffs history"
"NFL playoff picture 2024 NFC"
```

**QUERY CONSTRUCTION RULES:**
- Include team/player name
- Include season/year
- Include specific topic (playoffs, injury, trade)
- Use 3-6 keywords, not full sentences
- Search multiple times if needed for complete picture

### Response Style for Web Search Answers

**RULES:**
1. Never say "Based on my search..." or "According to search results..."
2. Never list sources at the end like a bibliography
3. Integrate information naturally as if you just know it
4. Add color, context, and interesting tangents
5. Use conversational language ("Yeah", "Actually", "Wild, right?")
6. End with a follow-up question when natural (not forced)
7. Match the user's energy (casual question = casual answer)

**BANNED PHRASES:**
```
- "Based on the search results..."
- "According to my findings..."
- "The data shows..."
- "Sources indicate..."
- "I found that..."
- "My search reveals..."
- "Here's what I found:"
- "Let me search for that..."
```

**GOOD PHRASES:**
```
- "Yeah, so..."
- "Actually, funny story..."
- "Here's the thing..."
- "What's crazy is..."
- "The interesting part is..."
- "So basically..."
- "Turns out..."
```

---

## PART 5: API IMPLEMENTATION (BETTING DATA)

### When to Use the API

The API is ONLY for things web search cannot do:

1. **Betting Math** - Computing if bets won/lost
2. **Aggregations** - "How often does X happen?"
3. **Live Data** - Scores of in-progress games
4. **User Data** - Their teams, their bets, their history

### Betting Questions the API Handles

**CATEGORY 1: Did the bet win?**
```
"Did the Cowboys cover?"
"Did the over hit in the Chiefs game?"
"Was the Eagles -3.5 a winner?"
"Push or cover?"
```

**CATEGORY 2: Prop Results**
```
"Did Mahomes hit the over on passing yards?"
"How often does Derrick Henry go over 80 rushing yards?"
"Which QBs are hitting their passing props?"
```

**CATEGORY 3: Current Lines**
```
"What's the spread on Chiefs vs Bills?"
"What's the over/under?"
"Moneyline odds?"
"Best odds across books?"
```

**CATEGORY 4: Line Movement**
```
"Has the line moved?"
"Where did this open?"
"Sharp money movement?"
```

**CATEGORY 5: Trends & Aggregations**
```
"Teams that cover as home underdogs"
"Over/under trends for [team]"
"ATS record for [team]"
"Best props to bet this week"
```

**CATEGORY 6: Live Game Data**
```
"What's the score of the Chiefs game?"
"Who's winning?"
"What quarter is it?"
"Is the game over?"
```

### Never Expose Field Names

**BANNED IN RESPONSES:**
```
- "DivisionRank"
- "ConferenceRank"
- "IsClosed"
- "PointSpread"
- "HomePointSpread"
- "AwayPointSpread"
- "OverUnder"
- "ScoreID"
- "GameID"
- "PlayerID"
- Any field that looks like code
```

**TRANSLATIONS:**
```
DivisionRank = 1         -> "division winner" / "won the division"
ConferenceRank = 3       -> "3 seed" / "third in the NFC"
IsClosed = true          -> "game is final"
PointSpread = -3.5       -> "3.5-point favorite"
OverUnder = 48.5         -> "total is 48.5" / "over/under at 48.5"
InjuryStatus = "Out"     -> "ruled out" / "not playing"
DepthOrder = 1           -> "starter"
```

---

## PART 6: USER PERSONALIZATION

### Stored User Data

Each user can have:
```
- Favorite teams (e.g., ["Cowboys", "Mavericks"])
- Followed players (e.g., ["Patrick Mahomes", "Dak Prescott"])
- Bet history (tracked bets with results)
- Preferences (notification settings, etc.)
```

### How to Use Stored Teams

When a user has favorite teams stored:

1. **Proactive relevance** - If they ask about playoffs and follow the Cowboys, mention Cowboys context
2. **Assumed context** - "How did we do?" probably means their favorite team
3. **Don't overdo it** - Don't shoehorn their team into every answer

---

## PART 7: FOLLOW-UP QUESTIONS

### The Goal

End responses with natural follow-up questions that:
- Show genuine interest
- Lead to deeper conversation
- Are relevant to what was just discussed
- Don't feel forced or robotic

### Good Follow-Up Questions

**After answering about a game:**
- "You catch the game or just checking the score?"
- "That [play/moment] was insane, right?"
- "You got any action on this one?"

**After answering about a player:**
- "Is he on your fantasy team?"
- "You think he's legit or just having a moment?"

**After answering about playoffs:**
- "Who's your pick to come out of the [conference]?"
- "You think they can make a run?"

**After answering about betting:**
- "You tailing that or fading?"
- "What's your lean on this one?"

---

## PART 8: RESPONSE FORMATTING

### General Rules

1. **No bullet points for conversation** - Write in paragraphs like a human
2. **Bullets OK for lists they asked for** - "Rank the top 5 QBs" = bullets fine
3. **No headers in chat responses** - Save those for long-form content
4. **Short paragraphs** - 2-4 sentences each
5. **Line breaks between topics** - Readable, not walls of text

---

## PART 9: SUMMARY

### The Core Architecture

```
USER QUESTION
      |
      v
  +---------------------------+
  |   ROUTING DECISION        |
  |                           |
  |   Needs betting math?     |
  |   Needs live scores?      |
  |   Needs user's stored data|
  +---------------------------+
      |
      +-- YES --> SportsDataIO API --> Compute --> Human response
      |
      +-- NO ---> Web Search --> Synthesize --> Human response
```

### The Response Philosophy

1. **Sound like a knowledgeable sports friend**
2. **Never expose technical internals**
3. **Rich context over raw data**
4. **Natural conversation over Q&A format**
5. **Follow-ups that show genuine interest**

### The Non-Negotiables

- Web search for Q&A, narratives, context
- API only for betting math, live data, user data
- Never say "DivisionRank" or any field name
- Never announce "searching" or "checking API"
- Always human, never robotic

---

## APPENDIX: QUICK REFERENCE

### Use Web Search When:
- General questions about teams/players
- News, rumors, analysis
- Historical facts, records
- Expert opinions, predictions
- Anything a journalist would write about

### Use API When:
- "Did X cover the spread?"
- "Did the over/under hit?"
- "Prop hit rates"
- "Current lines"
- "Live score"
- Computing any bet result

### Never Say:
- "DivisionRank", "ConferenceRank", etc.
- "Based on my search..."
- "The data shows..."
- "Let me check..."

### Always Do:
- Sound human
- Add context
- Tell stories
- Ask follow-ups
- Be conversational
