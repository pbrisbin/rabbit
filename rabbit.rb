#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby. this is only a toy.
#
###
require 'pathname'

$LOAD_PATH << # current directory and ./lib
  File.dirname(Pathname.new(File.expand_path(__FILE__)).realpath) <<
  File.dirname(Pathname.new(File.expand_path(__FILE__)).realpath) + '/lib'

require 'aursearch'
require 'package'

class Config
  attr_reader :pacman, :makepkg, :sync_level,
    :build_directory, :package_directory,
    :discard_sources, :discard_tarball, :discard_package,
    :resolve_deps, :edit_pkgbuilds, :ignore_packages

  def initialize
    @pacman            = "sudo pacman -U"
    @makepkg           = "makepkg -s --nocolor"
    @sync_level        = 3
    @build_directory   = ENV['HOME'] + "/Sources"
    @package_directory = ENV['HOME'] + "/Packages"
    @discard_sources   = true
    @discard_tarball   = true
    @discard_package   = false
    @resolve_deps      = false
    @edit_pkgbuilds    = :always
    @ignore_packages   = []
  end

  def load_config_file fp
    # todo: yaml?
  end
end

$config = Config.new

case ARGV.shift
  when '-Ss'; AurSearch.search   *ARGV
  when '-Si'; AurSearch.info     *ARGV
  when '-Sp'; AurSearch.pkgbuild *ARGV
  when '-S' ; Package.install    *ARGV
end
