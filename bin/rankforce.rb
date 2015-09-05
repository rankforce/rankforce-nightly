# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/../core/lib"
require 'rankforce'
require 'rankforce/base'
require 'optparse'
require 'thread'
require 'clockwork'
include Clockwork

config = {:test => false}
OptionParser.new do |opt|
  opt.on('-t', '--test') {|boolean| config[:test] = boolean}   # test mode
  opt.on('-v', '--version') {puts RankForce::VERSION; exit}    # version
  opt.parse!
end

rankforce = RankForce::Runner.new(config)
# rankforce_stream
rankforce.run_background('start')

# rankforce
rankforce.load do |board, ikioi, time|
  handler do |job|
    Thread.new { rankforce.run(board, ikioi) }
  end
  # Is time format "minutes" or "clock"?
  if rankforce.minute?(time)
    every(time.to_i.minutes, board)
  elsif rankforce.clock?(time)
    every(1.day, board, :at => time)
  end
end
