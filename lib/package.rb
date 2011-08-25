require 'aursearch'
require 'fileutils'
require 'open-uri'
require 'pkgbuild'

# when a search returns no results
class RabbitNotFoundError < StandardError
end

# an error that should stop processing of that target only
class RabbitNonError < StandardError
end

# a build error on a dependecy must stop the processesing of its parent
# and any other deps left to build
class RabbitBuildError < StandardError
end

# an error that should stop us entirely
class RabbitError < StandardError
end

class Package
  attr_reader :name, :version, :base_url, :archive

  def initialize name, version, url
    @name     = name
    @version  = version
    @base_url = File.dirname  url
    @archive  = File.basename url
  end

  def self.find name
    pkg = AurSearch.class_eval do
      # access private call_rpc method
      call_rpc(:multiinfo, name) do |r|
        return Package.new r['Name'], r['Version'], AUR + r['URLPath']
      end
    end
  end

  def self.install *targets
    if $config.resolve_deps
      puts "resolving dependencies..."

      deps = Package.find_all_deps targets

      puts "",
           "warning: the following (#{deps[:pacman].length}) packages may be installed by pacman: #{deps[:pacman].join(' ')}",
           "" unless deps[:pacman].empty?

      targets = deps[:aur]
    end

    puts "", "Targets (#{targets.length}): #{targets.join(' ')}",
         ""
    print "Proceed with installation (y/n)? "
    reply = STDIN.gets

    unless reply.chomp =~ /y(es)?/i
      exit
    end

    # create the build dir if needed
    unless Dir.exists? $config.build_directory
      begin FileUtils.mkdir_p $config.build_directory
      rescue
        raise RabbitError, "Could not create #{$config.build_directory}."
      end
    end

    # change to it
    Dir.chdir $config.build_directory

    targets.each do |target|
      pkg = self.find target

      if pkg
        begin
          pkg.download
          pkg.extract unless $config.sync_level < 1
          pkg.build   unless $config.sync_level < 2
          pkg.install unless $config.sync_level < 3

        rescue RabbitNotFoundError => e
          STDERR.puts e.message

        rescue RabbitNonError => e
          STDERR.puts e.message, "Skipping #{pkg.name}."

        rescue RabbitError => e
          STDERR.puts e.message
          exit 1
        end
      end
    end
  end

  def self.find_all_deps original_targets
    aur_deps = original_targets.reverse
    pac_deps = []

    aur_deps.each do |dep|
      begin pkg = Package.find dep
        begin
          pkg.with_pkgbuild do |pkgbuild|
            pkgbuild.parse!

            args =  pkgbuild.depends.collect     { |x| "'#{x}'" }.join(' ')
            args << pkgbuild.makedepends.collect { |x| "'#{x}'" }.join(' ')

            deps = `pacman -T -- #{args}`.split(' ')

            deps.each do |ddep|
              aur_deps << ddep unless aur_deps.include? ddep
            end
          end

        rescue RabbitNonError => e
          puts "#{pkg.name}: #{e}"
          next

        rescue RabbitError => e
          puts "#{pkg.name}: #{e}"
          exit 1
        end

      rescue RabbitNotFoundError
        # cannot be installed via AUR, hopefully a repo package
        # todo: check that fact
        pac_deps << dep unless pac_deps.include? dep
      end
    end

    return { :aur    => (aur_deps - pac_deps).reverse,
             :pacman => pac_deps.reverse }
  end

  # excute a block with a Package's pkgbuild
  def with_pkgbuild &block
    begin
      url  = @base_url + '/PKGBUILD'
      resp = Net::HTTP.get_response(URI.parse(url))
      pkgbuild = Pkgbuild.new(resp.body)
      block.call pkgbuild
    rescue
      raise RabbitNonError, "Error retrieving the PKGBUILD"
    end
  end

  # download the tarball into the current directory
  def download
    archive_url = "#{@base_url}/#{@archive}"

    begin
      a = open(archive_url)
      f = open(@archive, "wb")
      f.write(a.read)
    rescue
      raise RabbitNonError, "Error downloading the package"
    ensure
      a.close
      f.close
    end
  end

  # extract the downloaded archive
  def extract
    if File.exists? @archive
      unless system "tar xzf \"#{@archive}\""
        raise RabbitNonError, "Tar threw an error"
      end

      # maybe discard the taball
      File.delete @archive if $config.discard_tarball
    else
      raise RabbitNonError, "#{archive}: file not found"
    end
  end

  # build the package
  def build
    oldpwd = Dir.pwd
    if Dir.exists? @name
      Dir.chdir @name

      if File.exists? 'PKGBUILD'
        unless system $config.makepkg
          raise RabbitNonError "Makepkg threw an error"
        end

        # maybe discard the sources
        if $config.discard_sources
          Dir.glob("./*") do |fp|
            FileUtils.rm_rf fp unless fp =~ /.*\.pkg\.tar\.[gx]z$/
          end
        end
      else
        raise RabbitNonError, "PKGBUILD: file not found"
      end

      Dir.chdir oldpwd
    end
  end

  # install all built packages
  def install
    to_install = []

    # find all built packages
    Dir.glob("#{@name}/*") do |fp|
      to_install << fp if fp =~ /.*\.pkg\.tar\.[gx]z$/
    end

    if to_install.empty?
      raise RabbitNonError, "No packages found to install"
    end

    # make a quote separated string of args
    args = to_install.collect { |a| "'#{a}'" }.join(' ')

    # install all of them
    unless system "#{$config.pacman} #{args}"
      raise RabbitNonError, "Pacman threw an error"
    end

    if $config.discard_package
      to_install.each { |pkg| File.delete pkg }
    else
      unless Dir.exists? $config.package_directory
        begin FileUtils.mkdir_p $config.package_directory
        rescue
          to_install = [] # so we don't try to save them
          raise RabbitNonError, "Could not create #{$config.package_directory}."
        end
      end

      to_install.each do |pkg|
        begin
          from = open(pkg, "rb")
          to   = open("#{$config.package_directory}/#{File.basename pkg}", "wb")
          to.write(from.read)

          File.delete pkg
        rescue
          raise RabbitNonError, "Error saving the package"
        ensure
          from.close
          to.close
        end
      end

      if Dir.exists? @name
        begin Dir.delete @name
        rescue Errno::ENOTEMPTY
          # silenty ignore
        end
      end
    end
  end
end
