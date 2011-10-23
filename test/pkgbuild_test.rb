require 'test/unit'

require_relative '../lib/pkgbuild'

class PkgbuildTest < Test::Unit::TestCase
  def test_no_deps
    File.open('test/test_pkgbuilds/aurget') do |f|
      contents = f.read
      pkgbuild = Pkgbuild.new contents
      assert pkgbuild.depends.empty?, "Aurget should have no deps"
    end
  end

  def test_many_deps
    expected_deps = [ "ghc",
                      "sh",
                      "haskell-cabal",
                      "haskell-attoparsec-text",
                      "haskell-blaze-builder",
                      "haskell-bytestring",
                      "haskell-containers",
                      "haskell-directory",
                      "haskell-hamlet",
                      "haskell-hjsmin",
                      "haskell-http-types",
                      "haskell-mime-mail",
                      "haskell-monad-control",
                      "haskell-parsec",
                      "haskell-process",
                      "haskell-template-haskell",
                      "haskell-text",
                      "haskell-time",
                      "haskell-transformers",
                      "haskell-unix-compat",
                      "haskell-wai",
                      "haskell-wai-extra",
                      "haskell-warp",
                      "haskell-yesod-auth",
                      "haskell-yesod-core",
                      "haskell-yesod-form",
                      "haskell-yesod-json",
                      "haskell-yesod-persistent",
                      "haskell-yesod-static" ]

    File.open('test/test_pkgbuilds/yesod') do |f|
      contents = f.read
      pkgbuild = Pkgbuild.new contents
      assert_equal expected_deps, pkgbuild.depends, "Yesod should have a lot of deps"
    end
  end
end
