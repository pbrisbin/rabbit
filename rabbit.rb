#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby. this is only a toy.
#
###

require_relative 'lib/aursearch'
require_relative 'lib/config'
require_relative 'lib/package'

Signal.trap("INT") { exit 1 }

$config = Config.load_from_file

class Rabbit
  include AurSearch

  def self.execute_search(type, term)
    url = AurSearch.json_request_url(type, term)

    if url
      AurSearch.with_json_response(url) do |json|
        results = SearchResult.init_from_json(json)
        results.each { |result| result.send(:"show_in_#{type}") }
      end
    end

  rescue NotFoundError
    $stderr.puts 'No results found'
    exit 1

  rescue => e
    $stderr.puts e.fullmessage
    exit 1
  end
end

case ARGV.shift
  when '-Ss'; Rabbit.execute_search(:search  , ARGV.join(' '))
  when '-Si'; Rabbit.execute_search(:info    , ARGV.join(' '))
  when '-Sp'; Rabbit.execute_search(:pkgbuild, ARGV.join(' '))

  #when '-S' ; Package.install ARGV
  #when '-Su'; Package.update
end
