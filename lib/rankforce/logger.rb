require 'log4r'
require 'log4r/evernote'

module RankForce
  class Logger
    def self.method_missing(name, *args)
      if /(.*?)=$/ =~ name
        class_variable_set("@@#{$1}", args[0])
      end
    end
  
    def self.name=(name); @@name = name end
  
    def self.level=(level); @@level = level end
  
    def self.formatter=(formatter); @@formatter = formatter end
  
    def self.formatter
      Log4r::PatternFormatter.new(
        :pattern => "[%l] %d: %M",
        :date_format => "%Y/%m/%d %H:%M:%Sm"
      )
    end
  
    def self.syslog
      @@logger ||= {}
      return @@logger[:system] if @@logger.key?(:system)
      raise "auth token is empty." if @@auth_token.nil?
      @@logger[:system] = logger(Log4r::EvernoteOutputter.new('rankforce.system', {
        :auth_token => @@auth_token,
        :stack => "Log4ever",
        :notebook => "rankforce.system",
        :tags => ['Log', 'RankForce', 'RankForce(SystemLog)'],
        :shift_age => Log4ever::ShiftAge::DAILY,
        :formatter => formatter
      }))
      @@logger[:system]
    end
  
    def self.datalog
      @@logger ||= {}
      return @@logger[:data] if @@logger.key?(:data)
      raise "auth token is empty." if @@auth_token.nil?
      @@logger[:data] = logger(Log4r::EvernoteOutputter.new('rankforce.data', {
        :auth_token => @@auth_token,
        :stack => "Log4ever",
        :notebook => "rankforce.data",
        :tags => ['Log', 'RankForce', 'RankForce(DataLog)'],
        :shift_age => Log4ever::ShiftAge::DAILY,
        :formatter => formatter
      }))
      @@logger[:data]
    end
  
    def self.logger(*outputters)
      logger = Log4r::Logger.new(@@name)
      logger.level = @@level
      logger.outputters = []
      logger.outputters << Log4r::StdoutOutputter.new('console', {
          :formatter => formatter
      })
      outputters.each do |outputter|
        logger.outputters << outputter
      end
      logger
    end
  end
end