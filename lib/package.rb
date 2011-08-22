#
# rabbit support file.
#
###
require 'find'
require 'open-uri'

require_relative 'aursearch'

class Package
  attr_reader :name, :version, :description, :url, :urlpath, :outofdate

  @archive_path

  # note: a Package is always initialized from a JSON result returned by
  # the aur's rpc interface
  def initialize json_result
    @name        = json_result['Name']
    @version     = json_result['Version']
    @description = json_result['Description']
    @url         = json_result['URL']
    @urlpath     = json_result['URLPath']
    @outofdate   = json_result['OutOfDate'] == "1" ? true : false
  end

  def self.find name
    asearch = AurSearch.new name, :info

    raise if asearch.results.empty?
    pkg = asearch.results.first
    return pkg
  end

  def download
    uri           = AUR + @urlpath
    @archive_path = File.basename(uri)

    f = open(@archive_path, "wb")
    f.write(open(uri).read)
    f.close
  end

  def extract
    # todo: can ruby do this itself?
    `tar xzf #{@archive_path}`  
  end

  def build
    oldpwd = Dir.pwd
    if Dir.exists? @name
      Dir.chdir @name

      if File.exists? 'PKGBUILD'
        begin `makepkg`
        rescue
          raise
        end
      end

      Dir.chdir oldpwd
    end
  end

  def install
    pkg = nil

    catch :found do
      Find.find(@name) do |fp|
        if fp =~ /.*\.pkg\.tar\.[gx]z$/
          pkg = fp
          throw :found
        end
      end
    end

    if pkg
      begin `sudo pacman -U #{pkg}`
      rescue
        raise
      end
    end
  end
end
