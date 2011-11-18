# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rabbit/version"

Gem::Specification.new do |s|
  s.name        = "rabbit"
  s.version     = Rabbit::VERSION
  s.authors     = ["Patrick Brisbin"]
  s.email       = "pbrisbin@gmail.com"
  s.homepage    = "https://github.com/pbrisbin/rabbit"
  s.summary     = "An aur helper in ruby"
  s.description = "An aur helper in ruby"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.licenses      = ["MIT"]
  s.executables = ["rabbit"]
end
