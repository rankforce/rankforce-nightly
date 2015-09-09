require 'thread'
require 'rankforce/consts'

module RankForce
  class LimitManager
    include RankForce::Consts
    include RankForce::Utils

    def initialize
      @mutex = Mutex.new
      init_tweet_limit
    end

    def run
      @mutex.synchronize do
        if tweetable?
          yield @tweet_count, @limit_date.to_s if block_given?
        else
          syslog.debug("Reached tweet limit. couny by #{@tweet_count}")
        end
      end
    end

    def tweetable?
      init_tweet_limit if Time.now > @limit_date
      TWEET_LIMIT > @tweet_count + 1 & add_count
    end

    def init_tweet_limit
      @tweet_count = 0
      @limit_date = Time.now + TWEET_LIMIT * 60
    end

    def add_count
      @tweet_count += 1
    end
  end
end
