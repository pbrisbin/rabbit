module Rabbit
  module Json
    KEY = 'results'

    class Result
      def initialize(hsh)
        @hsh = hsh
      end

      def method_missing(meth, *args)
        return @hsh[meth.to_s] rescue nil
      end
    end

    def fetch_json(url, &block)
      require 'net/http'
      require 'json'

      resp = Net::HTTP.get_response(URI.parse(url))
      json = JSON.parse(resp.body)

      return [] unless json.has_key?(KEY) 
      return [] unless (jrs = json[KEY]).is_a?(Array)
      return [] if jrs.empty?

      results = []

      jrs.threaded_each do |jr|
        result = block_given? ? (yield jr) : jr
        results << Result.new(result) if result
      end

      results
    end

    def url_for_search(term)
      require 'cgi'

      'http://aur.archlinux.org/rpc.php' +
        '?type=search&arg=' + CGI::escape(term)
    end

    def url_for_info(terms)
      require 'cgi'

      'http://aur.archlinux.org/rpc.php?type=multiinfo' +
        terms.collect { |t| '&arg[]=' + CGI::escape(t) }.join
    end
  end
end
