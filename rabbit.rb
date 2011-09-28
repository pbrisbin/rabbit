#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby. this is only a toy.
#
###

require_relative 'lib/aursearch'
require_relative 'lib/config'
require_relative 'lib/package'

Signal.trap("INT") { exit 1 }

$config = Config.load_from_file

case ARGV.shift
  when '-Ss'; Aur.search   ARGV.join(' ')
  when '-Si'; Aur.info     ARGV.join(' ')
  when '-Sp'; Aur.pkgbuild ARGV.join(' ')
  when '-S' ; Package.install ARGV
  when '-Su'; Package.update
end
