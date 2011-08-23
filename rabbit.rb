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

def install_targets targets
  targets.each do |target|
    # find will print it's own "not found"
    pkg = Package.find target

    if pkg
      begin
        pkg.download
        pkg.extract
        pkg.build
        pkg.install
      rescue
        STDERR.puts "Something broke installing #{pkg.name}"
      end
    end
  end
end

case ARGV.shift
  when '-S' ; install_targets   ARGV
  when '-Ss'; AurSearch.search *ARGV
  when '-Si'; AurSearch.info   *ARGV
end
