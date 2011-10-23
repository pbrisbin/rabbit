require 'test/unit'

require_relative '../lib/config'

class RabbitConfigDefaultTest < Test::Unit::TestCase
  def setup
    @config = RabbitConfig.new
  end

  def test_yml_undefined
    assert_nil @config.yml
  end

  def test_keys_match
    assert_equal @config.pacman, "sudo pacman -U"
    assert_equal @config.makepkg, "makepkg --nocolor"
    assert_equal @config.sync_level, :download
    assert_equal @config.build_directory, ENV['HOME'] + "/Sources"
    assert_equal @config.package_directory, ENV['HOME'] + "/Packages"
    assert_equal @config.edit_pkgbuilds, :always
    assert_equal @config.ignore_packages, []
  end

  def test_boolean_values
    assert !@config.discard_sources
    assert !@config.discard_tarball
    assert !@config.discard_package
    assert !@config.resolve_deps
  end
end

class RabbitConfigLoadTest < Test::Unit::TestCase
  def setup
    @config = RabbitConfig.load_from_file "test/fake_config.yml"
  end

  def test_yml_defined
    assert_not_nil @config.yml
  end

  def test_loaded_keys_match
    assert_equal @config.pacman, "sudo pacman-color -U"
    assert_equal @config.makepkg, "makepkg -s"
    assert_equal @config.sync_level, :install
    assert_equal @config.build_directory, ENV['HOME'] + "/sources"
    assert_equal @config.package_directory, ENV['HOME'] + "/packages"
    assert_equal @config.edit_pkgbuilds, :never
  end

  def test_loaded_boolean_values
    assert @config.discard_sources
    assert @config.discard_tarball
    assert !@config.discard_package
    assert @config.resolve_deps
  end

  def test_empty_key_makes_nil
    assert_nil @config.ignore_packages
  end
end
