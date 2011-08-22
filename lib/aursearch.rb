require 'cgi'
require 'json'
require 'net/http'

require_relative 'package'

AUR       = "http://aur.archlinux.org"
AURSEARCH = AUR + "/rpc.php?type=search&arg="
AURINFO   = AUR + "/rpc.php?type=info&arg="

class AurSearch
  attr_reader :results

  def initialize term, type = :search
    @type    = type
    @results = Array.new

    # add argument to results array
    l = lambda { |name| @results << Package.new(name) }

    case @type
      when :search
        j = get_json(AURSEARCH + CGI::escape(term))
        j['results'].each &l if j.has_results?

      when :info
        j = get_json(AURINFO + CGI::escape(term))
        l.call j['results'] if j.has_results?
    end
  end

  def show_results
    @results.each do |pkg|
      case @type
        when :search
          puts "aur/#{pkg.name} #{pkg.version}#{pkg.outofdate ? ' [out of date]' : ''}",
               "    #{pkg.description}"
        when :info
          puts "Repository      : aur",
               "Name            : #{pkg.name}",
               "Version         : #{pkg.version}",
               "URL             : #{pkg.url}",
               "Out of date     : #{pkg.outofdate ? 'Yes' : 'No'}",
               "Description     : #{pkg.description}",
      end
    end
  end

  private

  def get_json url
    r = Net::HTTP.get_response(URI.parse(url))
    j = JSON.parse(r.body)

    def j.has_results? # add a singleton helper
      has_key? 'results' and ['results'] != "No results found"
    end

    return j
  end
end
