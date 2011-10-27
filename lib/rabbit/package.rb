require 'net/http'

module Rabbit
  module Package
    def self.find(name)
      # TODO
      url = "http://aur.archlinux.org/packages/ha/haskell-yesod/PKGBUILD"

      pkg = Package.new
      pkg.pkg_build = PkgBuild.new(url)

      pkg
    end

    class Package
      attr_accessor :name, :version, :pkg_build
    end

    class PkgBuild
      def initialize(url)
        @url = url
      end

      def download
        unless @content
          resp = Net::HTTP.get_response(URI.parse(@url))
          @content = resp.body
        end

        @content
      rescue => e
        STDERR.puts e.message
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
end
