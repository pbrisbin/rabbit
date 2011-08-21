require 'cgi'
require 'json'
require 'net/http'

require_relative 'package'

AUR       = "http://aur.archlinux.org"
AURSEARCH = AUR + "/rpc.php?type=search&arg="
AURINFO   = AUR + "/rpc.php?type=info&arg="

class AurSearch
  attr_reader :results, :type

  def initialize term, type = :search
    @type    = type
    @results = Array.new

    case @type
    when :search
      j = get_json(AURSEARCH + CGI::escape(term))
      if has_results? j
        j['results'].each do |result|
          @results << Package.new(result)
        end
      end
    when :info
      j = get_json(AURINFO + CGI::escape(term))
      @results << Package.new(j['results']) if has_results? j
    end
  end

  def show_results
    @results.each do |pkg|
      case @type
      when :search
        puts "aur/#{pkg.name} #{pkg.version}#{pkg.outofdate ? ' [out of date]' : ''}"
        puts "    #{pkg.description}"
      when :info
        puts "Repository      : aur"
        puts "Name            : #{pkg.name}"
        puts "Version         : #{pkg.version}"
        puts "URL             : #{pkg.url}"
        puts "Out of date     : #{pkg.outofdate ? 'Yes' : 'No'}"
        puts "Description     : #{pkg.description}"
      end
    end
  end

  private

  def get_json url
    r = Net::HTTP.get_response(URI.parse(url))
    j = JSON.parse(r.body)
    return j
  end

  def has_results? j
    return false unless j.has_key? 'results'
    return false unless j['results'] != "No results found"
    return true
  end
end
