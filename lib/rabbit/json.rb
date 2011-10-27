require 'cgi'
require 'json'
require 'net/http'
require 'threaded-each'

module Rabbit
  module Json
    KEY='results'

    def fetch_json(url)
      results = []

      resp = Net::HTTP.get_response(URI.parse(url))
      json = JSON.parse(resp.body)

      return results unless json.has_key?(KEY) 
      return results if (jrs = json[KEY]).class != Array 
      return results if jrs.empty?

      jrs.threaded_each do |jr|
        result = yield jr
        results << result if result
      end

      results
    end

    def url_for_search(term)
      'http://aur.archlinux.org/rpc.php' +
        '?type=search&arg=' + CGI::escape(term)

    end

    def url_for_info(terms)
      'http://aur.archlinux.org/rpc.php?type=multiinfo' +
        terms.collect { |t| '&arg[]=' + CGI::escape(t) }.join
    end
  end
end
