# Seed Teams first (required for user favorites)
puts "Seeding teams..."

# NFL Teams (all 32)
nfl_teams = [
  { name: "Arizona Cardinals", api_id: "ari", colors: { "primary" => "#97233F", "secondary" => "#000000" } },
  { name: "Atlanta Falcons", api_id: "atl", colors: { "primary" => "#A71930", "secondary" => "#000000" } },
  { name: "Baltimore Ravens", api_id: "bal", colors: { "primary" => "#241773", "secondary" => "#000000" } },
  { name: "Buffalo Bills", api_id: "buf", colors: { "primary" => "#00338D", "secondary" => "#C60C30" } },
  { name: "Carolina Panthers", api_id: "car", colors: { "primary" => "#0085CA", "secondary" => "#101820" } },
  { name: "Chicago Bears", api_id: "chi", colors: { "primary" => "#0B162A", "secondary" => "#C83803" } },
  { name: "Cincinnati Bengals", api_id: "cin", colors: { "primary" => "#FB4F14", "secondary" => "#000000" } },
  { name: "Cleveland Browns", api_id: "cle", colors: { "primary" => "#311D00", "secondary" => "#FF3C00" } },
  { name: "Dallas Cowboys", api_id: "dal", colors: { "primary" => "#003594", "secondary" => "#869397" } },
  { name: "Denver Broncos", api_id: "den", colors: { "primary" => "#FB4F14", "secondary" => "#002244" } },
  { name: "Detroit Lions", api_id: "det", colors: { "primary" => "#0076B6", "secondary" => "#B0B7BC" } },
  { name: "Green Bay Packers", api_id: "gb", colors: { "primary" => "#203731", "secondary" => "#FFB612" } },
  { name: "Houston Texans", api_id: "hou", colors: { "primary" => "#03202F", "secondary" => "#A71930" } },
  { name: "Indianapolis Colts", api_id: "ind", colors: { "primary" => "#002C5F", "secondary" => "#A2AAAD" } },
  { name: "Jacksonville Jaguars", api_id: "jax", colors: { "primary" => "#006778", "secondary" => "#D7A22A" } },
  { name: "Kansas City Chiefs", api_id: "kc", colors: { "primary" => "#E31837", "secondary" => "#FFB81C" } },
  { name: "Las Vegas Raiders", api_id: "lv", colors: { "primary" => "#000000", "secondary" => "#A5ACAF" } },
  { name: "Los Angeles Chargers", api_id: "lac", colors: { "primary" => "#0080C6", "secondary" => "#FFC20E" } },
  { name: "Los Angeles Rams", api_id: "lar", colors: { "primary" => "#003594", "secondary" => "#FFA300" } },
  { name: "Miami Dolphins", api_id: "mia", colors: { "primary" => "#008E97", "secondary" => "#FC4C02" } },
  { name: "Minnesota Vikings", api_id: "min", colors: { "primary" => "#4F2683", "secondary" => "#FFC62F" } },
  { name: "New England Patriots", api_id: "ne", colors: { "primary" => "#002244", "secondary" => "#C60C30" } },
  { name: "New Orleans Saints", api_id: "no", colors: { "primary" => "#D3BC8D", "secondary" => "#101820" } },
  { name: "New York Giants", api_id: "nyg", colors: { "primary" => "#0B2265", "secondary" => "#A71930" } },
  { name: "New York Jets", api_id: "nyj", colors: { "primary" => "#125740", "secondary" => "#000000" } },
  { name: "Philadelphia Eagles", api_id: "phi", colors: { "primary" => "#004C54", "secondary" => "#A5ACAF" } },
  { name: "Pittsburgh Steelers", api_id: "pit", colors: { "primary" => "#FFB612", "secondary" => "#101820" } },
  { name: "San Francisco 49ers", api_id: "sf", colors: { "primary" => "#AA0000", "secondary" => "#B3995D" } },
  { name: "Seattle Seahawks", api_id: "sea", colors: { "primary" => "#002244", "secondary" => "#69BE28" } },
  { name: "Tampa Bay Buccaneers", api_id: "tb", colors: { "primary" => "#D50A0A", "secondary" => "#FF7900" } },
  { name: "Tennessee Titans", api_id: "ten", colors: { "primary" => "#0C2340", "secondary" => "#4B92DB" } },
  { name: "Washington Commanders", api_id: "wsh", colors: { "primary" => "#5A1414", "secondary" => "#FFB612" } }
]

nfl_teams.each do |team_data|
  Team.find_or_create_by!(sport: "NFL", api_id: team_data[:api_id]) do |team|
    team.name = team_data[:name]
    team.colors = team_data[:colors]
    team.logo_url = "https://a.espncdn.com/i/teamlogos/nfl/500/#{team_data[:api_id]}.png"
  end
end
puts "  Created #{Team.where(sport: 'NFL').count} NFL teams"

# NBA Teams (all 30)
nba_teams = [
  { name: "Atlanta Hawks", api_id: "atl", colors: { "primary" => "#E03A3E", "secondary" => "#C1D32F" } },
  { name: "Boston Celtics", api_id: "bos", colors: { "primary" => "#007A33", "secondary" => "#BA9653" } },
  { name: "Brooklyn Nets", api_id: "bkn", colors: { "primary" => "#000000", "secondary" => "#FFFFFF" } },
  { name: "Charlotte Hornets", api_id: "cha", colors: { "primary" => "#1D1160", "secondary" => "#00788C" } },
  { name: "Chicago Bulls", api_id: "chi", colors: { "primary" => "#CE1141", "secondary" => "#000000" } },
  { name: "Cleveland Cavaliers", api_id: "cle", colors: { "primary" => "#860038", "secondary" => "#FDBB30" } },
  { name: "Dallas Mavericks", api_id: "dal", colors: { "primary" => "#00538C", "secondary" => "#002B5E" } },
  { name: "Denver Nuggets", api_id: "den", colors: { "primary" => "#0E2240", "secondary" => "#FEC524" } },
  { name: "Detroit Pistons", api_id: "det", colors: { "primary" => "#C8102E", "secondary" => "#1D42BA" } },
  { name: "Golden State Warriors", api_id: "gs", colors: { "primary" => "#1D428A", "secondary" => "#FFC72C" } },
  { name: "Houston Rockets", api_id: "hou", colors: { "primary" => "#CE1141", "secondary" => "#000000" } },
  { name: "Indiana Pacers", api_id: "ind", colors: { "primary" => "#002D62", "secondary" => "#FDBB30" } },
  { name: "LA Clippers", api_id: "lac", colors: { "primary" => "#C8102E", "secondary" => "#1D428A" } },
  { name: "Los Angeles Lakers", api_id: "lal", colors: { "primary" => "#552583", "secondary" => "#FDB927" } },
  { name: "Memphis Grizzlies", api_id: "mem", colors: { "primary" => "#5D76A9", "secondary" => "#12173F" } },
  { name: "Miami Heat", api_id: "mia", colors: { "primary" => "#98002E", "secondary" => "#F9A01B" } },
  { name: "Milwaukee Bucks", api_id: "mil", colors: { "primary" => "#00471B", "secondary" => "#EEE1C6" } },
  { name: "Minnesota Timberwolves", api_id: "min", colors: { "primary" => "#0C2340", "secondary" => "#236192" } },
  { name: "New Orleans Pelicans", api_id: "no", colors: { "primary" => "#0C2340", "secondary" => "#C8102E" } },
  { name: "New York Knicks", api_id: "ny", colors: { "primary" => "#006BB6", "secondary" => "#F58426" } },
  { name: "Oklahoma City Thunder", api_id: "okc", colors: { "primary" => "#007AC1", "secondary" => "#EF3B24" } },
  { name: "Orlando Magic", api_id: "orl", colors: { "primary" => "#0077C0", "secondary" => "#C4CED4" } },
  { name: "Philadelphia 76ers", api_id: "phi", colors: { "primary" => "#006BB6", "secondary" => "#ED174C" } },
  { name: "Phoenix Suns", api_id: "phx", colors: { "primary" => "#1D1160", "secondary" => "#E56020" } },
  { name: "Portland Trail Blazers", api_id: "por", colors: { "primary" => "#E03A3E", "secondary" => "#000000" } },
  { name: "Sacramento Kings", api_id: "sac", colors: { "primary" => "#5A2D81", "secondary" => "#63727A" } },
  { name: "San Antonio Spurs", api_id: "sa", colors: { "primary" => "#C4CED4", "secondary" => "#000000" } },
  { name: "Toronto Raptors", api_id: "tor", colors: { "primary" => "#CE1141", "secondary" => "#000000" } },
  { name: "Utah Jazz", api_id: "uta", colors: { "primary" => "#002B5C", "secondary" => "#00471B" } },
  { name: "Washington Wizards", api_id: "wsh", colors: { "primary" => "#002B5C", "secondary" => "#E31837" } }
]

nba_teams.each do |team_data|
  Team.find_or_create_by!(sport: "NBA", api_id: "nba_#{team_data[:api_id]}") do |team|
    team.name = team_data[:name]
    team.colors = team_data[:colors]
    team.logo_url = "https://a.espncdn.com/i/teamlogos/nba/500/#{team_data[:api_id]}.png"
  end
end
puts "  Created #{Team.where(sport: 'NBA').count} NBA teams"

# Premier League Teams (20 teams for 2024-25 season)
epl_teams = [
  { name: "Arsenal", api_id: "ars", colors: { "primary" => "#EF0107", "secondary" => "#063672" } },
  { name: "Aston Villa", api_id: "avl", colors: { "primary" => "#670E36", "secondary" => "#95BFE5" } },
  { name: "Bournemouth", api_id: "bou", colors: { "primary" => "#DA291C", "secondary" => "#000000" } },
  { name: "Brentford", api_id: "bre", colors: { "primary" => "#E30613", "secondary" => "#FBB800" } },
  { name: "Brighton & Hove Albion", api_id: "bha", colors: { "primary" => "#0057B8", "secondary" => "#FFCD00" } },
  { name: "Chelsea", api_id: "che", colors: { "primary" => "#034694", "secondary" => "#DBA111" } },
  { name: "Crystal Palace", api_id: "cry", colors: { "primary" => "#1B458F", "secondary" => "#C4122E" } },
  { name: "Everton", api_id: "eve", colors: { "primary" => "#003399", "secondary" => "#FFFFFF" } },
  { name: "Fulham", api_id: "ful", colors: { "primary" => "#000000", "secondary" => "#CC0000" } },
  { name: "Ipswich Town", api_id: "ips", colors: { "primary" => "#0044AA", "secondary" => "#FFFFFF" } },
  { name: "Leicester City", api_id: "lei", colors: { "primary" => "#003090", "secondary" => "#FDBE11" } },
  { name: "Liverpool", api_id: "liv", colors: { "primary" => "#C8102E", "secondary" => "#00B2A9" } },
  { name: "Manchester City", api_id: "mci", colors: { "primary" => "#6CABDD", "secondary" => "#1C2C5B" } },
  { name: "Manchester United", api_id: "mun", colors: { "primary" => "#DA291C", "secondary" => "#FBE122" } },
  { name: "Newcastle United", api_id: "new", colors: { "primary" => "#241F20", "secondary" => "#FFFFFF" } },
  { name: "Nottingham Forest", api_id: "nfo", colors: { "primary" => "#DD0000", "secondary" => "#FFFFFF" } },
  { name: "Southampton", api_id: "sou", colors: { "primary" => "#D71920", "secondary" => "#130C0E" } },
  { name: "Tottenham Hotspur", api_id: "tot", colors: { "primary" => "#132257", "secondary" => "#FFFFFF" } },
  { name: "West Ham United", api_id: "whu", colors: { "primary" => "#7A263A", "secondary" => "#1BB1E7" } },
  { name: "Wolverhampton Wanderers", api_id: "wol", colors: { "primary" => "#FDB913", "secondary" => "#231F20" } }
]

epl_teams.each do |team_data|
  Team.find_or_create_by!(sport: "EPL", api_id: "epl_#{team_data[:api_id]}") do |team|
    team.name = team_data[:name]
    team.colors = team_data[:colors]
    team.logo_url = "https://a.espncdn.com/i/teamlogos/soccer/500/#{team_data[:api_id]}.png"
  end
end
puts "  Created #{Team.where(sport: 'EPL').count} EPL teams"

puts "Total teams: #{Team.count}"

# Demo user with higher limits
demo_user = User.find_or_create_by!(email: "demo@sportsbiff.com") do |user|
  user.password = "demo123456"
  user.password_confirmation = "demo123456"
  user.subscription_tier = "pro"
end

# Set up demo user with some favorite teams
demo_user.update!(
  onboarded: true,
  favorite_sports: ["NFL", "NBA", "EPL"],
  favorite_teams: [
    { "sport" => "NFL", "team_id" => "nyg", "team_name" => "New York Giants" },
    { "sport" => "NBA", "team_id" => "nba_ny", "team_name" => "New York Knicks" },
    { "sport" => "EPL", "team_id" => "epl_ars", "team_name" => "Arsenal" }
  ]
)

puts "Created demo user: #{demo_user.email} (password: demo123456)"

# Regular test user (not onboarded)
test_user = User.find_or_create_by!(email: "test@example.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Created test user: #{test_user.email} (password: password123)"

# Sample chat with messages for demo
if demo_user.chats.empty?
  chat = demo_user.chats.create!(title: "Giants game analysis")

  chat.messages.create!(
    role: "user",
    content: "How are the Giants doing this season?"
  )

  chat.messages.create!(
    role: "assistant",
    content: <<~RESPONSE
      Rough stretch for Big Blue. The Giants are struggling at 2-5 after losing to the Eagles 28-14 on Sunday.

      **The issues:**
      - Daniel Jones has been inconsistent - 2 TDs but 3 INTs in the last two games
      - The offensive line is the real problem, giving up pressure on nearly 40% of dropbacks
      - Run game can't get going without solid blocking

      **Coming up:** Cowboys at home, which is a must-win if they want any shot at the playoffs.

      Markets have them as 3-point underdogs at home against Dallas, which tells you where expectations are. The home underdog angle is interesting historically, but that offensive line needs to show up.

      What else do you want to know about the Giants?
    RESPONSE
  )

  puts "Created sample chat with messages for demo user"
end

# Seed some mock odds data
OddsApiService.new.fetch_upcoming_events.each do |event|
  OddsCache.store(
    sport: "americanfootball_nfl",
    event_id: event["id"],
    data: event
  )
end

puts "Seeded #{OddsCache.count} odds cache entries"

puts "\n=== Seed Complete ==="
puts "Demo account: demo@sportsbiff.com / demo123456 (onboarded, pro tier)"
puts "Test account: test@example.com / password123 (not onboarded)"
puts "Teams: #{Team.count} total (#{Team.where(sport: 'NFL').count} NFL, #{Team.where(sport: 'NBA').count} NBA, #{Team.where(sport: 'EPL').count} EPL)"
