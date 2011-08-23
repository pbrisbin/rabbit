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

case ARGV[0]
  when '-Ss'
    ARGV.shift
    AurSearch.search *ARGV

  when '-Si'
    ARGV.shift
    AurSearch.info *ARGV
end
