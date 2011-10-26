require 'rabbit/json'

module AurSearch
  AUR = "http://aur.archlinux.org"

  class SearchResult
    extend JsonResult

    attr_accessor :repo, :name, :version, :description, :url, :url_path, :out_of_date

    def self.from_json_result(result)
      sresult = new
      sresult.repo        = 'aur'
      sresult.name        = result['Name']
      sresult.version     = result['Version']
      sresult.description = result['Description']
      sresult.url         = result['URL']
      sresult.url_path    = result['URLPath']
      sresult.out_of_date = result['OutOfDate'] == '1'
      sresult
    end

    def show_in_search
      puts "#{repo}/#{name} #{version}#{out_of_date ? ' [out of date]' : ''}",
           "    #{description}"
    end

    def show_in_info
      puts "Repository      : #{repo}",
           "Name            : #{name}",
           "Version         : #{version}",
           "URL             : #{url}",
           "Out of date     : #{out_of_date ? 'Yes' : 'No'}",
           "Description     : #{description}",
           ""
    end

    def show_in_pkgbuild
      url  = "#{AUR}#{File.dirname(url_path)}/PKGBUILD"
      resp = Net::HTTP.get_response(URI.parse(url))
      puts resp.body
    rescue
    end
  end

  def self.execute_search(type, term)
    results = SearchResult.init_from_json(type, term)
    results.sort_by { |r| r.name }.each do |r|
      r.send(:"show_in_#{type}")
    end
  end
end
