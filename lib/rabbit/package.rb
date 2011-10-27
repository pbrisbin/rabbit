
module Rabbit
  module Package
    class Taurball
      def initialize(package)

      end

      def download

      end
    end

    class Pkgbuild
      def initialize(package)

      end

      def download
        unless @content
          # todo: d/l it
        end

        @content
      end

      def depends
        @depends ||= parse(:depends)
      end

      def makedepends
        @makedepends ||= parse(:makedepends)
      end

      private

      def parse(key)
        content = download

        deps = []
        if content =~ /(^|\s)#{varname.to_s}=\((.*?)\)/m
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
