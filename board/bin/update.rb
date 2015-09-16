# -*- coding: utf-8 -*-
$: << File.dirname(File.expand_path($PROGRAM_NAME)) + "/../../lib"
require 'rankforce/base'
require 'optparse'

module RankForce
  class BoardUpdate < Base
    def save
      syslog.debug("start board update.")
      get_board do |board_ja, board_en|
        File.open("#{BOARD_ROOT}/#{BOARD_FILE_JA}", 'w') do |f|
          f.puts board_ja.join("\n")
        end
        File.open("#{BOARD_ROOT}/#{BOARD_FILE_EN}", 'w') do |f|
          f.puts board_en.join("\n")
        end
      end
      syslog.debug("end board update.")
    end

    private
    def get_board
      agent = Mechanize.new
      agent.read_timeout = CRAWLE_TIMEOUT
      agent.user_agent_alias = "Windows IE 8"
      board_ja = []
      board_en = []
      (agent.get(BOARD_URL)/'div[class="main"]/ul/li').each do |elem|
        board_ja << elem.at("a").text
        board_en << elem.at("a")["href"].gsub(/.*=/, '')
      end
      board_ja.delete_at(0)
      board_en.delete_at(0)
      yield board_ja, board_en
    end
  end
end

config = {:test => false}
OptionParser.new do |opt|
  opt.on('-t', '--test') {|boolean| config[:test] = boolean} # test mode
  opt.parse!
end
board = RankForce::BoardUpdate.new(config)
board.save
