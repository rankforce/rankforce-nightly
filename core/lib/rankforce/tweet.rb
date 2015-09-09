# -*- coding: utf-8 -*-
require 'rankforce/consts'
require 'rankforce/utils'
require 'twitter'
require 'tweetstream'
require 'sys/proctable'

module RankForce
  class Tweet
    include RankForce::Consts
    include RankForce::Utils

    TWEETSTREAM_PROCESS_NAME = 'ruby'
    TWEETSTREAM_PROCESS_REAL_NAME = 'tweetstream'

    def initialize(file)
      config_client        = load_config("#{CONFIG_ROOT}/#{file}")
      config_stream_client = load_config("#{CONFIG_ROOT}/#{file}")
      @client              = create_client(config_client)
      @client_stream       = create_stream_client(config_stream_client)
      @mongo_client        = MongoClient.new("mongolab.test.yml")
    end

    def post(data)
      text = "【#{data[:board]}】#{data[:title]} (勢い:#{data[:ikioi]}) #{data[:url]}"
      result = @client.update(text)
      if block_given?
        yield text if !!result
      else
        !!result
      end
    end

    def start_stream
      syslog.info("Start twitter stream.")
      start_event
      @client_stream.userstream unless @client_stream.nil?
    end

    def stop_stream
      syslog.info("Stop twitter stream.")
      Sys::ProcTable.ps.each do |ps|
        if ps.comm == TWEETSTREAM_PROCESS_NAME && ps.cmdline.strip == TWEETSTREAM_PROCESS_REAL_NAME
          Process.kill('KILL', ps.pid)
          syslog.info("Stop process: #{ps.pid}")
        end
      end
    end

    private
    def direct_message
      File.open("#{CONFIG_ROOT}/#{DIECT_MESSAGE}") do |f|
        return f.read.strip
      end
    end

    def load_config_with_prefix(file, prefix = nil)
      return load_config(file) if prefix.nil?
      load_config(file).each_with_object({}) do |(key, value), params|
        params[key.sub(prefix, '')] = value if /^#{prefix}/ =~ key
      end
    end

    def start_event
      begin
        @client_stream.on_anything do |status|
          # follow and send direct message
          follow(direct_message % VERSION, status) if status[:event] == 'follow'
          # retweet
          retweet(status) unless status[:retweeted_status].nil?
          # quote_retweet
          quote_retweet(status) if status[:retweeted_status].nil? && status[:event].nil?
          # favorite
          favorite(status) if status[:event] == 'favorite'
          # unfavorite
          unfavorite(status) if status[:event] == 'unfavorite'
        end
        @client_stream.on_error do |message|
          syslog.error(message)
        end
      rescue => e
        syslog.error(e.message)
      end
    end

    def follow(message, status)
      name = status[:source][:screen_name]
      @client.follow(name)
      @client.direct_message_create(name, message)
      syslog.info("Followed @#{name} and send direct message.")
    end

    def retweet(status)
      name = status[:user][:screen_name]
      url = decode_url(status[:entities][:urls][0][:expanded_url])
      delete_resnum(url)
      list = @mongo_client.get(:url => url)
      if !list.nil? && list.size > 0
        data = list[0]
        data['retweet'] = data['retweet'] + 1
        @mongo_client.put(data, :url => url)
        syslog.info("Retweeted by #{name}")
        syslog.info("Total retweets in #{url}: #{data['retweet']}")
      else
        syslog.error("Retweet data can not get from mongolab: " + url)
      end
    end

    def quote_retweet(status)
      retweet(status) if /(?:RT|QT|“)\s{0,1}@.*?\:/ =~ status[:text]
    end

    def favorite(status)
      name = status[:source][:screen_name]
      url = decode_url(status[:target_object][:entities][:urls][0][:expanded_url])
      delete_resnum(url)
      list = @mongo_client.get(:url => url)
      if !list.nil? && list.size > 0
        data = list[0]
        data['favorite'] = (data['favorite'] || 0) + 1
        @mongo_client.put(data, :url => url)
        syslog.info("Favorite by #{name}")
        syslog.info("Total favorites in #{url}: #{data['favorite']}")
      else
        syslog.error("Favorite data can not get from mongolab: " + url)
      end
    end

    def unfavorite(status)
      name = status[:source][:screen_name]
      url = decode_url(status[:target_object][:entities][:urls][0][:expanded_url])
      delete_resnum(url)
      list = @mongo_client.get(:url => url)
      if !list.nil? && list.size > 0
        data = list[0]
        data['favorite'] = data['favorite'] - 1
        @mongo_client.put(data, :url => url)
        syslog.info("Unfavorite by #{name}")
        syslog.info("Total favorites in #{url}: #{data['favorite']}")
      else
        syslog.error("Unfavorite data can not get from mongolab: " + url)
      end
    end

    def create_client(params)
      Twitter::REST::Client.new do |config|
        config.consumer_key        = params['consumer_key']
        config.consumer_secret     = params['consumer_secret']
        config.access_token        = params['oauth_token']
        config.access_token_secret = params['oauth_token_secret']
      end
    end

    def create_stream_client(params)
      TweetStream.configure do |config|
        config.consumer_key       = params['consumer_key'],
        config.consumer_secret    = params['consumer_secret'],
        config.oauth_token        = params['oauth_token'],
        config.oauth_token_secret = params['oauth_token_secret'],
        config.auth_method        = :oauth
      end
      TweetStream::Daemon.new
    end
  end
end
