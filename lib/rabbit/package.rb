module Rabbit
  class Package
    attr_accessor :name, :version, :pkg_build

    def initialize(name)
      @name = name
    end

    def to_s; name end

    def self.find(name)
      url = "http://aur.archlinux.org/packages/#{name[0..1]}/#{name}/PKGBUILD"

      pkg = new(name)
      pkg.pkg_build = PkgBuild.new(url)

      pkg
    end
  end

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
