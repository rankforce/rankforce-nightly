# -*- coding: utf-8 -*-
require 'rankforce/consts'

module RankForce
  class Board
    include RankForce::Consts

    def initialize
      @en = []
      @ja = []
      File::open("#{BOARD_ROOT}/#{BOARD_FILE_EN}", 'r:utf-8') do |file|
        while l = file.gets
          @en << l.strip
        end
      end
      File::open("#{BOARD_ROOT}/#{BOARD_FILE_JA}", 'r:utf-8') do |file|
        while l = file.gets
          @ja << l.strip
        end
      end
    end

    def to_en(str)
      i = @ja.index(str)
      i.nil? ? nil : @en[i]
    end

    def to_ja(str)
      i = @en.index(str)
      i.nil? ? nil : @ja[i]
    end

    def en; @en end
    def ja; @ja end
  end
end
