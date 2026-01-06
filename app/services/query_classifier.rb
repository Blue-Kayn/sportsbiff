# frozen_string_literal: true

# Classifies user questions to determine the appropriate data source
# Based on Architecture v2.0: Web Search (90%) vs API (10%)
#
# WEB SEARCH: General Q&A, news, analysis, historical facts, expert picks
# API: Betting math, live scores, prop analysis, user-specific data
class QueryClassifier
  # Questions that MUST use API (cannot be answered by web search)
  API_REQUIRED_PATTERNS = [
    # Betting math - requires computation
    /did.*(cover|hit)/i,                           # "Did they cover the spread?"
    /spread.*(cover|hit|win|lose)/i,               # "Did the spread cover?"
    /over.?under.*(hit|cover|cash)/i,              # "Did the over hit?"
    /push\s*(or|vs)\s*cover/i,                     # "Push or cover?"
    /was\s+the\s+.*(winner|loser)/i,               # "Was the Eagles -3.5 a winner?"

    # Prop bet results
    /prop.*(hit|result|cash)/i,                    # "Did the prop hit?"
    /hit\s+rate/i,                                 # "What's his hit rate?"
    /how\s+often\s+does.*(go\s+over|hit)/i,        # "How often does he go over?"

    # Current betting lines (real-time)
    /what('s| is)\s+the\s+(spread|line|total|over.?under|moneyline)/i,
    /current\s+(spread|line|odds|total)/i,
    /odds\s+(right\s+)?now/i,
    /best\s+odds/i,
    /compare\s+odds/i,

    # Line movement (requires historical odds data)
    /line\s+(move|movement|moved)/i,
    /where\s+did.*(open|start)/i,
    /sharp\s+money/i,
    /odds\s+(move|change)/i,

    # Betting trends & aggregations
    /ats\s+record/i,                               # Against the spread record
    /cover\s+as\s+(underdog|favorite|home|away)/i,
    /over.?under\s+trend/i,
    /betting\s+trend/i,

    # Live game data (faster than search indexing)
    /current\s+score/i,
    /live\s+score/i,
    /what('s| is)\s+the\s+score\s+(right\s+)?now/i,
    /who('s| is)\s+winning\s+(right\s+)?now/i,
    /what\s+quarter/i,
    /is\s+the\s+game\s+(over|still|in\s+progress)/i,
    /real\s*time/i,
    /play\s+by\s+play/i,

    # User-specific data (stored in DB)
    /my\s+(bet|bets|history|roi|record)/i,
    /track\s+this\s+bet/i,
    /my\s+favorite\s+team/i
  ].freeze

  # Questions that should PREFER web search (general Q&A)
  WEB_SEARCH_PATTERNS = [
    # General factual questions
    /did\s+.*make\s+(the\s+)?playoffs?/i,
    /who\s+won/i,
    /is\s+.*injured/i,
    /who('s| is)\s+the\s+best/i,
    /who\s+should\s+win/i,
    /what\s+are\s+experts\s+saying/i,
    /tell\s+me\s+about/i,
    /why\s+(are|is)\s+the/i,
    /what('s| is)\s+the\s+story/i,
    /mvp\s+(favorite|candidate|race)/i,
    /trade\s+rumor/i,
    /what\s+happened\s+in/i,
    /best\s+record/i,
    /playoff\s+picture/i,
    /standings/i,
    /historical/i,
    /record|streak|milestone/i,
    /draft\s+news/i,
    /coaching\s+change/i,
    /analysis|opinion/i,
    /context|narrative/i,
    /journalist/i,

    # News and rumors
    /news/i,
    /rumor/i,
    /report/i,
    /update/i,
    /latest/i,

    # Analysis and opinions
    /should\s+i\s+(bet|take|pick)/i,
    /what\s+do\s+you\s+think/i,
    /prediction/i,
    /who\s+will\s+win/i,
    /expect/i
  ].freeze

  # Questions that need BOTH (hybrid)
  HYBRID_PATTERNS = [
    /should\s+i\s+bet\s+(the\s+)?(over|under|spread)/i,  # Need line + analysis
    /good\s+bet/i,                                       # Need odds + context
    /value\s+(bet|play|on)/i,                            # Need odds + analysis
    /value.*(spread|over|under|line)/i                   # "value on the spread"
  ].freeze

  def initialize(question)
    @question = question.to_s.strip
  end

  # Returns :api, :web_search, or :hybrid
  def classify
    return :api if api_required?
    return :hybrid if hybrid_needed?
    return :web_search if web_search_preferred?

    # Default: prefer web search for general questions
    :web_search
  end

  # Detailed classification with explanation
  def classify_with_reason
    {
      source: classify,
      reason: classification_reason,
      question: @question
    }
  end

  private

  def api_required?
    API_REQUIRED_PATTERNS.any? { |pattern| @question.match?(pattern) }
  end

  def hybrid_needed?
    HYBRID_PATTERNS.any? { |pattern| @question.match?(pattern) }
  end

  def web_search_preferred?
    WEB_SEARCH_PATTERNS.any? { |pattern| @question.match?(pattern) }
  end

  def classification_reason
    if api_required?
      matching_pattern = API_REQUIRED_PATTERNS.find { |p| @question.match?(p) }
      "Requires API: #{pattern_category(matching_pattern)}"
    elsif hybrid_needed?
      "Hybrid: Needs both betting data and context/analysis"
    elsif web_search_preferred?
      "Web search preferred: General Q&A/narrative question"
    else
      "Default to web search: No specific API requirement detected"
    end
  end

  def pattern_category(pattern)
    pattern_str = pattern.to_s
    return "betting math computation" if pattern_str.include?("cover") || pattern_str.include?("hit")
    return "current betting lines" if pattern_str.include?("spread") || pattern_str.include?("odds")
    return "line movement data" if pattern_str.include?("move")
    return "live game data" if pattern_str.include?("score") || pattern_str.include?("quarter")
    return "user-specific data" if pattern_str.include?("my")
    "specialized betting data"
  end
end
