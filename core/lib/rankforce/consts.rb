module RankForce
  module Consts
    VERSION         = '0.4.7'
    TWEET_LIMIT     = 15
    CRAWLE_TIMEOUT  = 10
    CRAWLE_URL      = "http://2ch-ranking.net/"
    BOARD_URL       = "#{CRAWLE_URL}/menu.html"
    API_URL         = "#{CRAWLE_URL}/ranking.json"
    BOARD_FILE_JA   = 'board.ja.txt'
    BOARD_FILE_EN   = 'board.en.txt'
    DIECT_MESSAGE   = 'direct_message.txt'
    CONFIG_ROOT     = File.dirname(__FILE__) + "/../../config"
    BOARD_ROOT      = File.dirname(__FILE__) + "/../../board"
    SHORT_URL       = "https://api-ssl.bitly.com/v3/shorten?access_token=%s&longUrl=%s"
    DEFAULT_RES_NUM = 50
    HISTORY_SIZE    = 10
  end
end
