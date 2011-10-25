require 'cgi'
require 'json'
require 'threaded-each'

module JsonResult
  class JsonError < StandardError; end

  RPC="http://aur.archlinux.org/rpc.php"
  KEY='result'

  # abstract, must be implemented by the subclass
  def self.from_json_result(*args); nil end

  def self.json_url(type, term)
    case type
    when :search  : "#{RPC}?type=search#{  single_search_arg(term)}"
    when :info    : "#{RPC}?type=multiinfo#{multi_search_arg(term)}"
    when :pkgbuild: "#{RPC}?type=multiinfo#{multi_search_arg(term)}"
    else nil
    end
  end

  # downloads json_url and parses as json
  def self.init_from_json
    results = []

    # unable to determine url
    return results unless url = self.json_url

    resp = Net::HTTP.get_response(URI.parse(url))
    json = JSON.parse(resp.body)

    # no results key
    return results unless json.has_key?(KEY) 

    # not a non-empty array or results
    return results if (jresults = json[KEY]).class != Array 
    return results if jresults.empty

    jresults.threaded_each do |result|
      # caller can filter by passing a block
      next if block_given? && !yield result
      r = self.from_json_result(result)
      results << r if r
    end

    results

  rescue => e
    raise JsonError, e.message
  end

  private

  def single_search_arg(term)
    '&arg=' + CGI::escape(term)
  end

  def multi_search_arg(term)
    term.split(' ').collect { |t|
      '&arg[]=' + CGI::escape(t)
    }.join
  end
end
