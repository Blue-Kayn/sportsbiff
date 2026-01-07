class SportsbiffMenu
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
  ].freeze

  NFL_DIVISIONS = [
    "AFC East", "AFC North", "AFC South", "AFC West",
    "NFC East", "NFC North", "NFC South", "NFC West"
  ].freeze

  NFL_WEEKS = [
    "Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6",
    "Week 7", "Week 8", "Week 9", "Week 10", "Week 11", "Week 12",
    "Week 13", "Week 14", "Week 15", "Week 16", "Week 17", "Week 18",
    "Wild Card", "Divisional", "Conference Championship", "Super Bowl"
  ].freeze

  NFL_POSITIONS = %w[QB RB WR TE K DEF].freeze

  NFL_MENU = {
    sport: "NFL",
    icon: "🏈",
    enabled: true,
    categories: [
      {
        name: "Games & Scores",
        icon: "📊",
        questions: [
          { label: "What's the score right now?", input_type: "game_select", template: "What's the score of the {game} game?" },
          { label: "Who won yesterday?", input_type: "direct", template: "Who won yesterday's NFL games?" },
          { label: "How did my teams do?", input_type: "my_teams", template: "How did the {my_teams} do?" },
          { label: "Week results", input_type: "week_select", template: "What were the Week {week} NFL results?" },
          { label: "When do the [team] play next?", input_type: "team_select", template: "When do the {team} play next?" },
          { label: "What channel is the [team] game on?", input_type: "team_select", template: "What channel is the {team} game on?" },
          { label: "Any upsets this week?", input_type: "direct", template: "Were there any upsets in the NFL this week?" },
          { label: "Biggest blowout this week?", input_type: "direct", template: "What was the biggest blowout in the NFL this week?" },
          { label: "Any overtime games?", input_type: "direct", template: "Were there any overtime games in the NFL this week?" },
          { label: "Thursday Night Football result", input_type: "direct", template: "What was the Thursday Night Football result?" },
          { label: "Sunday Night Football result", input_type: "direct", template: "What was the Sunday Night Football result?" },
          { label: "Monday Night Football result", input_type: "direct", template: "What was the Monday Night Football result?" }
        ]
      },
      {
        name: "Standings & Playoffs",
        icon: "🏆",
        questions: [
          { label: "Is [team] in the playoffs?", input_type: "team_select", template: "Are the {team} in the playoffs?" },
          { label: "Are my teams in the playoffs?", input_type: "my_teams", template: "Are the {my_teams} in the playoffs?" },
          { label: "Who won the [division]?", input_type: "division_select", template: "Who won the {division}?" },
          { label: "What's the playoff bracket?", input_type: "direct", template: "What's the current NFL playoff bracket?" },
          { label: "Who has the best record?", input_type: "direct", template: "Which NFL team has the best record?" },
          { label: "Who has the worst record?", input_type: "direct", template: "Which NFL team has the worst record?" },
          { label: "Wild card race update", input_type: "direct", template: "What's the NFL wild card race looking like?" },
          { label: "NFC standings", input_type: "direct", template: "What are the current NFC standings?" },
          { label: "AFC standings", input_type: "direct", template: "What are the current AFC standings?" },
          { label: "[Team] record", input_type: "team_select", template: "What is the {team}'s record this season?" },
          { label: "My teams' records", input_type: "my_teams", template: "What are the {my_teams}'s records this season?" },
          { label: "Which teams have clinched?", input_type: "direct", template: "Which NFL teams have clinched playoff spots?" },
          { label: "Which teams are eliminated?", input_type: "direct", template: "Which NFL teams are eliminated from playoff contention?" },
          { label: "Who gets the #1 pick?", input_type: "direct", template: "Which team is projected to get the #1 draft pick?" }
        ]
      },
      {
        name: "Injuries & News",
        icon: "🏥",
        questions: [
          { label: "Is [player] playing this week?", input_type: "player_search", template: "Is {player} playing this week?" },
          { label: "Who's out for [team]?", input_type: "team_select", template: "Who's out for the {team} this week?" },
          { label: "My teams' injury reports", input_type: "my_teams", template: "What are the {my_teams}'s injury reports?" },
          { label: "Full injury report", input_type: "direct", template: "What's the full NFL injury report for this week?" },
          { label: "Who's questionable?", input_type: "direct", template: "Which NFL players are listed as questionable this week?" },
          { label: "Latest NFL news", input_type: "direct", template: "What's the latest NFL news?" },
          { label: "[Team] news", input_type: "team_select", template: "What's the latest news on the {team}?" },
          { label: "[Player] news", input_type: "player_search", template: "What's the latest news on {player}?" },
          { label: "Any trades today?", input_type: "direct", template: "Were there any NFL trades today?" },
          { label: "Recent signings", input_type: "direct", template: "What are the recent NFL free agent signings?" },
          { label: "Who got cut?", input_type: "direct", template: "Which players were cut or released recently?" },
          { label: "Coach firings/hirings", input_type: "direct", template: "Any recent NFL coaching changes?" }
        ]
      },
      {
        name: "Betting",
        icon: "💰",
        questions: [
          # Current Lines
          { label: "What's the spread on [game]?", input_type: "game_select", template: "What's the spread on the {game} game?" },
          { label: "What's the over/under?", input_type: "game_select", template: "What's the over/under for the {game} game?" },
          { label: "Moneyline odds", input_type: "game_select", template: "What are the moneyline odds for {game}?" },
          { label: "All Week [X] lines", input_type: "week_select", template: "What are all the Week {week} NFL betting lines?" },
          # Results
          { label: "Did [team] cover?", input_type: "team_select", template: "Did the {team} cover the spread?" },
          { label: "Did my teams cover?", input_type: "my_teams", template: "Did the {my_teams} cover the spread?" },
          { label: "Did the over hit?", input_type: "game_select", template: "Did the over hit in the {game} game?" },
          { label: "Which underdogs covered?", input_type: "direct", template: "Which underdogs covered this week?" },
          { label: "Which favorites covered?", input_type: "direct", template: "Which favorites covered this week?" },
          # Line Movement
          { label: "Line movement on [game]", input_type: "game_select", template: "What's the line movement on {game}?" },
          { label: "Biggest line moves this week", input_type: "direct", template: "What are the biggest line moves this week?" },
          # Analysis & Picks
          { label: "Best bets this week", input_type: "direct", template: "What are the best NFL bets this week?" },
          { label: "Expert picks this week", input_type: "direct", template: "What are the expert picks for NFL this week?" },
          { label: "Public betting percentages", input_type: "direct", template: "What are the public betting percentages for NFL this week?" },
          # Props
          { label: "[Player] prop odds", input_type: "player_search", template: "What are the prop odds for {player} this week?" },
          { label: "[Player] prop hit rate", input_type: "player_search", template: "What's {player}'s prop hit rate this season?" },
          { label: "Anytime TD scorer odds", input_type: "game_select", template: "What are the anytime touchdown scorer odds for {game}?" },
          # Trends
          { label: "[Team] ATS record", input_type: "team_select", template: "What's the {team}'s record against the spread this season?" },
          { label: "[Team] over/under record", input_type: "team_select", template: "What's the {team}'s over/under record this season?" },
          { label: "Home underdogs this week", input_type: "direct", template: "Which home underdogs should I look at this week?" },
          { label: "Road favorites this week", input_type: "direct", template: "Which road favorites should I look at this week?" },
          # Futures
          { label: "Super Bowl odds", input_type: "direct", template: "What are the current Super Bowl odds?" },
          { label: "MVP odds", input_type: "direct", template: "What are the current NFL MVP odds?" },
          { label: "[Team] to win Super Bowl", input_type: "team_select", template: "What are the {team}'s Super Bowl odds?" }
        ]
      },
      {
        name: "Fantasy",
        icon: "🎮",
        questions: [
          # Start/Sit
          { label: "Start or sit [player]?", input_type: "player_search", template: "Should I start or sit {player} this week?" },
          { label: "Start [player] or [player]?", input_type: "two_player_select", template: "Should I start {player1} or {player2} this week?" },
          # Rankings
          { label: "QB rankings this week", input_type: "direct", template: "What are the QB rankings for this week?" },
          { label: "RB rankings this week", input_type: "direct", template: "What are the RB rankings for this week?" },
          { label: "WR rankings this week", input_type: "direct", template: "What are the WR rankings for this week?" },
          { label: "TE rankings this week", input_type: "direct", template: "What are the TE rankings for this week?" },
          { label: "K rankings this week", input_type: "direct", template: "What are the kicker rankings for this week?" },
          { label: "DEF rankings this week", input_type: "direct", template: "What are the defense rankings for this week?" },
          { label: "Flex rankings this week", input_type: "direct", template: "What are the flex rankings for this week?" },
          # Waiver & Pickups
          { label: "Best waiver pickups", input_type: "direct", template: "Who are the best waiver wire pickups this week?" },
          { label: "RB waiver targets", input_type: "direct", template: "Which running backs should I target on waivers?" },
          { label: "WR waiver targets", input_type: "direct", template: "Which wide receivers should I target on waivers?" },
          { label: "Streaming QBs", input_type: "direct", template: "Which quarterbacks are good streaming options this week?" },
          { label: "Streaming DEF", input_type: "direct", template: "Which defenses are good streaming options this week?" },
          { label: "Streaming TE", input_type: "direct", template: "Which tight ends are good streaming options this week?" },
          # Matchups
          { label: "Best matchups this week", input_type: "direct", template: "Which players have the best matchups this week?" },
          { label: "Worst matchups this week", input_type: "direct", template: "Which players have the worst matchups this week?" },
          { label: "Smash spots", input_type: "direct", template: "Who are the smash plays this week in fantasy?" },
          { label: "Fade candidates", input_type: "direct", template: "Who should I fade this week in fantasy?" },
          # Analysis
          { label: "[Player] ROS outlook", input_type: "player_search", template: "What's {player}'s rest of season outlook?" },
          { label: "Buy low candidates", input_type: "direct", template: "Who are the buy low candidates in fantasy right now?" },
          { label: "Sell high candidates", input_type: "direct", template: "Who are the sell high candidates in fantasy right now?" },
          { label: "Sleepers this week", input_type: "direct", template: "Who are the fantasy sleepers this week?" },
          { label: "Bust alerts", input_type: "direct", template: "Who are potential fantasy busts this week?" },
          # Trade
          { label: "[Player] trade value", input_type: "player_search", template: "What's {player}'s trade value right now?" },
          { label: "Is this trade fair?", input_type: "direct", template: "Can you help me evaluate a trade?" },
          # DFS
          { label: "DraftKings value plays", input_type: "direct", template: "Who are the best DraftKings value plays this week?" },
          { label: "FanDuel value plays", input_type: "direct", template: "Who are the best FanDuel value plays this week?" },
          { label: "GPP stacks", input_type: "direct", template: "What are the best GPP stacks this week?" },
          { label: "Cash game plays", input_type: "direct", template: "Who are the safest cash game plays this week?" }
        ]
      },
      {
        name: "Stats & Players",
        icon: "📈",
        questions: [
          # Individual Stats
          { label: "[Player] stats this season", input_type: "player_search", template: "What are {player}'s stats this season?" },
          { label: "[Player] stats last game", input_type: "player_search", template: "What were {player}'s stats last game?" },
          { label: "[Player] career stats", input_type: "player_search", template: "What are {player}'s career stats?" },
          # Leaders
          { label: "Passing yards leaders", input_type: "direct", template: "Who leads the NFL in passing yards?" },
          { label: "Rushing yards leaders", input_type: "direct", template: "Who leads the NFL in rushing yards?" },
          { label: "Receiving yards leaders", input_type: "direct", template: "Who leads the NFL in receiving yards?" },
          { label: "Touchdown leaders", input_type: "direct", template: "Who leads the NFL in touchdowns?" },
          { label: "Sack leaders", input_type: "direct", template: "Who leads the NFL in sacks?" },
          { label: "Interception leaders", input_type: "direct", template: "Who leads the NFL in interceptions?" },
          { label: "Fantasy points leaders", input_type: "direct", template: "Who leads the NFL in fantasy points?" },
          # Comparisons
          { label: "Compare [player] vs [player]", input_type: "two_player_select", template: "Compare {player1} vs {player2}" },
          # Rankings & Analysis
          { label: "Top 10 QBs", input_type: "direct", template: "Who are the top 10 quarterbacks this season?" },
          { label: "Top 10 RBs", input_type: "direct", template: "Who are the top 10 running backs this season?" },
          { label: "Top 10 WRs", input_type: "direct", template: "Who are the top 10 wide receivers this season?" },
          { label: "Top 10 TEs", input_type: "direct", template: "Who are the top 10 tight ends this season?" },
          { label: "Best rookies", input_type: "direct", template: "Who are the best rookies this season?" },
          { label: "Breakout players", input_type: "direct", template: "Who's having a breakout season?" },
          { label: "Most improved players", input_type: "direct", template: "Who's most improved this season?" },
          { label: "Regression candidates", input_type: "direct", template: "Who's regressing this season?" },
          # Team Stats
          { label: "[Team] stats", input_type: "team_select", template: "What are the {team}'s team stats this season?" },
          { label: "Best offense", input_type: "direct", template: "Which team has the best offense?" },
          { label: "Best defense", input_type: "direct", template: "Which team has the best defense?" },
          { label: "Worst offense", input_type: "direct", template: "Which team has the worst offense?" },
          { label: "Worst defense", input_type: "direct", template: "Which team has the worst defense?" },
          # Player Info
          { label: "What team is [player] on?", input_type: "player_search", template: "What team is {player} on?" },
          { label: "Who's the [team] starting QB?", input_type: "team_select", template: "Who's the {team}'s starting quarterback?" },
          { label: "[Team] depth chart", input_type: "team_select", template: "What's the {team}'s depth chart?" }
        ]
      }
    ]
  }.freeze

  # Placeholder menus for other sports (coming soon)
  NBA_MENU = {
    sport: "NBA",
    icon: "🏀",
    enabled: false,
    categories: []
  }.freeze

  MLB_MENU = {
    sport: "MLB",
    icon: "⚾",
    enabled: false,
    categories: []
  }.freeze

  SOCCER_MENU = {
    sport: "Soccer",
    icon: "⚽",
    enabled: false,
    categories: []
  }.freeze

  NHL_MENU = {
    sport: "NHL",
    icon: "🏒",
    enabled: false,
    categories: []
  }.freeze

  class << self
    def all_sports_data
      {
        nfl: NFL_MENU,
        nba: NBA_MENU,
        mlb: MLB_MENU,
        soccer: SOCCER_MENU,
        nhl: NHL_MENU
      }
    end

    def teams_for_sport(sport)
      case sport.to_s.downcase
      when "nfl"
        NFL_TEAMS
      else
        []
      end
    end

    def divisions_for_sport(sport)
      case sport.to_s.downcase
      when "nfl"
        NFL_DIVISIONS
      else
        []
      end
    end

    def weeks_for_sport(sport)
      case sport.to_s.downcase
      when "nfl"
        NFL_WEEKS
      else
        []
      end
    end

    def positions_for_sport(sport)
      case sport.to_s.downcase
      when "nfl"
        NFL_POSITIONS
      else
        []
      end
    end

    def menu_for_sport(sport)
      case sport.to_s.downcase
      when "nfl"
        NFL_MENU
      when "nba"
        NBA_MENU
      when "mlb"
        MLB_MENU
      when "soccer"
        SOCCER_MENU
      when "nhl"
        NHL_MENU
      else
        nil
      end
    end
  end
end
