# frozen_string_literal: true

# Service providing NFL roster data for the Quick Menu
# Data is pre-loaded (no API calls) for instant availability
class RosterCacheService
  class << self
    # Get all rosters
    def all_rosters
      nfl_rosters
    end

    # Get roster for a specific team
    def roster_for_team(team_key)
      nfl_rosters[team_key.to_s.upcase] || []
    end

    # Get all players as a flat array (for search)
    def all_players
      nfl_rosters.values.flatten
    end

    private

    def nfl_rosters
      {
        "ARI" => [
          { name: "Kyler Murray", team: "ARI", position: "QB" },
          { name: "Marvin Harrison Jr.", team: "ARI", position: "WR" },
          { name: "James Conner", team: "ARI", position: "RB" },
          { name: "Trey McBride", team: "ARI", position: "TE" },
          { name: "Budda Baker", team: "ARI", position: "S" }
        ],
        "ATL" => [
          { name: "Kirk Cousins", team: "ATL", position: "QB" },
          { name: "Bijan Robinson", team: "ATL", position: "RB" },
          { name: "Drake London", team: "ATL", position: "WR" },
          { name: "Kyle Pitts", team: "ATL", position: "TE" },
          { name: "Darnell Mooney", team: "ATL", position: "WR" }
        ],
        "BAL" => [
          { name: "Lamar Jackson", team: "BAL", position: "QB" },
          { name: "Derrick Henry", team: "BAL", position: "RB" },
          { name: "Mark Andrews", team: "BAL", position: "TE" },
          { name: "Zay Flowers", team: "BAL", position: "WR" },
          { name: "Roquan Smith", team: "BAL", position: "LB" }
        ],
        "BUF" => [
          { name: "Josh Allen", team: "BUF", position: "QB" },
          { name: "James Cook", team: "BUF", position: "RB" },
          { name: "Dalton Kincaid", team: "BUF", position: "TE" },
          { name: "Khalil Shakir", team: "BUF", position: "WR" },
          { name: "Von Miller", team: "BUF", position: "LB" }
        ],
        "CAR" => [
          { name: "Bryce Young", team: "CAR", position: "QB" },
          { name: "Chuba Hubbard", team: "CAR", position: "RB" },
          { name: "Diontae Johnson", team: "CAR", position: "WR" },
          { name: "Adam Thielen", team: "CAR", position: "WR" },
          { name: "Derrick Brown", team: "CAR", position: "DT" }
        ],
        "CHI" => [
          { name: "Caleb Williams", team: "CHI", position: "QB" },
          { name: "D'Andre Swift", team: "CHI", position: "RB" },
          { name: "DJ Moore", team: "CHI", position: "WR" },
          { name: "Keenan Allen", team: "CHI", position: "WR" },
          { name: "Rome Odunze", team: "CHI", position: "WR" },
          { name: "Cole Kmet", team: "CHI", position: "TE" }
        ],
        "CIN" => [
          { name: "Joe Burrow", team: "CIN", position: "QB" },
          { name: "Ja'Marr Chase", team: "CIN", position: "WR" },
          { name: "Tee Higgins", team: "CIN", position: "WR" },
          { name: "Zack Moss", team: "CIN", position: "RB" },
          { name: "Trey Hendrickson", team: "CIN", position: "DE" }
        ],
        "CLE" => [
          { name: "Deshaun Watson", team: "CLE", position: "QB" },
          { name: "Nick Chubb", team: "CLE", position: "RB" },
          { name: "Amari Cooper", team: "CLE", position: "WR" },
          { name: "David Njoku", team: "CLE", position: "TE" },
          { name: "Myles Garrett", team: "CLE", position: "DE" }
        ],
        "DAL" => [
          { name: "Dak Prescott", team: "DAL", position: "QB" },
          { name: "CeeDee Lamb", team: "DAL", position: "WR" },
          { name: "Micah Parsons", team: "DAL", position: "LB" },
          { name: "Rico Dowdle", team: "DAL", position: "RB" },
          { name: "Jake Ferguson", team: "DAL", position: "TE" }
        ],
        "DEN" => [
          { name: "Bo Nix", team: "DEN", position: "QB" },
          { name: "Javonte Williams", team: "DEN", position: "RB" },
          { name: "Courtland Sutton", team: "DEN", position: "WR" },
          { name: "Jerry Jeudy", team: "DEN", position: "WR" },
          { name: "Patrick Surtain II", team: "DEN", position: "CB" }
        ],
        "DET" => [
          { name: "Jared Goff", team: "DET", position: "QB" },
          { name: "Jahmyr Gibbs", team: "DET", position: "RB" },
          { name: "David Montgomery", team: "DET", position: "RB" },
          { name: "Amon-Ra St. Brown", team: "DET", position: "WR" },
          { name: "Sam LaPorta", team: "DET", position: "TE" },
          { name: "Aidan Hutchinson", team: "DET", position: "DE" }
        ],
        "GB" => [
          { name: "Jordan Love", team: "GB", position: "QB" },
          { name: "Josh Jacobs", team: "GB", position: "RB" },
          { name: "Jayden Reed", team: "GB", position: "WR" },
          { name: "Christian Watson", team: "GB", position: "WR" },
          { name: "Romeo Doubs", team: "GB", position: "WR" },
          { name: "Rashan Gary", team: "GB", position: "LB" }
        ],
        "HOU" => [
          { name: "C.J. Stroud", team: "HOU", position: "QB" },
          { name: "Joe Mixon", team: "HOU", position: "RB" },
          { name: "Nico Collins", team: "HOU", position: "WR" },
          { name: "Stefon Diggs", team: "HOU", position: "WR" },
          { name: "Tank Dell", team: "HOU", position: "WR" },
          { name: "Will Anderson Jr.", team: "HOU", position: "DE" }
        ],
        "IND" => [
          { name: "Anthony Richardson", team: "IND", position: "QB" },
          { name: "Jonathan Taylor", team: "IND", position: "RB" },
          { name: "Michael Pittman Jr.", team: "IND", position: "WR" },
          { name: "Josh Downs", team: "IND", position: "WR" },
          { name: "DeForest Buckner", team: "IND", position: "DT" }
        ],
        "JAX" => [
          { name: "Trevor Lawrence", team: "JAX", position: "QB" },
          { name: "Travis Etienne", team: "JAX", position: "RB" },
          { name: "Evan Engram", team: "JAX", position: "TE" },
          { name: "Christian Kirk", team: "JAX", position: "WR" },
          { name: "Josh Allen", team: "JAX", position: "LB" }
        ],
        "KC" => [
          { name: "Patrick Mahomes", team: "KC", position: "QB" },
          { name: "Travis Kelce", team: "KC", position: "TE" },
          { name: "Isiah Pacheco", team: "KC", position: "RB" },
          { name: "Rashee Rice", team: "KC", position: "WR" },
          { name: "Chris Jones", team: "KC", position: "DT" },
          { name: "Xavier Worthy", team: "KC", position: "WR" }
        ],
        "LAC" => [
          { name: "Justin Herbert", team: "LAC", position: "QB" },
          { name: "J.K. Dobbins", team: "LAC", position: "RB" },
          { name: "Ladd McConkey", team: "LAC", position: "WR" },
          { name: "Quentin Johnston", team: "LAC", position: "WR" },
          { name: "Derwin James", team: "LAC", position: "S" },
          { name: "Joey Bosa", team: "LAC", position: "DE" }
        ],
        "LAR" => [
          { name: "Matthew Stafford", team: "LAR", position: "QB" },
          { name: "Kyren Williams", team: "LAR", position: "RB" },
          { name: "Puka Nacua", team: "LAR", position: "WR" },
          { name: "Cooper Kupp", team: "LAR", position: "WR" },
          { name: "Aaron Donald", team: "LAR", position: "DT" }
        ],
        "LV" => [
          { name: "Gardner Minshew", team: "LV", position: "QB" },
          { name: "Zamir White", team: "LV", position: "RB" },
          { name: "Davante Adams", team: "LV", position: "WR" },
          { name: "Jakobi Meyers", team: "LV", position: "WR" },
          { name: "Maxx Crosby", team: "LV", position: "DE" }
        ],
        "MIA" => [
          { name: "Tua Tagovailoa", team: "MIA", position: "QB" },
          { name: "De'Von Achane", team: "MIA", position: "RB" },
          { name: "Tyreek Hill", team: "MIA", position: "WR" },
          { name: "Jaylen Waddle", team: "MIA", position: "WR" },
          { name: "Jalen Ramsey", team: "MIA", position: "CB" }
        ],
        "MIN" => [
          { name: "Sam Darnold", team: "MIN", position: "QB" },
          { name: "Aaron Jones", team: "MIN", position: "RB" },
          { name: "Justin Jefferson", team: "MIN", position: "WR" },
          { name: "Jordan Addison", team: "MIN", position: "WR" },
          { name: "T.J. Hockenson", team: "MIN", position: "TE" }
        ],
        "NE" => [
          { name: "Drake Maye", team: "NE", position: "QB" },
          { name: "Rhamondre Stevenson", team: "NE", position: "RB" },
          { name: "Hunter Henry", team: "NE", position: "TE" },
          { name: "Kendrick Bourne", team: "NE", position: "WR" },
          { name: "Christian Barmore", team: "NE", position: "DT" }
        ],
        "NO" => [
          { name: "Derek Carr", team: "NO", position: "QB" },
          { name: "Alvin Kamara", team: "NO", position: "RB" },
          { name: "Chris Olave", team: "NO", position: "WR" },
          { name: "Rashid Shaheed", team: "NO", position: "WR" },
          { name: "Cameron Jordan", team: "NO", position: "DE" }
        ],
        "NYG" => [
          { name: "Daniel Jones", team: "NYG", position: "QB" },
          { name: "Saquon Barkley", team: "NYG", position: "RB" },
          { name: "Malik Nabers", team: "NYG", position: "WR" },
          { name: "Wan'Dale Robinson", team: "NYG", position: "WR" },
          { name: "Dexter Lawrence", team: "NYG", position: "DT" }
        ],
        "NYJ" => [
          { name: "Aaron Rodgers", team: "NYJ", position: "QB" },
          { name: "Breece Hall", team: "NYJ", position: "RB" },
          { name: "Garrett Wilson", team: "NYJ", position: "WR" },
          { name: "Davante Adams", team: "NYJ", position: "WR" },
          { name: "Sauce Gardner", team: "NYJ", position: "CB" }
        ],
        "PHI" => [
          { name: "Jalen Hurts", team: "PHI", position: "QB" },
          { name: "Saquon Barkley", team: "PHI", position: "RB" },
          { name: "A.J. Brown", team: "PHI", position: "WR" },
          { name: "DeVonta Smith", team: "PHI", position: "WR" },
          { name: "Dallas Goedert", team: "PHI", position: "TE" }
        ],
        "PIT" => [
          { name: "Russell Wilson", team: "PIT", position: "QB" },
          { name: "Najee Harris", team: "PIT", position: "RB" },
          { name: "George Pickens", team: "PIT", position: "WR" },
          { name: "Pat Freiermuth", team: "PIT", position: "TE" },
          { name: "T.J. Watt", team: "PIT", position: "LB" }
        ],
        "SEA" => [
          { name: "Geno Smith", team: "SEA", position: "QB" },
          { name: "Kenneth Walker III", team: "SEA", position: "RB" },
          { name: "DK Metcalf", team: "SEA", position: "WR" },
          { name: "Tyler Lockett", team: "SEA", position: "WR" },
          { name: "Jaxon Smith-Njigba", team: "SEA", position: "WR" }
        ],
        "SF" => [
          { name: "Brock Purdy", team: "SF", position: "QB" },
          { name: "Christian McCaffrey", team: "SF", position: "RB" },
          { name: "Deebo Samuel", team: "SF", position: "WR" },
          { name: "Brandon Aiyuk", team: "SF", position: "WR" },
          { name: "George Kittle", team: "SF", position: "TE" },
          { name: "Nick Bosa", team: "SF", position: "DE" }
        ],
        "TB" => [
          { name: "Baker Mayfield", team: "TB", position: "QB" },
          { name: "Rachaad White", team: "TB", position: "RB" },
          { name: "Mike Evans", team: "TB", position: "WR" },
          { name: "Chris Godwin", team: "TB", position: "WR" },
          { name: "Cade Otton", team: "TB", position: "TE" }
        ],
        "TEN" => [
          { name: "Will Levis", team: "TEN", position: "QB" },
          { name: "Tony Pollard", team: "TEN", position: "RB" },
          { name: "DeAndre Hopkins", team: "TEN", position: "WR" },
          { name: "Calvin Ridley", team: "TEN", position: "WR" },
          { name: "Jeffery Simmons", team: "TEN", position: "DT" }
        ],
        "WAS" => [
          { name: "Jayden Daniels", team: "WAS", position: "QB" },
          { name: "Brian Robinson Jr.", team: "WAS", position: "RB" },
          { name: "Terry McLaurin", team: "WAS", position: "WR" },
          { name: "Jahan Dotson", team: "WAS", position: "WR" },
          { name: "Jonathan Allen", team: "WAS", position: "DT" }
        ]
      }
    end
  end
end
