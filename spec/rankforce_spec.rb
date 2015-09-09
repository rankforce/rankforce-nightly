# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/../lib"
require File.expand_path(File.dirname(__FILE__) + '/../spec/spec_helper')
include RankForceTest

describe RankForce do
  describe '板名変換' do
    it '日本語の板名から英語の板名に変換できること' do
      board = RankForce::Board.new
      board_test_data.each do |en, ja|
        expect(en).to eq(board.to_en(ja))
      end
    end

    it '英語の板名から日本語の板名に変換できること' do
      board = RankForce::Board.new
      board_test_data.each do |en, ja|
        expect(ja).to eq(board.to_ja(en))
      end
    end
  end

  describe 'URL短縮' do
    it 'URL短縮が実行出来ること' do
      base = RankForce::Base.new
      expect(base.to_short("http://www.yahoo.co.jp")).to match(/bit.ly/)
    end
  end

  describe 'クローラ処理' do
    it 'スレ情報を取得できること' do
      board = 'newsplus'
      crawler = RankForce::Crawler.new(board, 1000)
      crawler.get do |data|
        expect(data[:ikioi]).to be_a_kind_of(Fixnum)
        expect(data[:title]).not_to be_nil
        expect(data[:board]).to eq(board)
        expect(data[:url]).to match(/http:\/\/.*?/)
        expect(data[:created_at]).not_to be_nil
      end
    end
  end

  describe 'Twitter処理' do
    before do
      @tweet = RankForce::Tweet.new("twitter.auth.test.yml")
      @data = {
        :board => "テスト",
        :title => Time.now.to_s,
        :ikioi => "10000",
        :url   => "http://www.yahoo.co.jp"
      }
    end

    it 'ツイートできること' do
      expect(@tweet.post(@data)).to be_truthy
    end
  end

  describe 'MongoLab登録処理' do
    before do
      @client = RankForce::MongoClient.new("mongolab.test.yml")
    end

    it 'クローラから取得したデータ形式からMongoLabに保存するスキーマ形式のデータに変換できること' do
      data = @client.create_post_data(data_from_2ch)
      expect(data[:url]).to be_a_kind_of(String)
      expect(data[:ikioi]).to be_a_kind_of(Hash)
      expect(data[:ikioi][:average]).to be_a_kind_of(Fixnum)
      expect(data[:ikioi][:max]).to be_a_kind_of(Fixnum)
      expect(data[:ikioi][:min]).to be_a_kind_of(Fixnum)
      expect(data[:ikioi][:history]).to be_a_kind_of(Array)
      expect(data[:ikioi][:history][0]).to be_a_kind_of(Fixnum)
      expect(data[:title]).to be_a_kind_of(String)
      expect(data[:date]).to be_a_kind_of(Hash)
      expect(data[:date][:created_at]).to be_a_kind_of(Time)
      expect(data[:date][:updated_history]).to be_a_kind_of(Array)
      expect(data[:date][:updated_history][0]).to be_a_kind_of(Time)
      expect(data[:board]).to be_a_kind_of(String)
    end

    it 'POSTが成功すること' do
      data = @client.create_post_data(data_from_2ch)
      data[:url] += "/" + Time.now.to_i.to_s
      expect(@client.post(data)).to be_truthy
    end

    it 'GETが成功すること' do
      data = @client.create_post_data(data_from_2ch)
      data[:url] += "/" + Time.now.to_i.to_s
      @client.post(data)
      expect(@client.get({:url => data[:url]})).not_to be_empty
    end

    it 'PUTが成功すること' do
      data = @client.create_post_data(data_from_2ch)
      data[:url] += "/" + Time.now.to_i.to_s
      @client.post(data)
      data = @client.get({:url => data[:url]})
      url = data_from_2ch[:url] + "/" + Time.now.to_i.to_s
      data[0]['url'] = url
      expect(@client.put(data[0], {:_id => data[0]['_id']})).to be_truthy
      expect(@client.get({:url => url})).not_to be_empty
    end

    it 'PUTを実行すると勢いと日付が更新されること' do
      path = "/" + Time.now.to_i.to_s
      data = data_from_2ch
      data[:url] += path
      # post
      @client.save(data)
      # put
      @client.save(data)
      expect(@client.get({:url => data[:url]})).not_to be_empty
    end
  end
end
