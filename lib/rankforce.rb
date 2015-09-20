# -*- coding: utf-8 -*-
require 'rankforce/crawler'
require 'rankforce/tweet'
require 'rankforce/base'
require 'rankforce/mongo_client'
require 'rankforce/limit_manager'
require 'rankforce/board'

module RankForce
  class Runner < Base
    def initialize(config = {})
      @limit = LimitManager.new
      @twitter = Tweet.new("twitter.auth.test.yml")
      @board = Board.new
      @mongo_client = MongoClient.new("mongolab.test.yml")
      @ngwords = load_ngword
      super
    end

    def signal
      Signal.trap(:INT) do
        puts "now shotdown...\n"
        run_background('stop')
        exit(0)
      end
    end

    def load
      load_config("#{CONFIG_ROOT}/board.yml").each do |board|
        board.each do |name, config|
          ikioi = config['ikioi']
          time = config['time']
          yield name, ikioi, time if validate(name, ikioi, time)
        end
      end
    end

    def run_background(command)
      syslog.debug("execute command: bundle exec ruby bin/rankforce_stream.rb #{command}")
      system "bundle exec ruby bin/rankforce_stream.rb #{command}"
    end

    def run(board, ikioi)
      begin
        signal
        crawler = Crawler.new(board, ikioi, @ngwords)
        crawler.get do |data, name|
          begin
            data[:url] = delete_resnum(data[:url])
            @mongo_client.save(data) do
              @limit.run do |count, limit_date|
                syslog.info("Tweet count: #{count}/#{TWEET_LIMIT}")
                syslog.info("Limit date: #{limit_date}")
                data[:title] = data[:title]
                data[:url] = to_short(add_resnum(data[:url], DEFAULT_RES_NUM))
                data[:board] = @board.to_ja name.to_s
                @twitter.post(data) {|text| logger.info(text)}
              end
            end
          rescue => e
            syslog.error(e)
          end
        end
      rescue => e
        syslog.error(e)
      end
    end

    def run_stream(type)
      syslog.debug("execute type: #{type}")
      @twitter.send("#{type}_stream")
    end
  end
end
