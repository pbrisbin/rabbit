require 'cgi'
require 'json'
require 'net/http'
require 'threaded-each'

module JsonResult
  RPC='http://aur.archlinux.org/rpc.php'
  KEY='results'

  def json_url(type, term)
    return "#{RPC}?type=multiinfo#{multi_search_arg(term)}" if [:info, :pkgbuild].include?(type)
    return "#{RPC}?type=search#{single_search_arg(term)}"   if type == :search

    nil
  end

  # downloads json_url and parses as json, results are discarded if a
  # block is given which returns false for the result hash. finally,
  # from_json_result is called and its result added to the return array.
  def init_from_json(*args)
    results = []

    # unable to determine url
    return results unless url = json_url(*args)

    resp = Net::HTTP.get_response(URI.parse(url))
    json = JSON.parse(resp.body)

    # no results
    return results unless json.has_key?(KEY) 
    return results if (jrs = json[KEY]).class != Array 
    return results if jrs.empty?

    jrs.threaded_each do |jr|
      next if block_given? && !yield(jr)
      result = from_json_result(jr)
      results << result if result
    end

    results
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
