require 'cgi'
require 'json'
require 'net/http'

require_relative 'errors'

class Aur
  URL = "http://aur.archlinux.org"

  def self.search term
    begin
      call_rpc(:search, term) do |result|
        outofdate = result['OutOfDate'] == '1' ? ' [out of date]' : ''

        puts "aur/#{result['Name']} #{result['Version']}#{outofdate}",
             "    #{result['Description']}"
      end

    rescue RabbitNotFoundError
      # ignore
    end
  end

  def self.info term
    begin
      call_rpc(:multiinfo, term) do |result|
        outofdate = result['OutOfDate'] == '1' ? 'Yes' : 'No'

        puts "Repository      : aur",
             "Name            : #{result['Name']}",
             "Version         : #{result['Version']}",
             "URL             : #{result['URL']}",
             "Out of date     : #{outofdate}",
             "Description     : #{result['Description']}",
             ""
      end

    rescue RabbitNotFoundError
      # ignore
    end
  end

  def self.pkgbuild term
    call_rpc(:multiinfo, term) do |result|
      begin
        url  = URL + File.dirname(result['URLPath']) + '/PKGBUILD'
        resp = Net::HTTP.get_response(URI.parse(url))
        if block_given?
          yield resp.body
        else
          puts resp.body, ''
        end
      rescue
        # ignore
      end
    end
  end

  def self.call_rpc type, term, &block
    url = case type
      when :search
        "#{URL}/rpc.php?type=search&arg=#{CGI::escape(term)}"
      when :multiinfo
        arg = term.split(' ').collect { |t| "&arg[]=" + CGI::escape(t) }.join
        "#{URL}/rpc.php?type=multiinfo#{arg}"
      else
        raise RabbitError, "Invalid search type #{type}"
      end

    begin
      resp = Net::HTTP.get_response(URI.parse(url))
      json = JSON.parse(resp.body)
    rescue
      json = nil
    end

    if json && json.has_key?('results') && json['results'].class == Array
      if block_given?
        json['results'].sort { |a,b| a['Name'] <=> b['Name'] }.each &block
      end

      json
    else
      raise RabbitNotFoundError, "No results round"
    end
  end
end
