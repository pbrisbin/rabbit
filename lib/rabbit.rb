$LOAD_PATH << './lib' # while developing

require 'threaded-each'
require 'rabbit/json'
require 'rabbit/search'
require 'rabbit/package'
require 'rabbit/dependencies'

pkg = Rabbit::Package.find('haskell-yesod')
puts Rabbit::Dependencies.all_dependencies(pkg).inspect

Rabbit::Search.search('aur helper')
Rabbit::Search.info(['aurget', 'cower-git'])
