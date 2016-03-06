# -*- coding: utf-8 -*-
require 'rankforce/consts'
require 'net/https'
require 'json'

module RankForce
  class MongoClient
    include RankForce::Consts
    include RankForce::Utils

    HOST = 'api.mongolab.com'
    PATH = '/api/1/databases/%s/collections/%s'

    def initialize(file)
      # ActiveSupport::JSON.backend = 'JSONGem'
      config     = load_config("#{CONFIG_ROOT}/#{file}")
      database   = config['database']
      collection = config['collection']
      @apikey    = config['apikey']
      @path      = PATH % [database, collection]
      @header    = {'Content-Type' => "application/json"}
    end

    def save(data)
      saved_data = get({:url => data[:url]})
      if saved_data.nil? || saved_data.empty?
        data = create_post_data(data)
        if post(data)
          syslog.debug("POST success.")
          syslog.debug("POST data: #{data['title']}")
          yield if block_given?
        else
          raise ArgumentError, "post failure. invalid data: #{data.to_s}"
        end
      else
        data = create_put_data(saved_data[0], data)
        if data.nil?
          syslog.debug("History size has reached limit.")
        else
          if put(data, {:_id => saved_data[0]['_id']})
            syslog.debug("PUT success.")
            syslog.debug("PUT data: #{data['title']}")
          else
            raise ArgumentError, "put failure. invalid data: #{data.to_s}"
          end
        end
      end
    end

    def https_start
      Net::HTTP.version_1_2
      https = Net::HTTP.new(HOST, 443)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      https.start { yield https }
    end

    def get(cond)
      https_start do |https|
        JSON.parse(https.get(@path + "?apiKey=#{@apikey}&q=" + cond.to_json).body)
      end
    end

    def post(data)
      https_start do |https|
        https.post(@path + "?apiKey=#{@apikey}", data.to_json, @header).code == "200"
      end
    end

    def put(data, cond)
      https_start do |https|
        https.put(@path + "?apiKey=#{@apikey}&q=" + cond.to_json, data.to_json, @header).code == "200"
      end
    end

    def delete; end

    def create_post_data(data)
      {
        :url => data[:url],
        :ikioi => {
          :average => data[:ikioi],
          :max => data[:ikioi],
          :min => data[:ikioi],
          :history => [data[:ikioi]]
        },
        :title => data[:title],
        :date => {
          :created_at => data[:created_at],
          :updated_history => [Time.now]
        },
        :board => data[:board],
        :retweet => 0,
        :favorite => 0
      }
    end

    def create_put_data(saved_data, new_data)
      ikioi_history = saved_data['ikioi']['history']
      if HISTORY_SIZE > ikioi_history.size
        ikioi_history << new_data[:ikioi]
        saved_data['ikioi'] = {
          :average => ikioi_history.inject(0) {|r, i| r += i} / ikioi_history.size,
          :max => ikioi_history.max,
          :min => ikioi_history.min,
          :history => ikioi_history
        }
        saved_data['date']['updated_history'] << Time.now
        saved_data
      end
    end
  end
end
