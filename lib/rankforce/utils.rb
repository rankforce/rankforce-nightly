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
      url.gsub(/\/&res=\d+/, '') unless url.nil?
    end

    def delete_copy(title)
      title.gsub(/\u00A92ch\.net/, '')
           .gsub(/\[\u8EE2\u8F09\u7981\u6B62\]/, '')
           .gsub(/\[\d+\]/, '')
           .strip unless title.nil?
    end

    def add_resnum(url, n)
      "#{url}/&res=#{n}"
    end

    def decode_url(str)
      httpclient = HTTPClient.new
      url = httpclient.get(str).headers['Location']
      url.chop! if /\/$/ =~ url
      url
    end
  end
end
