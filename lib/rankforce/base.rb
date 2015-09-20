# -*- coding: utf-8 -*-
require 'rankforce/consts'
require 'rankforce/utils'
require 'mechanize'
require 'httpclient'
require 'json'

module RankForce
  class Base
    include RankForce::Consts
    include RankForce::Utils

    def initialize(config = {})
      @@debug = config[:test]
      Logger.auth_token = evernote_auth_token
      Logger.name       = 'RankForce'
      Logger.level      = @@debug ? 1 : 2 # 1=DEBUG, 2=INFO
    end

    def validate(name, ikioi, time)
      raise ArgumentError, "Undefined board name: #{name}" unless boards.key?(name)
      raise ArgumentError, "Illegal ikioi value: #{ikioi}" unless ikioi.to_i > 0
      unless /^([0-9]|0[0-9]|1[0-9]|2[0-3]):([0-5][0-9])$|^(\d+)$/ =~ time.to_s
        raise ArgumentError, "Illegal time format: #{time}"
      end
      true
    end

    def boards
      return @boards unless @boards.nil?
      file_ja = "#{BOARD_ROOT}/#{BOARD_FILE_JA}"
      file_en = "#{BOARD_ROOT}/#{BOARD_FILE_EN}"
      list_ja = []
      list_en = []
      File.open(file_ja, 'r:utf-8') do |f|
        while line = f.gets
          list_ja << line.strip
        end
      end
      File.open(file_en, 'r:utf-8') do |f|
        while line = f.gets
          list_en << line.strip
        end
      end
      @boards = Hash[*([list_en, list_ja].transpose).flatten]
    end

    def load_ngword
      ngwords = []
      File.open("#{CONFIG_ROOT}/#{NGWORD}", 'r:utf-8') do |f|
        f.each_line do |line|
          ngwords << line.strip unless line.empty?
        end
        return f.read.strip
      end
      ngwords
    end

    def evernote_auth_token
      path = File.dirname(__FILE__) + "/../../config/evernote.auth.yml"
      load_config(path, 'auth_token')
    end

    def to_short(url)
      path = File.dirname(__FILE__) + "/../../config/bitly.auth.yml"
      access_token = load_config(path, 'access_token')
      response = HTTPClient.new.get_content(SHORT_URL % [access_token, url])
      json = JSON.parse(response)
      json['status_code'] == 200 ? json['data']['url'] : url
    end

    def minute?(n)
      /^\d+$/ =~ n.to_s
    end

    def clock?(n)
      /^([0-9]|0[0-9]|1[0-9]|2[0-3]):([0-5][0-9])$/ =~ n.to_s
    end
  end
end
