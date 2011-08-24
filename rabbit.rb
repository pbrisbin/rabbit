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

class Config
  attr_reader :pacman, :makepkg, :sync_level,
    :build_directory, :package_directory,
    :discard_sources, :discard_tarball, :discard_package,
    :resolve_deps, :edit_pkgbuilds, :ignore_packages

  # the default config. options not implemented are commented for now
  def initialize
    @pacman            = "sudo pacman -U"
    @makepkg           = "makepkg"
    @sync_level        = 3 # 0 => download, 1 => extract, 2 => build, 3 => install
    @build_directory   = ENV['HOME'] + "/Sources"
    @package_directory = ENV['HOME'] + "/Packages"
    @discard_sources   = true
    @discard_tarball   = true
    @discard_package   = false
    #@resolve_deps      = false
    #@edit_pkgbuilds    = :always #, :never, or :prompt
    #@ignore_packages   = []
  end

  def load_config_file fp
    # todo
  end
end

$config = Config.new
$config.load_config_file "/etc/rabbit.yml"

case ARGV.shift
  when '-Ss'; AurSearch.search *ARGV
  when '-Si'; AurSearch.info  *ARGV
  when '-S' ; Package.install *ARGV
end
