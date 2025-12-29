module ApplicationHelper
  SPORT_EMOJIS = {
    "NFL" => "🏈",
    "NBA" => "🏀",
    "MLB" => "⚾",
    "NHL" => "🏒",
    "EPL" => "⚽",
    "MLS" => "⚽"
  }.freeze

  SPORT_DISPLAY_NAMES = {
    "NFL" => "NFL Football",
    "NBA" => "NBA Basketball",
    "MLB" => "MLB Baseball",
    "NHL" => "NHL Hockey",
    "EPL" => "Premier League",
    "MLS" => "MLS Soccer"
  }.freeze

  def sport_emoji(sport)
    SPORT_EMOJIS[sport] || "🏆"
  end

  def sport_display_name(sport)
    SPORT_DISPLAY_NAMES[sport] || sport
  end
end
