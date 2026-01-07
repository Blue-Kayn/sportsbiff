# SportsBiff Quick Menu - Complete Implementation Spec

## READ THIS FIRST, CLAUDE CODE

This document specifies a **dynamic nested menu** for the SportsBiff chat interface. The menu:
- Lives in the bottom-right of the chat input area
- Opens/closes without page refresh
- Has nested levels (Sport → Category → Question)
- Some questions need user input (team/player selection) before sending
- Uses Stimulus.js for interactivity (standard Rails 7+ approach)
- Sends the final question to the chat input and submits

**DO NOT:**
- Use React or Vue (this is a Rails app)
- Refresh the page on any interaction
- Create separate pages for menu levels
- Overcomplicate this - it's a simple nested menu with some dynamic inputs

---

## PART 1: MENU STRUCTURE OVERVIEW

```
[Chat Input]                              [📋 Menu Button]
                                                │
                                                ▼
                                    ┌──────────────────────┐
                                    │ 🏈 NFL               │
                                    │ 🏀 NBA               │
                                    │ ⚾ MLB               │
                                    │ ⚽ Soccer            │
                                    │ 🏒 NHL               │
                                    └──────────────────────┘
                                                │
                                         (click NFL)
                                                ▼
                                    ┌──────────────────────┐
                                    │ ← Back               │
                                    │──────────────────────│
                                    │ 📊 Games & Scores    │
                                    │ 🏆 Standings         │
                                    │ 🏥 Injuries & News   │
                                    │ 💰 Betting           │
                                    │ 🎮 Fantasy           │
                                    │ 📈 Stats & Players   │
                                    └──────────────────────┘
                                                │
                                        (click Betting)
                                                ▼
                                    ┌──────────────────────┐
                                    │ ← NFL                │
                                    │──────────────────────│
                                    │ What's the spread?   │
                                    │ Did they cover?      │
                                    │ Over/under result?   │
                                    │ Line movement        │
                                    │ Best bets this week  │
                                    │ Prop hit rates       │
                                    └──────────────────────┘
                                                │
                                    (click "Did they cover?")
                                                ▼
                                    ┌──────────────────────┐
                                    │ ← Betting            │
                                    │──────────────────────│
                                    │ Select team:         │
                                    │ [🔍 Search...]       │
                                    │ ──────────────────── │
                                    │ Cowboys              │
                                    │ Eagles               │
                                    │ Chiefs               │
                                    │ ...                  │
                                    └──────────────────────┘
                                                │
                                         (click Cowboys)
                                                ▼
                            Chat input receives: "Did the Cowboys cover?"
                            Auto-submits to chat
```

---

## PART 2: QUESTION INPUT TYPES

Every menu item has an `input_type` that determines behavior:

### Type: `direct`
No user input needed. Clicking sends the question immediately.

```ruby
{
  label: "Who won yesterday?",
  input_type: :direct,
  template: "Who won yesterday's NFL games?"
}
# Click → Sends "Who won yesterday's NFL games?" → Closes menu
```

### Type: `team_select`
Shows a team picker. User selects team, then question sends.

```ruby
{
  label: "Did [team] cover?",
  input_type: :team_select,
  template: "Did the {team} cover the spread?"
}
# Click → Shows team list → User picks "Cowboys" → Sends "Did the Cowboys cover the spread?"
```

### Type: `my_team`
Uses the user's stored favorite team. If no favorite, prompts to set one.

```ruby
{
  label: "How did my team do?",
  input_type: :my_team,
  template: "How did the {my_team} do this week?"
}
# If favorite = Cowboys → Sends "How did the Cowboys do this week?"
# If no favorite → Shows "Set your favorite team" prompt
```

### Type: `player_search`
Shows a search box with autocomplete for player names.

```ruby
{
  label: "[Player] stats this season",
  input_type: :player_search,
  template: "What are {player}'s stats this season?"
}
# Click → Shows search box → User types "Maho" → Autocomplete shows "Patrick Mahomes" → Click → Sends
```

### Type: `game_select`
Shows a list of current/recent games to pick from.

```ruby
{
  label: "What's the score?",
  input_type: :game_select,
  template: "What's the score of the {away_team} vs {home_team} game?"
}
# Click → Shows today's games → User picks "Chiefs @ Bills" → Sends
```

### Type: `week_select`
Shows a week picker (Week 1-18, Wild Card, Divisional, etc.)

```ruby
{
  label: "Week [X] results",
  input_type: :week_select,
  template: "What were the Week {week} NFL results?"
}
```

### Type: `position_select`
Shows position picker (QB, RB, WR, TE, K, DEF)

```ruby
{
  label: "[Position] rankings this week",
  input_type: :position_select,
  template: "What are the {position} rankings this week?"
}
```

### Type: `two_player_select`
For comparisons - shows two sequential player searches.

```ruby
{
  label: "Compare [player] vs [player]",
  input_type: :two_player_select,
  template: "Compare {player1} vs {player2}"
}
```

---

## PART 3: COMPLETE NFL MENU DATA

```ruby
# config/menu_data/nfl.rb or app/models/concerns/nfl_menu.rb

NFL_MENU = {
  sport: "NFL",
  icon: "🏈",
  categories: [
    {
      name: "Games & Scores",
      icon: "📊",
      questions: [
        { label: "What's the score right now?", input_type: :game_select, template: "What's the score of the {game} game?" },
        { label: "Who won yesterday?", input_type: :direct, template: "Who won yesterday's NFL games?" },
        { label: "How did my team do?", input_type: :my_team, template: "How did the {my_team} do?" },
        { label: "Week results", input_type: :week_select, template: "What were the Week {week} NFL results?" },
        { label: "When do the [team] play next?", input_type: :team_select, template: "When do the {team} play next?" },
        { label: "What channel is the [team] game on?", input_type: :team_select, template: "What channel is the {team} game on?" },
        { label: "Any upsets this week?", input_type: :direct, template: "Were there any upsets in the NFL this week?" },
        { label: "Biggest blowout this week?", input_type: :direct, template: "What was the biggest blowout in the NFL this week?" },
        { label: "Any overtime games?", input_type: :direct, template: "Were there any overtime games in the NFL this week?" },
        { label: "Thursday Night Football result", input_type: :direct, template: "What was the Thursday Night Football result?" },
        { label: "Sunday Night Football result", input_type: :direct, template: "What was the Sunday Night Football result?" },
        { label: "Monday Night Football result", input_type: :direct, template: "What was the Monday Night Football result?" }
      ]
    },
    {
      name: "Standings & Playoffs",
      icon: "🏆",
      questions: [
        { label: "Is [team] in the playoffs?", input_type: :team_select, template: "Are the {team} in the playoffs?" },
        { label: "Is my team in the playoffs?", input_type: :my_team, template: "Are the {my_team} in the playoffs?" },
        { label: "Who won the [division]?", input_type: :division_select, template: "Who won the {division}?" },
        { label: "What's the playoff bracket?", input_type: :direct, template: "What's the current NFL playoff bracket?" },
        { label: "Who has the best record?", input_type: :direct, template: "Which NFL team has the best record?" },
        { label: "Who has the worst record?", input_type: :direct, template: "Which NFL team has the worst record?" },
        { label: "Wild card race update", input_type: :direct, template: "What's the NFL wild card race looking like?" },
        { label: "NFC standings", input_type: :direct, template: "What are the current NFC standings?" },
        { label: "AFC standings", input_type: :direct, template: "What are the current AFC standings?" },
        { label: "[Team] record", input_type: :team_select, template: "What is the {team}'s record this season?" },
        { label: "My team's record", input_type: :my_team, template: "What is the {my_team}'s record this season?" },
        { label: "Which teams have clinched?", input_type: :direct, template: "Which NFL teams have clinched playoff spots?" },
        { label: "Which teams are eliminated?", input_type: :direct, template: "Which NFL teams are eliminated from playoff contention?" },
        { label: "Who gets the #1 pick?", input_type: :direct, template: "Which team is projected to get the #1 draft pick?" }
      ]
    },
    {
      name: "Injuries & News",
      icon: "🏥",
      questions: [
        { label: "Is [player] playing this week?", input_type: :player_search, template: "Is {player} playing this week?" },
        { label: "Who's out for [team]?", input_type: :team_select, template: "Who's out for the {team} this week?" },
        { label: "My team's injury report", input_type: :my_team, template: "What's the {my_team}'s injury report?" },
        { label: "Full injury report", input_type: :direct, template: "What's the full NFL injury report for this week?" },
        { label: "Who's questionable?", input_type: :direct, template: "Which NFL players are listed as questionable this week?" },
        { label: "Latest NFL news", input_type: :direct, template: "What's the latest NFL news?" },
        { label: "[Team] news", input_type: :team_select, template: "What's the latest news on the {team}?" },
        { label: "[Player] news", input_type: :player_search, template: "What's the latest news on {player}?" },
        { label: "Any trades today?", input_type: :direct, template: "Were there any NFL trades today?" },
        { label: "Recent signings", input_type: :direct, template: "What are the recent NFL free agent signings?" },
        { label: "Who got cut?", input_type: :direct, template: "Which players were cut or released recently?" },
        { label: "Coach firings/hirings", input_type: :direct, template: "Any recent NFL coaching changes?" }
      ]
    },
    {
      name: "Betting",
      icon: "💰",
      questions: [
        # Current Lines
        { label: "What's the spread on [game]?", input_type: :game_select, template: "What's the spread on the {game} game?" },
        { label: "What's the over/under?", input_type: :game_select, template: "What's the over/under for the {game} game?" },
        { label: "Moneyline odds", input_type: :game_select, template: "What are the moneyline odds for {game}?" },
        { label: "All Week [X] lines", input_type: :week_select, template: "What are all the Week {week} NFL betting lines?" },

        # Results
        { label: "Did [team] cover?", input_type: :team_select, template: "Did the {team} cover the spread?" },
        { label: "Did my team cover?", input_type: :my_team, template: "Did the {my_team} cover the spread?" },
        { label: "Did the over hit?", input_type: :game_select, template: "Did the over hit in the {game} game?" },
        { label: "Which underdogs covered?", input_type: :direct, template: "Which underdogs covered this week?" },
        { label: "Which favorites covered?", input_type: :direct, template: "Which favorites covered this week?" },

        # Line Movement
        { label: "Line movement on [game]", input_type: :game_select, template: "What's the line movement on {game}?" },
        { label: "Biggest line moves this week", input_type: :direct, template: "What are the biggest line moves this week?" },

        # Analysis & Picks
        { label: "Best bets this week", input_type: :direct, template: "What are the best NFL bets this week?" },
        { label: "Expert picks this week", input_type: :direct, template: "What are the expert picks for NFL this week?" },
        { label: "Public betting percentages", input_type: :direct, template: "What are the public betting percentages for NFL this week?" },

        # Props
        { label: "[Player] prop odds", input_type: :player_search, template: "What are the prop odds for {player} this week?" },
        { label: "[Player] prop hit rate", input_type: :player_search, template: "What's {player}'s prop hit rate this season?" },
        { label: "Anytime TD scorer odds", input_type: :game_select, template: "What are the anytime touchdown scorer odds for {game}?" },

        # Trends
        { label: "[Team] ATS record", input_type: :team_select, template: "What's the {team}'s record against the spread this season?" },
        { label: "[Team] over/under record", input_type: :team_select, template: "What's the {team}'s over/under record this season?" },
        { label: "Home underdogs this week", input_type: :direct, template: "Which home underdogs should I look at this week?" },
        { label: "Road favorites this week", input_type: :direct, template: "Which road favorites should I look at this week?" },

        # Futures
        { label: "Super Bowl odds", input_type: :direct, template: "What are the current Super Bowl odds?" },
        { label: "MVP odds", input_type: :direct, template: "What are the current NFL MVP odds?" },
        { label: "[Team] to win Super Bowl", input_type: :team_select, template: "What are the {team}'s Super Bowl odds?" }
      ]
    },
    {
      name: "Fantasy",
      icon: "🎮",
      questions: [
        # Start/Sit
        { label: "Start or sit [player]?", input_type: :player_search, template: "Should I start or sit {player} this week?" },
        { label: "Start [player] or [player]?", input_type: :two_player_select, template: "Should I start {player1} or {player2} this week?" },

        # Rankings
        { label: "QB rankings this week", input_type: :direct, template: "What are the QB rankings for this week?" },
        { label: "RB rankings this week", input_type: :direct, template: "What are the RB rankings for this week?" },
        { label: "WR rankings this week", input_type: :direct, template: "What are the WR rankings for this week?" },
        { label: "TE rankings this week", input_type: :direct, template: "What are the TE rankings for this week?" },
        { label: "K rankings this week", input_type: :direct, template: "What are the kicker rankings for this week?" },
        { label: "DEF rankings this week", input_type: :direct, template: "What are the defense rankings for this week?" },
        { label: "Flex rankings this week", input_type: :direct, template: "What are the flex rankings for this week?" },

        # Waiver & Pickups
        { label: "Best waiver pickups", input_type: :direct, template: "Who are the best waiver wire pickups this week?" },
        { label: "RB waiver targets", input_type: :direct, template: "Which running backs should I target on waivers?" },
        { label: "WR waiver targets", input_type: :direct, template: "Which wide receivers should I target on waivers?" },
        { label: "Streaming QBs", input_type: :direct, template: "Which quarterbacks are good streaming options this week?" },
        { label: "Streaming DEF", input_type: :direct, template: "Which defenses are good streaming options this week?" },
        { label: "Streaming TE", input_type: :direct, template: "Which tight ends are good streaming options this week?" },

        # Matchups
        { label: "Best matchups this week", input_type: :direct, template: "Which players have the best matchups this week?" },
        { label: "Worst matchups this week", input_type: :direct, template: "Which players have the worst matchups this week?" },
        { label: "Smash spots", input_type: :direct, template: "Who are the smash plays this week in fantasy?" },
        { label: "Fade candidates", input_type: :direct, template: "Who should I fade this week in fantasy?" },

        # Analysis
        { label: "[Player] ROS outlook", input_type: :player_search, template: "What's {player}'s rest of season outlook?" },
        { label: "Buy low candidates", input_type: :direct, template: "Who are the buy low candidates in fantasy right now?" },
        { label: "Sell high candidates", input_type: :direct, template: "Who are the sell high candidates in fantasy right now?" },
        { label: "Sleepers this week", input_type: :direct, template: "Who are the fantasy sleepers this week?" },
        { label: "Bust alerts", input_type: :direct, template: "Who are potential fantasy busts this week?" },

        # Trade
        { label: "[Player] trade value", input_type: :player_search, template: "What's {player}'s trade value right now?" },
        { label: "Is this trade fair?", input_type: :direct, template: "Can you help me evaluate a trade?" },

        # DFS
        { label: "DraftKings value plays", input_type: :direct, template: "Who are the best DraftKings value plays this week?" },
        { label: "FanDuel value plays", input_type: :direct, template: "Who are the best FanDuel value plays this week?" },
        { label: "GPP stacks", input_type: :direct, template: "What are the best GPP stacks this week?" },
        { label: "Cash game plays", input_type: :direct, template: "Who are the safest cash game plays this week?" }
      ]
    },
    {
      name: "Stats & Players",
      icon: "📈",
      questions: [
        # Individual Stats
        { label: "[Player] stats this season", input_type: :player_search, template: "What are {player}'s stats this season?" },
        { label: "[Player] stats last game", input_type: :player_search, template: "What were {player}'s stats last game?" },
        { label: "[Player] career stats", input_type: :player_search, template: "What are {player}'s career stats?" },

        # Leaders
        { label: "Passing yards leaders", input_type: :direct, template: "Who leads the NFL in passing yards?" },
        { label: "Rushing yards leaders", input_type: :direct, template: "Who leads the NFL in rushing yards?" },
        { label: "Receiving yards leaders", input_type: :direct, template: "Who leads the NFL in receiving yards?" },
        { label: "Touchdown leaders", input_type: :direct, template: "Who leads the NFL in touchdowns?" },
        { label: "Sack leaders", input_type: :direct, template: "Who leads the NFL in sacks?" },
        { label: "Interception leaders", input_type: :direct, template: "Who leads the NFL in interceptions?" },
        { label: "Fantasy points leaders", input_type: :direct, template: "Who leads the NFL in fantasy points?" },

        # Comparisons
        { label: "Compare [player] vs [player]", input_type: :two_player_select, template: "Compare {player1} vs {player2}" },

        # Rankings & Analysis
        { label: "Top 10 QBs", input_type: :direct, template: "Who are the top 10 quarterbacks this season?" },
        { label: "Top 10 RBs", input_type: :direct, template: "Who are the top 10 running backs this season?" },
        { label: "Top 10 WRs", input_type: :direct, template: "Who are the top 10 wide receivers this season?" },
        { label: "Top 10 TEs", input_type: :direct, template: "Who are the top 10 tight ends this season?" },
        { label: "Best rookies", input_type: :direct, template: "Who are the best rookies this season?" },
        { label: "Breakout players", input_type: :direct, template: "Who's having a breakout season?" },
        { label: "Most improved players", input_type: :direct, template: "Who's most improved this season?" },
        { label: "Regression candidates", input_type: :direct, template: "Who's regressing this season?" },

        # Team Stats
        { label: "[Team] stats", input_type: :team_select, template: "What are the {team}'s team stats this season?" },
        { label: "Best offense", input_type: :direct, template: "Which team has the best offense?" },
        { label: "Best defense", input_type: :direct, template: "Which team has the best defense?" },
        { label: "Worst offense", input_type: :direct, template: "Which team has the worst offense?" },
        { label: "Worst defense", input_type: :direct, template: "Which team has the worst defense?" },

        # Player Info
        { label: "What team is [player] on?", input_type: :player_search, template: "What team is {player} on?" },
        { label: "Who's the [team] starting QB?", input_type: :team_select, template: "Who's the {team}'s starting quarterback?" },
        { label: "[Team] depth chart", input_type: :team_select, template: "What's the {team}'s depth chart?" }
      ]
    }
  ]
}
```

---

## PART 4: REFERENCE DATA

### NFL Teams List
```ruby
NFL_TEAMS = [
  { key: "ARI", name: "Cardinals", full_name: "Arizona Cardinals", division: "NFC West" },
  { key: "ATL", name: "Falcons", full_name: "Atlanta Falcons", division: "NFC South" },
  { key: "BAL", name: "Ravens", full_name: "Baltimore Ravens", division: "AFC North" },
  { key: "BUF", name: "Bills", full_name: "Buffalo Bills", division: "AFC East" },
  { key: "CAR", name: "Panthers", full_name: "Carolina Panthers", division: "NFC South" },
  { key: "CHI", name: "Bears", full_name: "Chicago Bears", division: "NFC North" },
  { key: "CIN", name: "Bengals", full_name: "Cincinnati Bengals", division: "AFC North" },
  { key: "CLE", name: "Browns", full_name: "Cleveland Browns", division: "AFC North" },
  { key: "DAL", name: "Cowboys", full_name: "Dallas Cowboys", division: "NFC East" },
  { key: "DEN", name: "Broncos", full_name: "Denver Broncos", division: "AFC West" },
  { key: "DET", name: "Lions", full_name: "Detroit Lions", division: "NFC North" },
  { key: "GB", name: "Packers", full_name: "Green Bay Packers", division: "NFC North" },
  { key: "HOU", name: "Texans", full_name: "Houston Texans", division: "AFC South" },
  { key: "IND", name: "Colts", full_name: "Indianapolis Colts", division: "AFC South" },
  { key: "JAX", name: "Jaguars", full_name: "Jacksonville Jaguars", division: "AFC South" },
  { key: "KC", name: "Chiefs", full_name: "Kansas City Chiefs", division: "AFC West" },
  { key: "LAC", name: "Chargers", full_name: "Los Angeles Chargers", division: "AFC West" },
  { key: "LAR", name: "Rams", full_name: "Los Angeles Rams", division: "NFC West" },
  { key: "LV", name: "Raiders", full_name: "Las Vegas Raiders", division: "AFC West" },
  { key: "MIA", name: "Dolphins", full_name: "Miami Dolphins", division: "AFC East" },
  { key: "MIN", name: "Vikings", full_name: "Minnesota Vikings", division: "NFC North" },
  { key: "NE", name: "Patriots", full_name: "New England Patriots", division: "AFC East" },
  { key: "NO", name: "Saints", full_name: "New Orleans Saints", division: "NFC South" },
  { key: "NYG", name: "Giants", full_name: "New York Giants", division: "NFC East" },
  { key: "NYJ", name: "Jets", full_name: "New York Jets", division: "AFC East" },
  { key: "PHI", name: "Eagles", full_name: "Philadelphia Eagles", division: "NFC East" },
  { key: "PIT", name: "Steelers", full_name: "Pittsburgh Steelers", division: "AFC North" },
  { key: "SEA", name: "Seahawks", full_name: "Seattle Seahawks", division: "NFC West" },
  { key: "SF", name: "49ers", full_name: "San Francisco 49ers", division: "NFC West" },
  { key: "TB", name: "Buccaneers", full_name: "Tampa Bay Buccaneers", division: "NFC South" },
  { key: "TEN", name: "Titans", full_name: "Tennessee Titans", division: "AFC South" },
  { key: "WAS", name: "Commanders", full_name: "Washington Commanders", division: "NFC East" }
]

NFL_DIVISIONS = [
  "AFC East", "AFC North", "AFC South", "AFC West",
  "NFC East", "NFC North", "NFC South", "NFC West"
]

NFL_WEEKS = [
  "Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6",
  "Week 7", "Week 8", "Week 9", "Week 10", "Week 11", "Week 12",
  "Week 13", "Week 14", "Week 15", "Week 16", "Week 17", "Week 18",
  "Wild Card", "Divisional", "Conference Championship", "Super Bowl"
]

NFL_POSITIONS = ["QB", "RB", "WR", "TE", "K", "DEF"]
```

---

## PART 5: IMPLEMENTATION - STIMULUS CONTROLLERS

### Main Menu Controller
```javascript
// app/javascript/controllers/quick_menu_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "content", "searchInput", "searchResults"]
  static values = {
    sport: String,
    category: String,
    currentLevel: { type: String, default: "sports" }, // sports, categories, questions, input
    favoriteTeam: String,
    menuData: Object
  }

  connect() {
    this.loadMenuData()
    this.loadFavoriteTeam()
    this.selectedQuestion = null
  }

  // Toggle menu open/close
  toggle() {
    this.menuTarget.classList.toggle("hidden")
    if (!this.menuTarget.classList.contains("hidden")) {
      this.showSports()
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.reset()
  }

  // Navigation
  showSports() {
    this.currentLevelValue = "sports"
    this.render()
  }

  showCategories(event) {
    this.sportValue = event.currentTarget.dataset.sport
    this.currentLevelValue = "categories"
    this.render()
  }

  showQuestions(event) {
    this.categoryValue = event.currentTarget.dataset.category
    this.currentLevelValue = "questions"
    this.render()
  }

  back() {
    if (this.currentLevelValue === "input") {
      this.currentLevelValue = "questions"
    } else if (this.currentLevelValue === "questions") {
      this.currentLevelValue = "categories"
    } else if (this.currentLevelValue === "categories") {
      this.currentLevelValue = "sports"
    }
    this.render()
  }

  // Question Selection
  selectQuestion(event) {
    const questionIndex = event.currentTarget.dataset.questionIndex
    const category = this.getCurrentCategory()
    this.selectedQuestion = category.questions[questionIndex]

    switch (this.selectedQuestion.input_type) {
      case "direct":
        this.sendQuestion(this.selectedQuestion.template)
        break
      case "my_team":
        if (this.favoriteTeamValue) {
          const question = this.selectedQuestion.template.replace("{my_team}", this.favoriteTeamValue)
          this.sendQuestion(question)
        } else {
          this.showSetFavoritePrompt()
        }
        break
      case "team_select":
        this.currentLevelValue = "input"
        this.inputType = "team"
        this.render()
        break
      case "player_search":
        this.currentLevelValue = "input"
        this.inputType = "player"
        this.render()
        break
      case "game_select":
        this.currentLevelValue = "input"
        this.inputType = "game"
        this.loadTodaysGames()
        this.render()
        break
      case "two_player_select":
        this.currentLevelValue = "input"
        this.inputType = "two_player"
        this.playerSelectionStep = 1
        this.render()
        break
      case "week_select":
        this.currentLevelValue = "input"
        this.inputType = "week"
        this.render()
        break
      case "division_select":
        this.currentLevelValue = "input"
        this.inputType = "division"
        this.render()
        break
      case "position_select":
        this.currentLevelValue = "input"
        this.inputType = "position"
        this.render()
        break
    }
  }

  // Input Handlers
  selectTeam(event) {
    const teamName = event.currentTarget.dataset.teamName
    const question = this.selectedQuestion.template.replace("{team}", teamName)
    this.sendQuestion(question)
  }

  selectGame(event) {
    const game = event.currentTarget.dataset.game
    const question = this.selectedQuestion.template.replace("{game}", game)
    this.sendQuestion(question)
  }

  selectWeek(event) {
    const week = event.currentTarget.dataset.week
    const question = this.selectedQuestion.template.replace("{week}", week)
    this.sendQuestion(question)
  }

  selectDivision(event) {
    const division = event.currentTarget.dataset.division
    const question = this.selectedQuestion.template.replace("{division}", division)
    this.sendQuestion(question)
  }

  selectPosition(event) {
    const position = event.currentTarget.dataset.position
    const question = this.selectedQuestion.template.replace("{position}", position)
    this.sendQuestion(question)
  }

  // Player Search with Autocomplete
  searchPlayer(event) {
    const query = event.target.value.trim()
    if (query.length < 2) {
      this.searchResultsTarget.innerHTML = ""
      return
    }

    // Debounce
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      this.fetchPlayerResults(query)
    }, 200)
  }

  async fetchPlayerResults(query) {
    try {
      const response = await fetch(`/api/players/search?q=${encodeURIComponent(query)}&sport=${this.sportValue}`)
      const players = await response.json()
      this.renderPlayerResults(players)
    } catch (error) {
      console.error("Player search failed:", error)
    }
  }

  selectPlayer(event) {
    const playerName = event.currentTarget.dataset.playerName

    if (this.inputType === "two_player" && this.playerSelectionStep === 1) {
      this.selectedPlayer1 = playerName
      this.playerSelectionStep = 2
      this.searchInputTarget.value = ""
      this.searchResultsTarget.innerHTML = ""
      this.render()
    } else if (this.inputType === "two_player" && this.playerSelectionStep === 2) {
      const question = this.selectedQuestion.template
        .replace("{player1}", this.selectedPlayer1)
        .replace("{player2}", playerName)
      this.sendQuestion(question)
    } else {
      const question = this.selectedQuestion.template.replace("{player}", playerName)
      this.sendQuestion(question)
    }
  }

  // Set Favorite Team
  showSetFavoritePrompt() {
    this.currentLevelValue = "input"
    this.inputType = "set_favorite"
    this.render()
  }

  setFavoriteTeam(event) {
    const teamName = event.currentTarget.dataset.teamName
    this.favoriteTeamValue = teamName

    // Save to backend
    fetch("/api/user/favorite_team", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ team: teamName })
    })

    // Now execute the original question
    const question = this.selectedQuestion.template.replace("{my_team}", teamName)
    this.sendQuestion(question)
  }

  // Send Final Question to Chat
  sendQuestion(question) {
    const chatInput = document.querySelector("[data-chat-input]")
    const chatForm = document.querySelector("[data-chat-form]")

    if (chatInput && chatForm) {
      chatInput.value = question
      chatForm.requestSubmit()
    }

    this.close()
  }

  // Rendering
  render() {
    let html = ""

    switch (this.currentLevelValue) {
      case "sports":
        html = this.renderSports()
        break
      case "categories":
        html = this.renderCategories()
        break
      case "questions":
        html = this.renderQuestions()
        break
      case "input":
        html = this.renderInput()
        break
    }

    this.contentTarget.innerHTML = html
  }

  renderSports() {
    const sports = [
      { key: "nfl", icon: "🏈", name: "NFL" },
      { key: "nba", icon: "🏀", name: "NBA" },
      { key: "mlb", icon: "⚾", name: "MLB" },
      { key: "soccer", icon: "⚽", name: "Soccer" },
      { key: "nhl", icon: "🏒", name: "NHL" }
    ]

    return `
      <div class="menu-header">Choose Sport</div>
      <div class="menu-items">
        ${sports.map(sport => `
          <button class="menu-item" data-action="click->quick-menu#showCategories" data-sport="${sport.key}">
            <span class="menu-icon">${sport.icon}</span>
            <span class="menu-label">${sport.name}</span>
          </button>
        `).join("")}
      </div>
    `
  }

  renderCategories() {
    const sportData = this.menuDataValue[this.sportValue]
    if (!sportData) return "Sport not found"

    return `
      <button class="menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="menu-header">${sportData.icon} ${sportData.sport}</div>
      <div class="menu-items">
        ${sportData.categories.map(cat => `
          <button class="menu-item" data-action="click->quick-menu#showQuestions" data-category="${cat.name}">
            <span class="menu-icon">${cat.icon}</span>
            <span class="menu-label">${cat.name}</span>
          </button>
        `).join("")}
      </div>
    `
  }

  renderQuestions() {
    const category = this.getCurrentCategory()
    if (!category) return "Category not found"

    return `
      <button class="menu-back" data-action="click->quick-menu#back">← ${this.sportValue.toUpperCase()}</button>
      <div class="menu-header">${category.icon} ${category.name}</div>
      <div class="menu-items menu-items-scroll">
        ${category.questions.map((q, index) => `
          <button class="menu-item menu-item-question" data-action="click->quick-menu#selectQuestion" data-question-index="${index}">
            ${q.label}
          </button>
        `).join("")}
      </div>
    `
  }

  renderInput() {
    switch (this.inputType) {
      case "team":
      case "set_favorite":
        return this.renderTeamSelector()
      case "player":
        return this.renderPlayerSearch()
      case "two_player":
        return this.renderTwoPlayerSearch()
      case "game":
        return this.renderGameSelector()
      case "week":
        return this.renderWeekSelector()
      case "division":
        return this.renderDivisionSelector()
      case "position":
        return this.renderPositionSelector()
    }
  }

  renderTeamSelector() {
    const teams = this.getTeamsForSport()
    const header = this.inputType === "set_favorite" ? "Set Your Favorite Team" : "Select Team"

    return `
      <button class="menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="menu-header">${header}</div>
      <input type="text" class="menu-search" placeholder="🔍 Search teams..." data-action="input->quick-menu#filterTeams" data-quick-menu-target="teamSearch">
      <div class="menu-items menu-items-scroll" data-quick-menu-target="teamList">
        ${teams.map(team => `
          <button class="menu-item" data-action="click->quick-menu#${this.inputType === 'set_favorite' ? 'setFavoriteTeam' : 'selectTeam'}" data-team-name="${team.name}">
            ${team.full_name}
          </button>
        `).join("")}
      </div>
    `
  }

  renderPlayerSearch() {
    return `
      <button class="menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="menu-header">Search Player</div>
      <input type="text" class="menu-search" placeholder="🔍 Type player name..." data-action="input->quick-menu#searchPlayer" data-quick-menu-target="searchInput" autofocus>
      <div class="menu-items menu-items-scroll" data-quick-menu-target="searchResults"></div>
    `
  }

  renderTwoPlayerSearch() {
    const step = this.playerSelectionStep
    const header = step === 1 ? "Select First Player" : `Compare ${this.selectedPlayer1} vs...`

    return `
      <button class="menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="menu-header">${header}</div>
      <input type="text" class="menu-search" placeholder="🔍 Type player name..." data-action="input->quick-menu#searchPlayer" data-quick-menu-target="searchInput" autofocus>
      <div class="menu-items menu-items-scroll" data-quick-menu-target="searchResults"></div>
    `
  }

  renderGameSelector() {
    const games = this.todaysGames || []

    return `
      <button class="menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="menu-header">Select Game</div>
      <div class="menu-items menu-items-scroll">
        ${games.length > 0 ? games.map(game => `
          <button class="menu-item" data-action="click->quick-menu#selectGame" data-game="${game.label}">
            ${game.label}
          </button>
        `).join("") : "<div class='menu-empty'>No games today</div>"}
      </div>
    `
  }

  renderWeekSelector() {
    const weeks = this.getWeeksForSport()

    return `
      <button class="menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="menu-header">Select Week</div>
      <div class="menu-items menu-items-scroll">
        ${weeks.map(week => `
          <button class="menu-item" data-action="click->quick-menu#selectWeek" data-week="${week}">
            ${week}
          </button>
        `).join("")}
      </div>
    `
  }

  renderDivisionSelector() {
    const divisions = this.getDivisionsForSport()

    return `
      <button class="menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="menu-header">Select Division</div>
      <div class="menu-items menu-items-scroll">
        ${divisions.map(div => `
          <button class="menu-item" data-action="click->quick-menu#selectDivision" data-division="${div}">
            ${div}
          </button>
        `).join("")}
      </div>
    `
  }

  renderPositionSelector() {
    const positions = this.getPositionsForSport()

    return `
      <button class="menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="menu-header">Select Position</div>
      <div class="menu-items">
        ${positions.map(pos => `
          <button class="menu-item" data-action="click->quick-menu#selectPosition" data-position="${pos}">
            ${pos}
          </button>
        `).join("")}
      </div>
    `
  }

  renderPlayerResults(players) {
    if (players.length === 0) {
      this.searchResultsTarget.innerHTML = "<div class='menu-empty'>No players found</div>"
      return
    }

    this.searchResultsTarget.innerHTML = players.map(player => `
      <button class="menu-item" data-action="click->quick-menu#selectPlayer" data-player-name="${player.name}">
        ${player.name} <span class="menu-item-meta">${player.team} - ${player.position}</span>
      </button>
    `).join("")
  }

  filterTeams(event) {
    const query = event.target.value.toLowerCase()
    const items = this.teamListTarget.querySelectorAll(".menu-item")

    items.forEach(item => {
      const text = item.textContent.toLowerCase()
      item.style.display = text.includes(query) ? "" : "none"
    })
  }

  // Helpers
  getCurrentCategory() {
    const sportData = this.menuDataValue[this.sportValue]
    if (!sportData) return null
    return sportData.categories.find(c => c.name === this.categoryValue)
  }

  getTeamsForSport() {
    // Return teams based on current sport
    // For now, hardcoded NFL teams
    return [
      { key: "ARI", name: "Cardinals", full_name: "Arizona Cardinals" },
      { key: "ATL", name: "Falcons", full_name: "Atlanta Falcons" },
      { key: "BAL", name: "Ravens", full_name: "Baltimore Ravens" },
      { key: "BUF", name: "Bills", full_name: "Buffalo Bills" },
      { key: "CAR", name: "Panthers", full_name: "Carolina Panthers" },
      { key: "CHI", name: "Bears", full_name: "Chicago Bears" },
      { key: "CIN", name: "Bengals", full_name: "Cincinnati Bengals" },
      { key: "CLE", name: "Browns", full_name: "Cleveland Browns" },
      { key: "DAL", name: "Cowboys", full_name: "Dallas Cowboys" },
      { key: "DEN", name: "Broncos", full_name: "Denver Broncos" },
      { key: "DET", name: "Lions", full_name: "Detroit Lions" },
      { key: "GB", name: "Packers", full_name: "Green Bay Packers" },
      { key: "HOU", name: "Texans", full_name: "Houston Texans" },
      { key: "IND", name: "Colts", full_name: "Indianapolis Colts" },
      { key: "JAX", name: "Jaguars", full_name: "Jacksonville Jaguars" },
      { key: "KC", name: "Chiefs", full_name: "Kansas City Chiefs" },
      { key: "LAC", name: "Chargers", full_name: "Los Angeles Chargers" },
      { key: "LAR", name: "Rams", full_name: "Los Angeles Rams" },
      { key: "LV", name: "Raiders", full_name: "Las Vegas Raiders" },
      { key: "MIA", name: "Dolphins", full_name: "Miami Dolphins" },
      { key: "MIN", name: "Vikings", full_name: "Minnesota Vikings" },
      { key: "NE", name: "Patriots", full_name: "New England Patriots" },
      { key: "NO", name: "Saints", full_name: "New Orleans Saints" },
      { key: "NYG", name: "Giants", full_name: "New York Giants" },
      { key: "NYJ", name: "Jets", full_name: "New York Jets" },
      { key: "PHI", name: "Eagles", full_name: "Philadelphia Eagles" },
      { key: "PIT", name: "Steelers", full_name: "Pittsburgh Steelers" },
      { key: "SEA", name: "Seahawks", full_name: "Seattle Seahawks" },
      { key: "SF", name: "49ers", full_name: "San Francisco 49ers" },
      { key: "TB", name: "Buccaneers", full_name: "Tampa Bay Buccaneers" },
      { key: "TEN", name: "Titans", full_name: "Tennessee Titans" },
      { key: "WAS", name: "Commanders", full_name: "Washington Commanders" }
    ]
  }

  getWeeksForSport() {
    return [
      "Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6",
      "Week 7", "Week 8", "Week 9", "Week 10", "Week 11", "Week 12",
      "Week 13", "Week 14", "Week 15", "Week 16", "Week 17", "Week 18",
      "Wild Card", "Divisional", "Conference Championship", "Super Bowl"
    ]
  }

  getDivisionsForSport() {
    return [
      "AFC East", "AFC North", "AFC South", "AFC West",
      "NFC East", "NFC North", "NFC South", "NFC West"
    ]
  }

  getPositionsForSport() {
    return ["QB", "RB", "WR", "TE", "K", "DEF"]
  }

  async loadTodaysGames() {
    try {
      const response = await fetch(`/api/games/today?sport=${this.sportValue}`)
      this.todaysGames = await response.json()
    } catch (error) {
      this.todaysGames = []
    }
  }

  loadMenuData() {
    // In production, this would come from the server
    // For now, it's embedded in a data attribute or fetched
    this.menuDataValue = window.SPORTSBIFF_MENU_DATA || {}
  }

  loadFavoriteTeam() {
    // Load from data attribute or make API call
    this.favoriteTeamValue = this.element.dataset.favoriteTeam || ""
  }

  reset() {
    this.currentLevelValue = "sports"
    this.sportValue = ""
    this.categoryValue = ""
    this.selectedQuestion = null
    this.inputType = null
    this.playerSelectionStep = 1
    this.selectedPlayer1 = null
  }
}
```

---

## PART 6: HTML STRUCTURE

```erb
<%# app/views/shared/_quick_menu.html.erb %>

<div data-controller="quick-menu"
     data-quick-menu-favorite-team-value="<%= current_user&.favorite_team %>"
     class="quick-menu-container">

  <%# Menu Toggle Button %>
  <button class="quick-menu-toggle" data-action="click->quick-menu#toggle" aria-label="Quick Menu">
    📋
  </button>

  <%# Menu Panel %>
  <div class="quick-menu hidden" data-quick-menu-target="menu">
    <div class="quick-menu-content" data-quick-menu-target="content">
      <%# Content rendered dynamically by Stimulus %>
    </div>
  </div>
</div>

<%# Embed menu data for JavaScript %>
<script>
  window.SPORTSBIFF_MENU_DATA = <%= raw SportsbiffMenu.all_sports_data.to_json %>;
</script>
```

---

## PART 7: CSS

```scss
// app/assets/stylesheets/components/_quick_menu.scss

.quick-menu-container {
  position: relative;
}

.quick-menu-toggle {
  width: 44px;
  height: 44px;
  border-radius: 8px;
  border: 1px solid #e0e0e0;
  background: white;
  cursor: pointer;
  font-size: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;

  &:hover {
    background: #f5f5f5;
  }
}

.quick-menu {
  position: absolute;
  bottom: 100%;
  right: 0;
  margin-bottom: 8px;
  width: 280px;
  max-height: 400px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  overflow: hidden;
  z-index: 100;

  &.hidden {
    display: none;
  }
}

.quick-menu-content {
  display: flex;
  flex-direction: column;
}

.menu-header {
  padding: 12px 16px;
  font-weight: 600;
  font-size: 14px;
  color: #333;
  border-bottom: 1px solid #eee;
}

.menu-back {
  padding: 10px 16px;
  background: #f8f8f8;
  border: none;
  text-align: left;
  cursor: pointer;
  font-size: 13px;
  color: #666;

  &:hover {
    background: #f0f0f0;
  }
}

.menu-items {
  display: flex;
  flex-direction: column;
}

.menu-items-scroll {
  max-height: 280px;
  overflow-y: auto;
}

.menu-item {
  padding: 12px 16px;
  border: none;
  background: white;
  text-align: left;
  cursor: pointer;
  font-size: 14px;
  color: #333;
  display: flex;
  align-items: center;
  gap: 10px;
  transition: background 0.15s;

  &:hover {
    background: #f5f5f5;
  }

  &:not(:last-child) {
    border-bottom: 1px solid #f0f0f0;
  }
}

.menu-item-question {
  font-size: 13px;
}

.menu-icon {
  font-size: 18px;
}

.menu-label {
  flex: 1;
}

.menu-item-meta {
  font-size: 11px;
  color: #999;
  margin-left: auto;
}

.menu-search {
  margin: 8px 12px;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  outline: none;

  &:focus {
    border-color: #007bff;
  }
}

.menu-empty {
  padding: 20px;
  text-align: center;
  color: #999;
  font-size: 13px;
}
```

---

## PART 8: RAILS BACKEND

### Menu Data Service
```ruby
# app/services/sportsbiff_menu.rb

class SportsbiffMenu
  class << self
    def all_sports_data
      {
        nfl: nfl_data,
        nba: nba_data,
        mlb: mlb_data,
        soccer: soccer_data,
        nhl: nhl_data
      }
    end

    def nfl_data
      # Return the NFL_MENU hash from Part 3
      NFL_MENU
    end

    def nba_data
      # Similar structure for NBA
      { sport: "NBA", icon: "🏀", categories: [] }
    end

    # ... other sports
  end
end
```

### Player Search API
```ruby
# app/controllers/api/players_controller.rb

module Api
  class PlayersController < ApplicationController
    def search
      sport = params[:sport]
      query = params[:q]

      players = PlayerSearchService.search(sport: sport, query: query, limit: 10)

      render json: players.map { |p| { name: p.name, team: p.team, position: p.position } }
    end
  end
end
```

### Favorite Team API
```ruby
# app/controllers/api/users_controller.rb

module Api
  class UsersController < ApplicationController
    def update_favorite_team
      current_user.update(favorite_team: params[:team])
      render json: { success: true }
    end
  end
end
```

### Today's Games API
```ruby
# app/controllers/api/games_controller.rb

module Api
  class GamesController < ApplicationController
    def today
      sport = params[:sport]
      games = GamesService.today(sport: sport)

      render json: games.map { |g| { label: "#{g.away_team} @ #{g.home_team}", id: g.id } }
    end
  end
end
```

### Routes
```ruby
# config/routes.rb

namespace :api do
  get "players/search", to: "players#search"
  post "user/favorite_team", to: "users#update_favorite_team"
  get "games/today", to: "games#today"
end
```

---

## PART 9: INTEGRATION WITH CHAT

The menu needs to integrate with your existing chat form. Make sure your chat form has these data attributes:

```erb
<%# Your chat form %>
<%= form_with url: chat_path, method: :post, data: { chat_form: true } do |f| %>
  <%= f.text_field :message, data: { chat_input: true }, placeholder: "Ask anything..." %>
  <%= f.submit "Send" %>
<% end %>

<%# Quick menu button next to input %>
<%= render "shared/quick_menu" %>
```

The Stimulus controller finds these elements:
```javascript
const chatInput = document.querySelector("[data-chat-input]")
const chatForm = document.querySelector("[data-chat-form]")
```

And submits programmatically:
```javascript
chatInput.value = question
chatForm.requestSubmit()
```

---

## PART 10: SUMMARY FOR CLAUDE CODE

**What to build:**
1. A Stimulus controller (`quick_menu_controller.js`) that handles all menu logic
2. Menu data stored in a Ruby service class
3. HTML partial for the menu structure
4. CSS for styling
5. Three simple API endpoints (player search, favorite team, today's games)

**Key behaviors:**
- Menu opens/closes without page refresh
- Navigation between levels is instant (no server calls)
- Team/player selection happens in-menu
- Final question auto-submits to chat
- Favorite team is persisted and used for "my team" questions

**Don't:**
- Use React/Vue
- Make server calls for navigation
- Refresh the page
- Overcomplicate the data structure

**File structure:**
```
app/
├── javascript/
│   └── controllers/
│       └── quick_menu_controller.js
├── views/
│   └── shared/
│       └── _quick_menu.html.erb
├── assets/
│   └── stylesheets/
│       └── components/
│           └── _quick_menu.scss
├── services/
│   └── sportsbiff_menu.rb
└── controllers/
    └── api/
        ├── players_controller.rb
        ├── users_controller.rb
        └── games_controller.rb
```

This is a straightforward Stimulus.js menu. Don't overthink it.
