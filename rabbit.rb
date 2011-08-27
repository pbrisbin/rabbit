#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby. this is only a toy.
#
###
require 'pathname'

$LOAD_PATH << # current directory and ./lib
  File.dirname(Pathname.new(File.expand_path(__FILE__)).realpath) <<
  File.dirname(Pathname.new(File.expand_path(__FILE__)).realpath) + '/lib'

require 'config'
require 'aursearch'
require 'package'

$config = Config.new
$config.load_config_file

case ARGV.shift
  when '-Ss'; AurSearch.search   *ARGV
  when '-Si'; AurSearch.info     *ARGV
  when '-Sp'; AurSearch.pkgbuild *ARGV
  when '-S' ; Package.install    *ARGV
end
