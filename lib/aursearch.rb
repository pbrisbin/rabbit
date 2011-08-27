require 'cgi'
require 'json'
require 'net/http'

AUR = "http://aur.archlinux.org"

class AurSearch
  # executes a search. if multiple terms are passed, they are joined
  # with a space and encoded as a single search argument
  def self.search term
    begin
      call_rpc(:search, *term) do |result|
        outofdate = result['OutOfDate'] == '1' ? ' [out of date]' : ''

        puts "aur/#{result['Name']} #{result['Version']}#{outofdate}",
             "    #{result['Description']}"
      end

    rescue RabbitNotFoundError
      # ignore
    end
  end

  # prints info for the passed packages
  def self.info term
    begin
      call_rpc(:multiinfo, *term) do |result|
        outofdate = result['OutOfDate'] == '1' ? 'Yes' : 'No'

        puts "Repository      : aur",
             "Name            : #{result['Name']}",
             "Version         : #{result['Version']}",
             "URL             : #{result['URL']}",
             "Out of date     : #{outofdate}",
             "Description     : #{result['Description']}",
             ""
      end

    rescue RabbitNotFoundError => e
      # ignore
    end
  end

  # print the pkgbuild for the passed packages
  def self.pkgbuild *term
    call_rpc(:multiinfo, *term) do |result|
      begin
        url  = AUR + File.dirname(result['URLPath']) + '/PKGBUILD'
        resp = Net::HTTP.get_response(URI.parse(url))
        puts resp.body, ''
      rescue
        # ignore
      end
    end
  end

  private

  def self.call_rpc type, *term, &block
    url = case type
      when :search
        "#{AUR}/rpc.php?type=search&arg=#{CGI::escape(term.join(" "))}"
      when :multiinfo
        arg = term.collect { |t| "&arg[]=" + CGI::escape(t) }.join
        "#{AUR}/rpc.php?type=multiinfo#{arg}"
    end

    begin
      resp = Net::HTTP.get_response(URI.parse(url))
      json = JSON.parse(resp.body)
    rescue
      json = nil
    end

    if json && json.has_key?('results') && json['results'].class == Array
      json['results'].sort { |a,b| a['Name'] <=> b['Name'] }.each &block
    else
      raise RabbitNotFoundError, "No results round"
    end
  end
end
