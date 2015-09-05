require 'yaml'
require 'httpclient'
require 'rankforce/logger'

module RankForce
  module Utils
    def logger; Logger.datalog end
    def syslog; Logger.syslog end
  
    def load_config(file, config_key = nil)
      obj = File.exist?(file) ? YAML.load_file(file) : ENV
      config_key.nil? ? obj : obj[config_key]
    end

    def delete_resnum(url)
      url.gsub!(/\/&res=\d+/, '')
    end

    def add_resnum(url, n)
      "#{url}/&res=#{n}"
    end

    def decode_url(str)
      httpclient = HTTPClient.new
      httpclient.get(str).headers['Location']
    end
  end
end