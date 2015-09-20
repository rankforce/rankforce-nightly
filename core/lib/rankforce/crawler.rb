# -*- coding: utf-8 -*-
require 'rankforce/utils'
require 'rankforce/consts'
require 'mechanize'
require 'json'
require 'parallel_runner'

module RankForce
  class Crawler
    include RankForce::Utils
    include RankForce::Consts

    def initialize(board, ikioi, ngwords)
      @board = board
      @ikioi = ikioi.to_i
      @ngwords = Regexp.union(ngwords)
      @agent = Mechanize.new
      @agent.user_agent_alias = "Windows IE 8"
      @agent.read_timeout = CRAWLE_TIMEOUT
    end

    def get
      get_board_data.each_parallel {|board_data| yield board_data, @board}
    end

    private
    # json api version.
    # But Can't get board data because return 304 immediately.
    def get_board_data_by_json(board, threshold)
      result = []
      @agent.get(API_URL, {'board' => board}) do |response|
        syslog.info("#{response.uri.to_s} (#{response.code})")
        if response.code == '200'
          json = response.body
          json.slice!(0, 9)
          json.slice!(-2, 2)
          result = JSON.parse(json)
        end
      end
      result
    end

    def get_board_data
      list = []
      site = @agent.get(CRAWLE_URL, {'board' => @board})
      site.encoding = 'CP932'
      lines = (site/'//table[@class="forces first_f"]/tr')
      lines.each do |line|
        ikioi = line.search("td.ikioi").text.to_i
        url = (line.search("td.title a").map {|e| e["href"].to_s})[0]
        title = delete_copy(line.search("td.title").text.strip.encode("UTF-8"))
        next if @ngwords =~ title
        next if url.nil? || ikioi < @ikioi
        date = Time.at($1.to_i).to_s if /(\d{10})/ =~ url
        list << {
          :ikioi => ikioi,
          :title => title,
          :url => url,
          :board => @board,
          :created_at => date
        }
      end
      list
    end
  end
end
