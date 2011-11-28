module Rabbit
  module Search
    extend Json

    # search the aur for a search term. prints the results directly.
    def self.search(term)
      results = fetch_json(url_for_search(term)).sort_by(&:Name)
      results.each do |result|
        out_of_date = result.OutOfDate == '1' ? ' [out of date]' : ''

        puts "aur/#{result.Name} #{result.Version}#{out_of_date}",
             "    #{result.Description}"
      end
    end

    # fetch info for each package name. prints the results directly.
    def self.info(pkg_names)
      results = fetch_json(url_for_info(pkg_names)).sort_by(&:Name)
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
  end
end
