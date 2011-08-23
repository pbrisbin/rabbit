require 'cgi'
require 'json'
require 'net/http'

AUR = "http://aur.archlinux.org"

class AurSearch
  def self.search *term
    call_rpc(:search, *term) do |result|
      outofdate = result['OutOfDate'] == '1' ? ' [out of date]' : ''

      puts "aur/#{result['Name']} #{result['Version']}#{outofdate}",
           "    #{result['Description']}"
    end
  end

  def self.info *term
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
  end

  private

  def self.call_rpc type, *term, &block
    url = case type
      when :search
        "#{AUR}/rpc.php?type=search&arg=#{CGI::escape(term.join(" "))}"
      when :multiinfo
        term.collect! { |t| "&arg[]=" + CGI::escape(t) }
        "#{AUR}/rpc.php?type=multiinfo#{term.join}"
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
      STDERR.puts "No results round"
    end
  end
end
