# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/../core/lib"
require 'rankforce'
require 'rankforce/base'
require 'optparse'

OptionParser.new.parse!(ARGV)
rankforce = RankForce::Runner.new
rankforce.run_stream(ARGV[0])
