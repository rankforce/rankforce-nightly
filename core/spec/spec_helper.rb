# -*- coding: utf-8 -*-
require 'rspec'
require File.dirname(__FILE__) + "/../lib/rankforce"
require File.dirname(__FILE__) + "/../lib/rankforce/base"
require File.dirname(__FILE__) + "/../lib/rankforce/crawler"
require File.dirname(__FILE__) + "/../lib/rankforce/tweet"
require File.dirname(__FILE__) + "/../lib/rankforce/board"
require File.dirname(__FILE__) + "/../lib/rankforce/limit_manager"
require File.dirname(__FILE__) + "/../lib/rankforce/utils"
require File.dirname(__FILE__) + "/../lib/rankforce/mongo_client"

module RankForceTest
  include RankForce::Utils
  TEST_CONFIG_ROOT = File.dirname(__FILE__) + "/config"

  def load_board_confg(file)
    load_config("#{TEST_CONFIG_ROOT}/#{file}")
  end

  def board_test_data
    {'bakanews' => 'バカニュース',
     'geino' => '芸能',
     'goldenfish' => '日本の淡水魚'}
  end

  def data_from_2ch
    {
      :ikioi      => rand(8000) + 4000,
      :title      => "test title",
      :url        => "http://www.yahoo.co.jp",
      :board      => "newsplus",
      :created_at => Time.now
    }
  end
end