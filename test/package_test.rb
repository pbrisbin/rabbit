require 'test/unit'
require 'fileutils'

require_relative '../lib/rabbit/package'

class PackageTest < Test::Unit::TestCase
  def setup
    # a mock config
    $config = Object.new
    def $config.makepkg; "makepkg --nocolor" end
    def $config.pacman;  "sudo pacman -U"    end

    def $config.discard_tarball; false end
    def $config.discard_sources; false end
    def $config.discard_package; false end
  end

  def teardown
    File.delete @pkg.archive if File.exists? @pkg.archive
    FileUtils.rm_rf @pkg.name if Dir.exists? @pkg.name
  end

  def test_find
    @pkg = Package.find 'aurget'
    assert_not_nil @pkg
    assert_equal 'aurget', @pkg.name
  end

  def test_pkgbuild_method
    @pkg = Package.find 'aurget'
    assert_not_nil @pkg

    pkgbuild = @pkg.pkgbuild
    assert_not_nil pkgbuild
  end

  def test_download
    @pkg = Package.find 'aurget'
    assert_not_nil @pkg

    @pkg.download
    assert File.exists? @pkg.archive
  end

  def test_extract
    @pkg = Package.find 'aurget'
    assert_not_nil @pkg

    @pkg.extract
    assert Dir.exists? @pkg.name
  end

  def test_build
    @pkg = Package.find 'aurget'
    assert_not_nil @pkg

    @pkg.build
    assert Dir.exists? @pkg.name
    assert File.exists? "#{@pkg.name}/#{@pkg.name}-#{@pkg.version}-any.pkg.tar.xz"
  end
end
