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

case ARGV[0]
when '-S'
  pkg = Package.find ARGV[1]

  if pkg
    pkg.download
    pkg.extract
    pkg.build
    pkg.install
  end

when '-Ss'
  srch = AurSearch.new ARGV[1]
  srch.show_results

when '-Ssi'
  srch = AurSearch.new ARGV[1], :info
  srch.show_results

else
  puts "usage: rabbit [ -S <pkg> | -Ss <term> | -Ssi <term> ]"
end
