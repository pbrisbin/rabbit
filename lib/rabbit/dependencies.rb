require 'threaded-each'
require 'rabbit/package'

module Rabbit
  module Dependencies
    def all_dependencies(pkg)
      recursive_dependencies(:depends     => [pkg],
                             :makedepends => [],
                             :pacdepends  => [])
    end

    private

    def recursive_dependencies(hsh)
      new_hsh = dependencies(hsh)

      if more_found(new_hsh, hsh)
        recursive_dependencies(new_hsh)
      else
        new_hsh
      end
    end

    def dependencies(hsh)
      depends     = hsh[:depends].dup
      makedepends = hsh[:makedepends].dup
      pacdepends  = hsh[:pacdepends].dup

      (hsh[:depends] + hsh[:makedepends]).threaded_each do |pkg|
        pkg.pkg_build.depends.threaded_each do |d|
          p = find(d)
          p ? depends << p : pacdepends << d
        end

        pkg.pkg_build.makedepends.threaded_each do |m|
          p = find(m)
          p ? makedepends << p : pacdepends << m
        end
      end
      
      #puts ""
      #puts "d: #{depends.uniq {|p| p.name}.compact.inspect}"
      #puts "m: #{makedepends.uniq {|p| p.name}.compact.inspect}"
      #puts "p: #{pacdepends.uniq {|p| p.name}.compact.inspect}"

      { :depends     => depends.uniq {|p| p.name}.compact,
        :makedepends => makedepends.uniq {|p| p.name}.compact,
        :pacdepends  => pacdepends.uniq {|p| p.name}.compact
      }
    end

    def more_found(hsh_a, hsh_b)
      [:depends, :makedepends, :pacdepends].each do |k|
        #puts "a: #{hsh_a[k].length}"
        #puts "b: #{hsh_b[k].length}"
        return true if hsh_a[k].length != hsh_b[k].length
      end

      false
    end
  end
end

class Tester
  extend Rabbit::Package
  extend Rabbit::Dependencies
end

pkg = Tester.find('haskell-yesod')
puts Tester.all_dependencies(pkg)
