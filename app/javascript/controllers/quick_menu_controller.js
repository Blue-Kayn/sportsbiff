import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "content", "searchInput", "searchResults", "teamList", "toggleBtn"]
  static values = {
    sport: String,
    category: String,
    currentLevel: { type: String, default: "sports" },
    favoriteTeams: { type: Array, default: [] }
  }

  connect() {
    this.loadMenuData()
    this.loadRosterData()
    this.selectedQuestion = null
    this.inputType = null
    this.playerSelectionStep = 1
    this.selectedPlayer1 = null
    this.selectedTeamForPlayer = null
    this.todaysGames = []
    this.teamPlayers = []

    // Close menu when clicking outside
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target) && this.hasMenuTarget && !this.menuTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
    if (!this.menuTarget.classList.contains("hidden")) {
      this.showSports()
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.reset()
  }

  showSports() {
    this.currentLevelValue = "sports"
    this.render()
  }

  showCategories(event) {
    event.stopPropagation()
    this.sportValue = event.currentTarget.dataset.sport
    this.currentLevelValue = "categories"
    this.render()
  }

  showQuestions(event) {
    event.stopPropagation()
    this.categoryValue = event.currentTarget.dataset.category
    this.currentLevelValue = "questions"
    this.render()
  }

  back(event) {
    event.stopPropagation()
    if (this.currentLevelValue === "input") {
      this.currentLevelValue = "questions"
    } else if (this.currentLevelValue === "questions") {
      this.currentLevelValue = "categories"
    } else if (this.currentLevelValue === "categories") {
      this.currentLevelValue = "sports"
    }
    this.render()
  }

  selectQuestion(event) {
    event.stopPropagation()
    const questionIndex = parseInt(event.currentTarget.dataset.questionIndex)
    const category = this.getCurrentCategory()
    this.selectedQuestion = category.questions[questionIndex]

    switch (this.selectedQuestion.input_type) {
      case "direct":
        this.sendQuestion(this.selectedQuestion.template)
        break
      case "my_teams":
        if (this.favoriteTeamsValue && this.favoriteTeamsValue.length > 0) {
          const teamsText = this.formatTeamsList(this.favoriteTeamsValue)
          const question = this.selectedQuestion.template.replace("{my_teams}", teamsText)
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
        this.inputType = "player_team_select"
        this.selectedTeamForPlayer = null
        this.render()
        break
      case "game_select":
        this.currentLevelValue = "input"
        this.inputType = "game"
        this.loadTodaysGames()
        break
      case "two_player_select":
        this.currentLevelValue = "input"
        this.inputType = "two_player_team_select"
        this.playerSelectionStep = 1
        this.selectedTeamForPlayer = null
        this.selectedPlayer1 = null
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

  selectTeam(event) {
    event.stopPropagation()
    const teamName = event.currentTarget.dataset.teamName
    const question = this.selectedQuestion.template.replace("{team}", teamName)
    this.sendQuestion(question)
  }

  selectTeamForPlayer(event) {
    event.stopPropagation()
    const teamKey = event.currentTarget.dataset.teamKey
    const teamName = event.currentTarget.dataset.teamName
    this.selectedTeamForPlayer = { key: teamKey, name: teamName }

    // Load players for this team and show player list
    this.loadPlayersForTeam(teamKey)
  }

  selectGame(event) {
    event.stopPropagation()
    const game = event.currentTarget.dataset.game
    const question = this.selectedQuestion.template.replace("{game}", game)
    this.sendQuestion(question)
  }

  selectWeek(event) {
    event.stopPropagation()
    const week = event.currentTarget.dataset.week
    const question = this.selectedQuestion.template.replace("{week}", week)
    this.sendQuestion(question)
  }

  selectDivision(event) {
    event.stopPropagation()
    const division = event.currentTarget.dataset.division
    const question = this.selectedQuestion.template.replace("{division}", division)
    this.sendQuestion(question)
  }

  selectPosition(event) {
    event.stopPropagation()
    const position = event.currentTarget.dataset.position
    const question = this.selectedQuestion.template.replace("{position}", position)
    this.sendQuestion(question)
  }

  searchPlayer(event) {
    const query = event.target.value.trim()
    if (query.length < 2) {
      if (this.hasSearchResultsTarget) {
        this.searchResultsTarget.innerHTML = ""
      }
      return
    }

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
      if (this.hasSearchResultsTarget) {
        this.searchResultsTarget.innerHTML = "<div class='quick-menu-empty'>Search failed</div>"
      }
    }
  }

  selectPlayer(event) {
    event.stopPropagation()
    const playerName = event.currentTarget.dataset.playerName
    const question = this.selectedQuestion.template.replace("{player}", playerName)
    this.sendQuestion(question)
  }

  selectPlayerForComparison(event) {
    event.stopPropagation()
    const playerName = event.currentTarget.dataset.playerName

    if (this.playerSelectionStep === 1) {
      // First player selected, go back to team select for second player
      this.selectedPlayer1 = playerName
      this.playerSelectionStep = 2
      this.inputType = "two_player_team_select"
      this.selectedTeamForPlayer = null
      this.teamPlayers = []
      this.render()
    } else {
      // Second player selected, send the question
      const question = this.selectedQuestion.template
        .replace("{player1}", this.selectedPlayer1)
        .replace("{player2}", playerName)
      this.sendQuestion(question)
    }
  }

  showSetFavoritePrompt() {
    this.currentLevelValue = "input"
    this.inputType = "set_favorite"
    this.render()
  }

  setFavoriteTeam(event) {
    event.stopPropagation()
    const teamName = event.currentTarget.dataset.teamName
    this.favoriteTeamsValue = [teamName]

    fetch("/api/user/favorite_team", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ team: teamName })
    })

    const question = this.selectedQuestion.template.replace("{my_teams}", teamName)
    this.sendQuestion(question)
  }

  formatTeamsList(teams) {
    if (!teams || teams.length === 0) return ""
    if (teams.length === 1) return teams[0]
    if (teams.length === 2) return `${teams[0]} and ${teams[1]}`
    // For 3+ teams: "Team1, Team2, and Team3"
    const lastTeam = teams[teams.length - 1]
    const otherTeams = teams.slice(0, -1).join(", ")
    return `${otherTeams}, and ${lastTeam}`
  }

  sendQuestion(question) {
    const chatInput = document.querySelector("[data-chat-input]")
    const chatForm = document.querySelector("[data-chat-form]")

    if (chatInput && chatForm) {
      chatInput.value = question
      chatForm.requestSubmit()
      // Clear the input after submission
      chatInput.value = ""
    }

    this.close()
  }

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
      { key: "nba", icon: "🏀", name: "NBA", disabled: true },
      { key: "mlb", icon: "⚾", name: "MLB", disabled: true },
      { key: "soccer", icon: "⚽", name: "Soccer", disabled: true },
      { key: "nhl", icon: "🏒", name: "NHL", disabled: true }
    ]

    return `
      <div class="quick-menu-header">Choose Sport</div>
      <div class="quick-menu-items">
        ${sports.map(sport => `
          <button class="quick-menu-item ${sport.disabled ? 'quick-menu-item-disabled' : ''}"
                  data-action="click->quick-menu#showCategories"
                  data-sport="${sport.key}"
                  ${sport.disabled ? 'disabled' : ''}>
            <span class="quick-menu-icon">${sport.icon}</span>
            <span class="quick-menu-label">${sport.name}</span>
            ${sport.disabled ? '<span class="quick-menu-badge">Soon</span>' : ''}
          </button>
        `).join("")}
      </div>
    `
  }

  renderCategories() {
    const sportData = this.menuData[this.sportValue]
    if (!sportData) return "<div class='quick-menu-empty'>Sport not found</div>"

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="quick-menu-header">${sportData.icon} ${sportData.sport}</div>
      <div class="quick-menu-items">
        ${sportData.categories.map(cat => `
          <button class="quick-menu-item" data-action="click->quick-menu#showQuestions" data-category="${cat.name}">
            <span class="quick-menu-icon">${cat.icon}</span>
            <span class="quick-menu-label">${cat.name}</span>
          </button>
        `).join("")}
      </div>
    `
  }

  renderQuestions() {
    const category = this.getCurrentCategory()
    if (!category) return "<div class='quick-menu-empty'>Category not found</div>"

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← ${this.sportValue.toUpperCase()}</button>
      <div class="quick-menu-header">${category.icon} ${category.name}</div>
      <div class="quick-menu-items quick-menu-items-scroll">
        ${category.questions.map((q, index) => `
          <button class="quick-menu-item quick-menu-item-question" data-action="click->quick-menu#selectQuestion" data-question-index="${index}">
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
      case "player_team_select":
        return this.renderTeamSelectorForPlayer()
      case "player_list":
        return this.renderPlayerList()
      case "two_player_team_select":
        return this.renderTeamSelectorForTwoPlayer()
      case "two_player_list":
        return this.renderTwoPlayerList()
      case "game":
        return this.renderGameSelector()
      case "week":
        return this.renderWeekSelector()
      case "division":
        return this.renderDivisionSelector()
      case "position":
        return this.renderPositionSelector()
      default:
        return "<div class='quick-menu-empty'>Unknown input type</div>"
    }
  }

  renderTeamSelector() {
    const teams = this.getTeamsForSport()
    const header = this.inputType === "set_favorite" ? "Set Your Favorite Team" : "Select Team"

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="quick-menu-header">${header}</div>
      <input type="text" class="quick-menu-search" placeholder="Search teams..." data-action="input->quick-menu#filterTeams">
      <div class="quick-menu-items quick-menu-items-scroll" data-quick-menu-target="teamList">
        ${teams.map(team => `
          <button class="quick-menu-item" data-action="click->quick-menu#${this.inputType === 'set_favorite' ? 'setFavoriteTeam' : 'selectTeam'}" data-team-name="${team.name}">
            ${team.full_name}
          </button>
        `).join("")}
      </div>
    `
  }

  renderTeamSelectorForPlayer() {
    const teams = this.getTeamsForSport()

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="quick-menu-header">Select Team</div>
      <input type="text" class="quick-menu-search" placeholder="Search teams..." data-action="input->quick-menu#filterTeams">
      <div class="quick-menu-items quick-menu-items-scroll" data-quick-menu-target="teamList">
        ${teams.map(team => `
          <button class="quick-menu-item" data-action="click->quick-menu#selectTeamForPlayer" data-team-key="${team.key}" data-team-name="${team.name}">
            ${team.full_name}
          </button>
        `).join("")}
      </div>
    `
  }

  renderPlayerList() {
    const teamName = this.selectedTeamForPlayer?.name || "Team"
    const players = this.teamPlayers || []

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#backToTeamSelect">← Teams</button>
      <div class="quick-menu-header">${teamName} Players</div>
      <div class="quick-menu-items quick-menu-items-scroll">
        ${players.length > 0 ? players.map(player => `
          <button class="quick-menu-item" data-action="click->quick-menu#selectPlayer" data-player-name="${player.name}">
            ${player.name} <span class="quick-menu-item-meta">${player.position}</span>
          </button>
        `).join("") : "<div class='quick-menu-empty'>No players found for this team</div>"}
      </div>
    `
  }

  renderTeamSelectorForTwoPlayer() {
    const teams = this.getTeamsForSport()
    const header = this.playerSelectionStep === 1 ? "Select Team (Player 1)" : `Select Team for Player 2`

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="quick-menu-header">${header}</div>
      ${this.playerSelectionStep === 2 ? `<div class="quick-menu-subheader">Comparing: ${this.selectedPlayer1}</div>` : ''}
      <input type="text" class="quick-menu-search" placeholder="Search teams..." data-action="input->quick-menu#filterTeams">
      <div class="quick-menu-items quick-menu-items-scroll" data-quick-menu-target="teamList">
        ${teams.map(team => `
          <button class="quick-menu-item" data-action="click->quick-menu#selectTeamForPlayer" data-team-key="${team.key}" data-team-name="${team.name}">
            ${team.full_name}
          </button>
        `).join("")}
      </div>
    `
  }

  renderTwoPlayerList() {
    const teamName = this.selectedTeamForPlayer?.name || "Team"
    const players = this.teamPlayers || []
    const header = this.playerSelectionStep === 1 ? `${teamName} - Player 1` : `${teamName} - Player 2`

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#backToTeamSelectTwoPlayer">← Teams</button>
      <div class="quick-menu-header">${header}</div>
      ${this.playerSelectionStep === 2 ? `<div class="quick-menu-subheader">Comparing: ${this.selectedPlayer1}</div>` : ''}
      <div class="quick-menu-items quick-menu-items-scroll">
        ${players.length > 0 ? players.map(player => `
          <button class="quick-menu-item" data-action="click->quick-menu#selectPlayerForComparison" data-player-name="${player.name}">
            ${player.name} <span class="quick-menu-item-meta">${player.position}</span>
          </button>
        `).join("") : "<div class='quick-menu-empty'>No players found for this team</div>"}
      </div>
    `
  }

  backToTeamSelect(event) {
    event.stopPropagation()
    this.inputType = "player_team_select"
    this.selectedTeamForPlayer = null
    this.render()
  }

  backToTeamSelectTwoPlayer(event) {
    event.stopPropagation()
    this.inputType = "two_player_team_select"
    this.selectedTeamForPlayer = null
    this.render()
  }

  renderGameSelector() {
    const games = this.todaysGames || []

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="quick-menu-header">Select Game</div>
      <div class="quick-menu-items quick-menu-items-scroll">
        ${games.length > 0 ? games.map(game => `
          <button class="quick-menu-item" data-action="click->quick-menu#selectGame" data-game="${game.display}">
            ${game.display}
          </button>
        `).join("") : "<div class='quick-menu-empty'>No games found for today</div>"}
      </div>
    `
  }

  renderWeekSelector() {
    const weeks = this.getWeeksForSport()

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="quick-menu-header">Select Week</div>
      <div class="quick-menu-items quick-menu-items-scroll">
        ${weeks.map(week => `
          <button class="quick-menu-item" data-action="click->quick-menu#selectWeek" data-week="${week}">
            ${week}
          </button>
        `).join("")}
      </div>
    `
  }

  renderDivisionSelector() {
    const divisions = this.getDivisionsForSport()

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="quick-menu-header">Select Division</div>
      <div class="quick-menu-items quick-menu-items-scroll">
        ${divisions.map(div => `
          <button class="quick-menu-item" data-action="click->quick-menu#selectDivision" data-division="${div}">
            ${div}
          </button>
        `).join("")}
      </div>
    `
  }

  renderPositionSelector() {
    const positions = this.getPositionsForSport()

    return `
      <button class="quick-menu-back" data-action="click->quick-menu#back">← Back</button>
      <div class="quick-menu-header">Select Position</div>
      <div class="quick-menu-items">
        ${positions.map(pos => `
          <button class="quick-menu-item" data-action="click->quick-menu#selectPosition" data-position="${pos}">
            ${pos}
          </button>
        `).join("")}
      </div>
    `
  }

  renderPlayerResults(players) {
    if (!this.hasSearchResultsTarget) return

    if (players.length === 0) {
      this.searchResultsTarget.innerHTML = "<div class='quick-menu-empty'>No players found</div>"
      return
    }

    this.searchResultsTarget.innerHTML = players.map(player => `
      <button class="quick-menu-item" data-action="click->quick-menu#selectPlayer" data-player-name="${player.name}">
        ${player.name} <span class="quick-menu-item-meta">${player.team} - ${player.position}</span>
      </button>
    `).join("")
  }

  filterTeams(event) {
    const query = event.target.value.toLowerCase()
    if (!this.hasTeamListTarget) return

    const items = this.teamListTarget.querySelectorAll(".quick-menu-item")
    items.forEach(item => {
      const text = item.textContent.toLowerCase()
      item.style.display = text.includes(query) ? "" : "none"
    })
  }

  getCurrentCategory() {
    const sportData = this.menuData[this.sportValue]
    if (!sportData) return null
    return sportData.categories.find(c => c.name === this.categoryValue)
  }

  getTeamsForSport() {
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
      this.render()
    } catch (error) {
      console.error("Failed to load games:", error)
      this.todaysGames = []
      this.render()
    }
  }

  loadPlayersForTeam(teamKey) {
    // Use pre-cached roster data from server
    this.teamPlayers = this.rosterData[teamKey] || []

    // Switch to player list view
    if (this.inputType === "player_team_select") {
      this.inputType = "player_list"
    } else if (this.inputType === "two_player_team_select") {
      this.inputType = "two_player_list"
    }
    this.render()
  }

  loadMenuData() {
    this.menuData = window.SPORTSBIFF_MENU_DATA || {}
  }

  loadRosterData() {
    // Load pre-cached roster data injected by the server
    this.rosterData = window.SPORTSBIFF_ROSTERS || {}
  }

  reset() {
    this.currentLevelValue = "sports"
    this.sportValue = ""
    this.categoryValue = ""
    this.selectedQuestion = null
    this.inputType = null
    this.playerSelectionStep = 1
    this.selectedPlayer1 = null
    this.selectedTeamForPlayer = null
    this.teamPlayers = []
  }
}
