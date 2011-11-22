module Rabbit
  module Json
    KEY = 'results'

    # a single search result with methods representing the keys of the
    # json hash returned from the AURs rpc function.
    class Result
      def initialize(hsh)
        @hsh = hsh
      end

      def method_missing(meth, *args)
        return @hsh[meth.to_s] rescue nil
      end
    end

    # fetch the json for the given url and retun an Array of Result
    # objects. if block is given, each json hash is yielded to it before
    # creating the Result object -- return nil or false to exclude it
    # from the returned results (i.e. when checking for updates).
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

    # aur's search rpc url for the given search term.
    def url_for_search(term)
      require 'cgi'

      'http://aur.archlinux.org/rpc.php' +
        '?type=search&arg=' + CGI::escape(term)
    end

    # aur's info rpc url for the given array of package names.
    def url_for_info(terms)
      require 'cgi'

      'http://aur.archlinux.org/rpc.php?type=multiinfo' +
        terms.collect { |t| '&arg[]=' + CGI::escape(t) }.join
    end
  end
end
