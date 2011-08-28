#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby. this is only a toy.
#
###
require 'pathname'

$LOAD_PATH << # add the current directory and ./lib
  File.dirname(Pathname.new(File.expand_path(__FILE__)).realpath) <<
  File.dirname(Pathname.new(File.expand_path(__FILE__)).realpath) + '/lib'

require 'aursearch'
require 'config'
require 'package'

Signal.trap("INT") { exit 1 }

$config = Config.load_from_file

case ARGV.shift
  when '-Ss'; AurSearch.search   ARGV
  when '-Si'; AurSearch.info     ARGV
  when '-Sp'; AurSearch.pkgbuild ARGV
  when '-S' ; Package.install    ARGV
  when '-Su'; Package.update
end
