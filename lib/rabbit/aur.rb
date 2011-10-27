require 'rabbit/json'

module Rabbit
  module Aur
    extend Json

    def self.search(term)
      sorted_results(url_for_search(term)) do |result|
        out_of_date = result['OutOfDate'] == '1' ? ' [out of date]' : ''

        puts "aur/#{result['Name']} #{result['Version']}#{out_of_date}",
             "    #{result['Description']}"
      end
    end

    def self.info(terms)
      sorted_results(url_for_info(terms)) do |result|
        out_of_date = result['OutOfDate'] == '1' ? 'Yes' : 'No'

        puts "Repository      : aur",
             "Name            : #{result['Name']}",
             "Version         : #{result['Version']}",
             "URL             : #{result['URL']}",
             "Out of date     : #{out_of_date}",
             "Description     : #{result['Description']}",
             ""
      end
    end

    private

    def self.sorted_results(url)
      results = []

      fetch_json(url) do |result|
        results << result
      end

      return if results.empty?

      if results.length == 1
        yield results.first
      else
        results.sort_by { |r| r['Name'] }.each do |r|
          yield r
        end
      end
    end
  end
end
