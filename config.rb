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

  def load_config_file
    def read_key config, key
      instance_eval "@#{key} = config['#{key}'] if config.has_key? '#{key}'"
    end

    def read_mapped_key config, key, mapping
      instance_eval "@#{key} = mapping[config['#{key}']] if config.has_key? '#{key}'"
    end

    # note: just a temp path for testing
    config = YAML.load_file("/home/patrick/Code/ruby/rabbit/rabbit.yml")

    read_key config, 'pacman'
    read_key config, 'makepkg'
    read_key config, 'build_directory'
    read_key config, 'package_directory'
    read_key config, 'discard_sources'
    read_key config, 'discard_tarball'
    read_key config, 'discard_package'
    read_key config, 'resolve_deps'
    read_key config, 'edit_pkgbuilds'
    read_key config, 'ignore_packages'

    # map the symbols to integers to simplify the "how far do we go"
    # check during installations.
    read_mapped_key config, 'sync_level', { :download => 0,
                                            :extract  => 1,
                                            :build    => 2,
                                            :install  => 3 }
  end
end
