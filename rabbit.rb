#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby.
#
# This is a toy. There is currently little to no:
#
#   * Features
#   * Error handling
#   * Configuration
#
###
require_relative 'lib/aursearch'
require_relative 'lib/package'

#AurSearch.info "aurget", "cower-git"

#AurSearch.search "ruby"

pkg = Package.find "aurget"

if pkg
  pkg.download
  pkg.extract
  pkg.build
  pkg.install
end
