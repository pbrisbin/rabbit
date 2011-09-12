#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby. this is only a toy.
#
###
require 'pathname'

$LOAD_PATH << # add . and ./lib in spite of symlinks
  File.dirname(Pathname.new(File.expand_path(__FILE__)).realpath) <<
  File.dirname(Pathname.new(File.expand_path(__FILE__)).realpath) + '/lib'

require 'aursearch'
require 'config'
require 'package'

Signal.trap("INT") { exit 1 }

$config = Config.load_from_file

case ARGV.shift
  when '-Ss'; Aur.search   ARGV.join(' ')
  when '-Si'; Aur.info     ARGV.join(' ')
  when '-Sp'; Aur.pkgbuild ARGV.join(' ')
  when '-S' ; Package.install ARGV
  when '-Su'; Package.update
end
