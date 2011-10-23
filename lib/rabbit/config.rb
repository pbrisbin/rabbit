require 'yaml'

class RabbitConfig
  attr_accessor :pacman, :makepkg, :sync_level, :build_directory,
    :package_directory, :discard_sources, :discard_tarball,
    :discard_package, :resolve_deps, :edit_pkgbuilds, :ignore_packages,
    :yml

  def initialize
    # default configuration
    @pacman            = "sudo pacman -U"
    @makepkg           = "makepkg --nocolor"
    @sync_level        = :download
    @build_directory   = ENV['HOME'] + "/Sources"
    @package_directory = ENV['HOME'] + "/Packages"
    @discard_sources   = false
    @discard_tarball   = false
    @discard_package   = false
    @resolve_deps      = false
    @edit_pkgbuilds    = :always
    @ignore_packages   = []
    @yml               = nil
  end

  def read_yml_key key
    instance_eval "@#{key} = yml['#{key}'] if yml.has_key? '#{key}'"
  end

  def self.load_from_file fp = '/etc/rabbit.yml'
    c = RabbitConfig.new
    c.yml = YAML.load_file fp

    c.read_yml_key 'pacman'
    c.read_yml_key 'makepkg'
    c.read_yml_key 'build_directory'
    c.read_yml_key 'package_directory'
    c.read_yml_key 'discard_sources'
    c.read_yml_key 'discard_tarball'
    c.read_yml_key 'discard_package'
    c.read_yml_key 'resolve_deps'
    c.read_yml_key 'ignore_packages'
    c.read_yml_key 'sync_level'
    c.read_yml_key 'edit_pkgbuilds'

    c.build_directory   = File.expand_path(c.build_directory)
    c.package_directory = File.expand_path(c.package_directory)

    return c
  end
end
