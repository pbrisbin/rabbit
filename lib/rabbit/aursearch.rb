require 'cgi'
require 'json'
require 'net/http'

module AurSearch
  AUR = "http://aur.archlinux.org"

  class NotFoundError < StandardError; end

  class SearchResult
    attr_accessor :repo, :name, :version, :description, :url, :url_path, :out_of_date

    # returns an array of SearchResults
    def self.init_from_json(json)
      if json.has_key?('results') && json['results'].class == Array && !json['results'].empty?
        sresults = json['results'].map do |result|
          sresult = SearchResult.new

          sresult.repo        = 'aur'
          sresult.name        = result['Name']
          sresult.version     = result['Version']
          sresult.description = result['Description']
          sresult.url         = result['URL']
          sresult.url_path    = result['URLPath']
          sresult.out_of_date = result['OutOfDate'] == '1'

          sresult
        end
      else
        raise NotFoundError
      end

      sresults
    end

    def show_in_search
      puts "#{@repo}/#{@name} #{@version}#{@out_of_date ? ' [out of date]' : ''}",
           "    #{@description}"
    end

    def show_in_info
      puts "Repository      : #{@repo}",
           "Name            : #{@name}",
           "Version         : #{@version}",
           "URL             : #{@url}",
           "Out of date     : #{@out_of_date ? 'Yes' : 'No'}",
           "Description     : #{@description}",
           ""
    end

    def show_in_pkgbuild
      with_pkgbuild { |pkgbuild| puts pkgbuild, '' }
    end

    def with_pkgbuild
      url  = "#{AUR}#{File.dirname(@url_path)}/PKGBUILD"
      resp = Net::HTTP.get_response(URI.parse(url))
      yield resp.body
    rescue
      # ignore   
    end
  end

  def self.json_request_url(type, term)
    if type == :info || type == :pkgbuild
      arg = term.split(' ').collect { |t| "&arg[]=" + CGI::escape(t) }.join
      url = "#{AUR}/rpc.php?type=multiinfo#{arg}"
    elsif type == :search
      url = "#{AUR}/rpc.php?type=search&arg=#{CGI::escape(term)}"
    else
      url = nil
    end

    url

  rescue
    nil
  end

  def self.with_json_response(url)
    resp   = Net::HTTP.get_response(URI.parse(url))
    json   = JSON.parse(resp.body)
    result = yield json

    result

  rescue NotFoundError => e
    raise e
  rescue
    nil
  end
end
