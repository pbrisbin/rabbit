require 'forwardable'
require 'threaded-each'
require 'rabbit/json'
require 'rabbit/search'
require 'rabbit/package'
require 'rabbit/dependencies'

# rabbit is a toy implementation of the classic aur-helper in ruby.
# focus is on speed by being as multi-threaded as the domain allows.
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
