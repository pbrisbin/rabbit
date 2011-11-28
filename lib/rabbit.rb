require 'forwardable'
require 'threaded-each'
require 'rabbit/json'
require 'rabbit/search'
require 'rabbit/package'
require 'rabbit/dependencies'

# rabbit is a toy implementation of the classic aur-helper in ruby.
# focus is on speed by being as multi-threaded as the domain allows.
# view/run lib/rabbit.rb to see what's implemented and how to use it.
module Rabbit
  class << self
    extend Forwardable

    def_delegator Rabbit::Package,      :find
    def_delegator Rabbit::Package,      :upgrades
    def_delegator Rabbit::Dependencies, :all_dependencies
    def_delegator Rabbit::Search,       :search
    def_delegator Rabbit::Search,       :info
  end
end

def test_depends
  name = 'haskell-yesod'

  pkg = Rabbit.find(name)
  deps = Rabbit.all_dependencies(pkg)

  puts "#{name} has:"
  puts "> #{deps[:depends].length} depends"
  puts "> #{deps[:makedepends].length} makedepends"
  puts "> #{deps[:pacdepends].length} pacdepends"
end

def test_search
  Rabbit.search('aur helper')
  Rabbit.info(['aurget', 'cower-git'])
end

def test_upgrades
  Rabbit.upgrades.sort_by(&:name).each do |pkg|
    puts "#{pkg.name} --> #{pkg.version}"
  end
end

test_depends
test_search
test_upgrades
