module Rabbit
  module Search
    extend Json

    # search the aur for a search term. prints the results directly.
    def self.search(term)
      results = sorted_results(url_for_search(term))
      results.each do |result|
        out_of_date = result.OutOfDate == '1' ? ' [out of date]' : ''

        puts "aur/#{result.Name} #{result.Version}#{out_of_date}",
             "    #{result.Description}"
      end
    end

    # fetch info for each package name. prints the results directly.
    def self.info(pkg_names)
      results = sorted_results(url_for_info(pkg_names))
      results.each do |result|
        out_of_date = result.OutOfDate == '1' ? 'Yes' : 'No'

        puts "Repository      : aur",
             "Name            : #{result.Name}",
             "Version         : #{result.Version}",
             "URL             : #{result.URL}",
             "Out of date     : #{out_of_date}",
             "Description     : #{result.Description}",
             ""
      end
    end

    private

    def self.sorted_results(url)
      results = fetch_json(url)
      return results if results.length <= 1
      results.sort_by { |r| r.Name }.each 
    end
  end
end
