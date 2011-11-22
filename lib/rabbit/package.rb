module Rabbit
  # main Package datatype -- has a name, version and a PkgBuild. TODO:
  # methods to download, build, install, etc.
  class Package
    extend Json

    attr_reader :name, :version
    attr_accessor :pkg_build

    private_class_method :new

    def to_s; name end

    def init_from_json(result)
      @name = result.Name
      @version = result.Version
    end

    def self.find(name)
      results = fetch_json(url_for_info([name]))
      return nil if results.empty?

      result = results.first

      url = "http://aur.archlinux.org/packages/#{name[0..1]}/#{name}/PKGBUILD"

      pkg = new
      pkg.init_from_json(result)
      pkg.pkg_build = PkgBuild.new(url)

      pkg
    end
  end

  # a PkgBuild can be downloaded and parsed for depends and make depends
  class PkgBuild
    def initialize(url)
      @url = url
    end

    def download
      unless @content
        require 'net/http'
        resp = Net::HTTP.get_response(URI.parse(@url))
        @content = resp.body
      end

      @content
    rescue => ex
      $stderr.puts "#{ex}"
      @content = ''
    end

    def depends;     @depends     ||= parse('depends')     end
    def makedepends; @makedepends ||= parse('makedepends') end

    private

    def parse(key)
      content = download

      deps = []
      if content =~ /(^|\s)#{key}=\((.*?)\)/m
        # remove inline comments, join multiline statements, split on
        # whitespace, pull out just the package name from a variety of
        # quoting and/or version bounds
        deps = $2.split(/#.*?\n/m).join.split(/[\s]+/).collect do |dep|
          dep =~ /("|')([^><=]*)[><=]{0,2}.*\1/ ? $2 : dep
        end

        deps.delete ""
      end

      deps
    end
  end
end
