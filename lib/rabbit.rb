$LOAD_PATH << './lib' # while developing

require 'forwardable'
require 'threaded-each'
require 'rabbit/json'
require 'rabbit/search'
require 'rabbit/package'
require 'rabbit/dependencies'

module Rabbit
  class << self
    extend Forwardable

    def_delegator Rabbit::Package,      :find
    def_delegator Rabbit::Dependencies, :all_dependencies
    def_delegator Rabbit::Search,       :search
    def_delegator Rabbit::Search,       :info
  end
end

pkg = Rabbit.find('haskell-yesod')
puts Rabbit.all_dependencies(pkg).inspect

Rabbit.search('aur helper')
Rabbit.info(['aurget', 'cower-git'])
