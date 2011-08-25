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
require 'pkgbuild'

#class Config
  #attr_reader :pacman, :makepkg, :sync_level,
    #:build_directory, :package_directory,
    #:discard_sources, :discard_tarball, :discard_package,
    #:resolve_deps, :edit_pkgbuilds, :ignore_packages

  #def initialize
    #@pacman            = "sudo pacman -U"
    #@makepkg           = "makepkg -s --nocolor"
    #@sync_level        = 3
    #@build_directory   = ENV['HOME'] + "/Sources"
    #@package_directory = ENV['HOME'] + "/Packages"
    #@discard_sources   = true
    #@discard_tarball   = true
    #@discard_package   = false
    #@resolve_deps      = false
    #@edit_pkgbuilds    = :always
    #@ignore_packages   = []
  #end

  #def load_config_file fp
    ## todo: yaml?
  #end
#end

#$config = Config.new

#case ARGV.shift
  #when '-Ss'; AurSearch.search   *ARGV
  #when '-Si'; AurSearch.info     *ARGV
  #when '-Sp'; AurSearch.pkgbuild *ARGV
  #when '-S' ; Package.install    *ARGV
#end

def find_all_deps original_targets
  aur_deps = original_targets.reverse
  pac_deps = []
  #mk_deps  = []

  aur_deps.each do |dep|
    begin pkg = Package.find dep
      #begin

        pkg.with_pkgbuild do |str|
          pkgbuild = Pkgbuild.new str
          pkgbuild.parse!

          args =  pkgbuild.depends.collect     { |x| "'#{x}'" }.join(' ')
          args << pkgbuild.makedepends.collect { |x| "'#{x}'" }.join(' ')

          deps = `pacman -T -- #{args}`.split(' ')

          deps.each do |ddep|
            aur_deps << ddep unless aur_deps.include? ddep
          end
        end

      #rescue RabbitNonError => e
        #puts "#{pkg.name}: #{e}"
        #next

      #rescue RabbitError => e
        #puts "#{pkg.name}: #{e}"
        #exit 1
      #end

    rescue RabbitNotFoundError
      # cannot be installed via AUR, hopefully a repo package
      # todo: check that fact
      pac_deps << dep unless pac_deps.include? dep
    end
  end

  return { :aur    => (aur_deps - pac_deps).reverse,
           :pacman => pac_deps.reverse }
end

deps = find_all_deps ["aurget", "cower-git", "haskell-yesod"]

puts "", "warning: the following (#{deps[:pacman].length}) packages will be installed by pacman: #{deps[:pacman].join(' ')}",
     "", "Targets (#{deps[:aur].length}): #{deps[:aur].join(' ')}",
     ""
