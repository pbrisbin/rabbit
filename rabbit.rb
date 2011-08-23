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

case ARGV.shift
  when '-S' ; Package.install *ARGV
  when '-Ss'; AurSearch.search *ARGV
  when '-Si'; AurSearch.info  *ARGV
end
