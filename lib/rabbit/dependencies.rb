require 'threaded-each'
require 'rabbit/package'

module Rabbit
  module Dependencies
    def recursive_dependencies(hsh)
      new_hsh = dependencies(hsh)
      recursive_dependencies(new_hsh) unless new_hash == hsh

      new_hsh
    end

    def dependencies(hsh)
      depends     = hsh[:depends]
      makedepends = hsh[:makedepends]
      pacdepends  = []

      (hsh[:depends] + hsh[:makedepends]).threaded_each do |pkg|
        pkg.pkg_build.depends.threaded_each do |d|
          p = Package.find(d) ? depends << p : pacdepends << d
        end

        pkg.pkg_build.makedepends.threaded_each do |m|
          p = Package.find(m) ? makedepends << p : pacdepends << m
        end
      end

      { :depends     => depends.uniq,
        :makedepends => makedepends.uniq,
        :pacdepends  => pacdepends.uniq
      }
    end
  end
end
