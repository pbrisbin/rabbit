require 'rubygems'
require 'aursearch'
require 'errors'
require 'fileutils'
require 'open-uri'
require 'pkgbuild'
require 'threaded-each'

class Package
  attr_reader :name, :version, :base_url, :archive

  def initialize name, version, url
    @name       = name
    @version    = version
    @base_url   = File.dirname  url
    @archive    = File.basename url
    @pkgbuild   = nil
    @built_pkgs = nil
  end

  def pkgbuild
    unless @pkgbuild
      begin
        url  = @base_url + '/PKGBUILD'
        resp = Net::HTTP.get_response(URI.parse(url))
        pkgbuild = Pkgbuild.new(resp.body)
      rescue => e
        STDERR.puts e.message
        raise RabbitNonError, "Error retrieving the PKGBUILD"
      end
    end

    @pkgbuild
  end

  def built_pkgs
    unless @built_pkgs
      Dir.glob("#{@name}/*") do |fp|
        @built_pkgs << fp if fp =~ /.*\.pkg\.tar\.[gx]z$/
      end

      if @built_pkgs.empty?
        raise RabbitNonError, "No packages found to save"
      end
    end

    @built_pkgs
  end


  def self.find name
    json = Aur.call_rpc(:multiinfo, name)
    Package.new json['Name'], json['Version'], Aur::URL + json['URLPath']
  end

  def self.update
    puts "checking for available upgrades..."

    targets = []

    `pacman -Qm`.lines.threaded_each do |out|
      name, version = out.split(' ')

      begin
        Aur.call_rpc(:multiinfo, name) do |r|
          nversion = r['Version']
          if `vercmp '#{nversion}' '#{version}'`.to_i == 1
            targets << Package.new(r['Name'], nversion, Aur::URL + r['URLPath'])
          end
        end

        nil
      rescue RabbitNotFoundError
        # ignore
      end
    end

    process_targets targets unless targets.empty?
  end

  # accepts names and hands off to process_targets
  def self.install names
    targets = []

    names.each do |name|
      begin
        targets << find(name)
      rescue RabbitNotFoundError
        STDERR.puts "#{name}: package not found"
      end
    end

    process_targets targets unless targets.empty?
  end

  # accepts Packages, returns nothing
  def self.process_targets targets
    if $config.resolve_deps
      puts "resolving dependencies..."

      deps = find_all_deps targets

      puts %{
        warning: the following (#{deps[:pacman].length}) packages may be installed by pacman: #{deps[:pacman].join(' ')}
      }.gsub(/^ +/,'') unless deps[:pacman].empty?

      targets = deps[:targets]
    end

    print %{
      Targets (#{targets.length}): #{targets.collect { |x| x.name }.join(' ')}

      Proceed with installation (y/n)? }.gsub(/^ +/,'')

    exit unless STDIN.gets.chomp =~ /y(es)?/i

    # create the build dir if needed
    unless Dir.exists? $config.build_directory
      begin FileUtils.mkdir_p $config.build_directory
      rescue => e
        STDERR.puts e.message
        raise RabbitError, "Could not create #{$config.build_directory}."
      end
    end

    Dir.chdir $config.build_directory

    targets.each do |pkg|
      begin
        pkg.download if $config.sync_level == :download
        pkg.extract  if $config.sync_level == :extract

        if $config.sync_level == :build
          pkg.build
          pkg.save_pkgs
        end

        if $config.sync_level == :install
          pkg.build
          pkg.install
          pkg.save_pkgs
        end

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

  # accepts Packages, returns { :targets => Packages, :pacman => names }
  def self.find_all_deps targets
    pac_deps    = []
    new_targets = targets.reverse!.threaded_each do |pkg|
      begin
        targets_new = []

        args = pkg.pkgbuild.depends.collect { |x| "'#{x}'" }.join(' ')
        deps = `pacman -T -- #{args}`.split(' ')

        deps.each do |ddep|
          next if pac_deps.include? ddep
          next if targets.index {|p| p.name == ddep }

          begin
            p = find ddep

            targets     << p # add to master list
            targets_new << p # store the new ones from this round
          rescue RabbitNotFoundError
            # cannot be installed via AUR, hopefully a repo package
            # todo: check that fact
            pac_deps << ddep
          end
        end
        end

        targets_new

      rescue RabbitNonError => e
        STDERR.puts "#{pkg.name}: #{e}"
        next

      rescue RabbitError => e
        STDERR.puts "#{pkg.name}: #{e}"
        exit 1
      end
    end

    unless new_targets.empty?
      new_deps  = find_all_deps new_targets.flatten
      targets  += new_deps[:targets]
      pac_deps += new_deps[:pacman]
    end

    # use uniq to account for the non-thread-safeness of this whole
    # approach...
    return { :targets => targets.uniq { |p| p.name }.reverse,
              :pacman => pac_deps.uniq.reverse }
  end

  def download
    archive_url = "#{@base_url}/#{@archive}"

    begin
      a = open(archive_url)
      f = open(@archive, "wb")
      f.write(a.read)
    rescue => e
      STDERR.puts e.message
      raise RabbitNonError, "Error downloading the package"
    ensure
      a.close
      f.close
    end
  end

  def extract
    # download if we haven't already
    unless File.exists? @archive
      begin download
      rescue RabbitNonError => e
        STDERR.puts e.message
        return
      end
    end

    unless system "tar xzf \"#{@archive}\""
      raise RabbitNonError, "Tar threw an error"
    end

    File.delete @archive if $config.discard_tarball
  end

  def build
    # extract if we haven't already
    unless Dir.exists? @name
      begin extract
      rescue RabbitNonError => e
        STDERR.puts e.message
        return
      end
    end

    oldpwd = Dir.pwd
    Dir.chdir @name

    if File.exists? 'PKGBUILD'
      unless system $config.makepkg
        raise RabbitNonError, "Makepkg threw an error"
      end

      # maybe discard the sources
      if $config.discard_sources
        Dir.glob("./*") do |fp|
          # keep built packages
          FileUtils.rm_rf fp unless fp =~ /.*\.pkg\.tar\.[gx]z$/
        end
      end
    else
      raise RabbitNonError, "PKGBUILD: file not found"
    end

    Dir.chdir oldpwd
  end

  def save_pkgs
    unless Dir.exists? $config.package_directory
      begin FileUtils.mkdir_p $config.package_directory
      rescue => e
        @built_pkgs = [] # so we don't try to save them
        STDERR.puts e.message
        raise RabbitNonError, "Could not create #{$config.package_directory}."
      end
    end

    @built_pkgs.each do |pkg|
      begin
        from = open(pkg, "rb")
        to   = open("#{$config.package_directory}/#{File.basename pkg}", "wb")
        to.write(from.read)

        File.delete pkg
      rescue => e
        STDERR.puts e.message
        raise RabbitNonError, "Error saving the package"
      ensure
        from.close
        to.close
      end
    end

    begin Dir.delete @name
    rescue Errno::ENOTEMPTY
      # silenty ignore
    end
  end

  def install
    args = @built_pkgs.collect { |a| "'#{a}'" }.join(' ')

    unless system "#{$config.pacman} #{args}"
      raise RabbitNonError, "Pacman threw an error"
    end

    if $config.discard_package
      @built_pkgs.each { |pkg| File.delete pkg }
    end
end
