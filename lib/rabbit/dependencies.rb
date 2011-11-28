module Rabbit
  module Dependencies
    # for the given package, recursively resolve dependencies. returns a
    # hash of three keys: depends, makedepends, and pacdepends. depends
    # and makedepends are Arrays of Package objects and pacdepends is an
    # Array of String objects -- package names.
    def self.all_dependencies(pkg)
      recursive_dependencies(:depends     => [pkg],
                             :makedepends => [],
                             :pacdepends  => [])
    end

    private

    def self.recursive_dependencies(hsh)
      new_hsh = dependencies(hsh)

      if more_found(new_hsh, hsh)
        recursive_dependencies(new_hsh)
      else
        new_hsh
      end
    end

    def self.dependencies(hsh)
      depends     = hsh[:depends].dup
      makedepends = hsh[:makedepends].dup
      pacdepends  = hsh[:pacdepends].dup

      (hsh[:depends] + hsh[:makedepends]).threaded_each do |pkg|
        pkg.pkg_build.depends.threaded_each do |d|
          p = Package.find(d)
          p ? depends << p : pacdepends << d
        end

        pkg.pkg_build.makedepends.threaded_each do |m|
          p = Package.find(m)
          p ? makedepends << p : pacdepends << m
        end
      end
      
      {
        :depends     => depends.uniq {|p| p.name}.compact,
        :makedepends => makedepends.uniq {|p| p.name}.compact,
        :pacdepends  => pacdepends.uniq.compact
      }
    end

    def self.more_found(hsh_a, hsh_b)
      [:depends, :makedepends].each do |k|
        return true if hsh_a[k].length != hsh_b[k].length
      end

      false
    end
  end
end
