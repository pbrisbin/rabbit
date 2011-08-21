#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby.
#
###
require_relative 'lib/package'

pkg = Package.find 'aurget'

if pkg
  pkg.download
  pkg.extract
  pkg.build
  pkg.install
end
