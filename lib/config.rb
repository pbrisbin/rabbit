require 'yaml'

class Config
  attr_accessor :pacman, :makepkg, :sync_level,
    :build_directory, :package_directory,
    :discard_sources, :discard_tarball, :discard_package,
    :resolve_deps, :edit_pkgbuilds, :ignore_packages

  def initialize
    # default configuration
    @pacman            = "sudo pacman -U"
    @makepkg           = "makepkg --nocolor"
    @sync_level        = 0
    @build_directory   = ENV['HOME'] + "/Sources"
    @package_directory = ENV['HOME'] + "/Packages"
    @discard_sources   = false
    @discard_tarball   = false
    @discard_package   = false
    @resolve_deps      = false
    @edit_pkgbuilds    = :always
    @ignore_packages   = []
  end

  def self.load_from_file
    c = Config.new
    c.load_from_file
  end

  def load_from_file
    def read_key yml, key
      instance_eval "@#{key} = yml['#{key}'] if yml.has_key? '#{key}'"
    end

    def read_mapped_key yml, key, mapping
      instance_eval "@#{key} = mapping[yml['#{key}']] if yml.has_key? '#{key}'"
    end

    # note: just a temp path for testing
    yml = YAML.load_file "/home/patrick/Code/ruby/rabbit/rabbit.yml"

    read_key yml, 'pacman'
    read_key yml, 'makepkg'
    read_key yml, 'build_directory'
    read_key yml, 'package_directory'
    read_key yml, 'discard_sources'
    read_key yml, 'discard_tarball'
    read_key yml, 'discard_package'
    read_key yml, 'resolve_deps'
    read_key yml, 'ignore_packages'

    # map the symbols to integers to simplify the "how far do we go"
    # check during installations.
    read_mapped_key yml, 'sync_level', { :download => 0,
                                         :extract  => 1,
                                         :build    => 2,
                                         :install  => 3 }

    # this mapping just ensures a valid value was entered
    read_mapped_key yml, 'edit_pkgbuilds', { :always => :always,
                                             :never  => :never,
                                             :prompt => :prompt }

    # some post-user-input fixes
    @sync_level     = :download unless @sync_level
    @edit_pkgbuilds = :always   unless @edit_pkgbuilds

    @build_directory.gsub!   /~/, ENV['HOME']
    @package_directory.gsub! /~/, ENV['HOME']

    return self
  end
end
