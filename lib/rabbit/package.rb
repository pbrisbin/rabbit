require 'fileutils'
require 'open-uri'
require 'threaded-each'
require 'rabbit/aursearch'
require 'rabbit/pkgbuild'

# version comparisons
class String
  def newer_than?(other)
    vercmp(self, other) == 1
  end

  def older_than?(other)
    vercmp(self, other) == -1
  end

  private

  def vercmp(a, b)
    `vercmp '#{a}' '#{b}'`.to_i
  end
end

module Package
  class NotFoundError < StandardError; end
  class ProcessError  < StandardError; end
  class FatalError    < StandardError; end

  class AurPackage
    include FileUtils

    attr_accessor :name, :version, :base_url, :archive

    # returns an array of AurPackages
    def self.init_from_json(json, &block)
      key  = 'results'
      pkgs = []

      if json.has_key?(key) && json[key].class == Array && !json[key].empty?
        json[key].threaded_each do |result|
          next if block_given? && !block.call(result)

          pkg = AurPackage.new

          pkg.name     = result['Name']
          pkg.version  = result['Version']
          pkg.base_url = AurSearch::AUR + File.dirname(result['URLPath'])
          pkg.archive  = File.basename(result['URLPath'])

          pkgs << pkg
        end
      end

      pkgs
    end

    def self.find_pkgs(names, &block)
      missing = names
      pkgs    = []

      url = AurSearch.json_request_url(:info, names.join(' '))
      raise unless url

      AurSearch.with_json_response(url) do |json|
        pkgs = init_from_json(json, &block)
      end

      if pkgs.length != names.length
        missing = names - pkgs.map(&:name)
        raise
      end

      pkgs
  
    rescue => e
      STDERR.puts e.message
      raise NotFoundError, missing.join(', ')
    end

    def self.find(name)
      pkgs = find_pkgs([name]) # throws NotFoundError
      pkgs.first

    rescue => e
      STDERR.puts e.message
      raise NotFoundError, e
    end

    def pkgbuild
      unless @pkgbuild
        url  = base_url + '/PKGBUILD'
        resp = Net::HTTP.get_response(URI.parse(url))
        @pkgbuild = Pkgbuild.new(resp.body)
      end

      @pkgbuild

    rescue => e
      STDERR.puts e.message
      raise ProcessError, name
    end

    def built_pkgs
      unless @built_pkgs
        @built_pkgs = []

        Dir.glob("#{name}/*") do |fp|
          @built_pkgs << fp if fp =~ /.*\.pkg\.tar\.[gx]z$/
        end
      end

      @built_pkgs
    end

    def download
      archive_url = "#{base_url}/#{archive}"

      a = open(archive_url)
      f = open(archive, "wb")
      f.write(a.read)

    rescue => e
      STDERR.puts e.message
      raise ProcessError, name
    ensure
      a.close
      f.close
    end

    def extract
      download unless File.exists? archive
      raise ProcessError unless system "tar xzf \"#{archive}\""
      File.delete archive if $config.discard_tarball

    rescue => e
      STDERR.puts e.message
      raise ProcessError, name
    end

    def build
      extract unless File.exists? "#{name}/PKGBUILD"

      Dir.chdir name do
        raise unless File.exists? 'PKGBUILD'
        raise unless system $config.makepkg

        # maybe discard the sources
        if $config.discard_sources
          Dir.glob("./*") do |fp|
            # keep built packages
            FileUtils.rm_rf fp unless fp =~ /.*\.pkg\.tar\.[gx]z$/
          end
        end
      end

    rescue => e
      STDERR.puts e.message
      raise ProcessError name
    end

    def install
      args = built_pkgs.collect { |a| "'#{a}'" }.join(' ')
      raise unless system "#{$config.pacman} #{args}"
      built_pkgs.each { |pkg| File.delete pkg } if $config.discard_package

    rescue => e
      STDERR.puts e.message
      raise ProcessError, name
    end

    def save_pkgs
      dir = $config.package_directory

      mkdir_p dir unless Dir.exists? $config.package_directory

      built_pkgs.each do |pkg|
        from = open(pkg, "rb")
        to   = open("#{dir pkg}", "wb")
        to.write(from.read)

        File.delete pkg
      end

      # silently ignore
      Dir.delete name rescue Errno::ENOTEMPTY
    rescue => e
      STDERR.puts e.message
      raise ProcessError name
    ensure
      from.close if from.defined?
      to.close   if to.defined?
    end
  end

  def self.update
    pkg_hash = {}

    puts "checking for available upgrades..."

    `pacman -Qm`.lines.threaded_each do |out|
      name, version = out.split(' ')
      pkg_hash.merge!({ name => version })
    end

    targets = AurPackage.find_pkgs(pkg_hash.keys) do |result|
      result['Version'].newer_than?(pkgs_hash[result['Name']]) rescue false
    end

    process_targets targets unless targets.empty?

  rescue NotFoundError => e
    # ignore
  rescue SkipError => e
    STDERR.puts "Package #{e.message} failed to process, skipping..."
  rescue FatalError => e
    STDERR.puts "Package #{e.message} failed to process, exiting."
    exit 1
  rescue => e
    STDERR.puts e.message
    exit 1
  end

  def self.install names
    targets = names.collect { |name| find(name) }
    process_targets targets unless targets.empty?

  rescue NotFoundError => e
    STDERR.puts "Package(s) not found: #{e.message}"
    exit 1
  rescue SkipError => e
    STDERR.puts "Package #{e.message} failed to process, skipping..."
  rescue FatalError => e
    STDERR.puts "Package #{e.message} failed to process, exiting."
    exit 1
  rescue => e
    STDERR.puts e.message
    exit 1
  end

  # accepts Packages, returns nothing
  def self.process_targets(targets)
    resolve_dependencies if $config.resolve_deps

    puts  "Targets (#{targets.length}): #{targets.collect { |x| "#{x.name}-#{x.version}" }.join(' ')}", ""
    print "Proceed with installation (y/n)? "

    exit unless STDIN.gets.chomp =~ /y(es)?/i

################################################################################

    exit # for the time being
  end
end

    ## create the build dir if needed
    #unless Dir.exists? $config.build_directory
      #begin FileUtils.mkdir_p $config.build_directory
      #rescue => e
        #STDERR.puts e.message
        #raise RabbitError, "Could not create #{$config.build_directory}."
      #end
    #end

    #Dir.chdir $config.build_directory do
      #targets.each do |pkg|
        #begin
          #pkg.download if $config.sync_level == :download
          #pkg.extract  if $config.sync_level == :extract

          #if $config.sync_level == :build
            #pkg.build
            #pkg.save_pkgs
          #end

          #if $config.sync_level == :install
            #pkg.build
            #pkg.install
            #pkg.save_pkgs
          #end

        #rescue RabbitNotFoundError => e
          #STDERR.puts e.message

        #rescue RabbitNonError => e
          #STDERR.puts e.message, "Skipping #{pkg.name}."

        #rescue RabbitError => e
          #STDERR.puts e.message
          #exit 1
        #end
      #end
    #end
  #end

  # accepts Packages, returns Packages
  #def self.resolve_dependencies(targets)
    #puts "resolving dependencies..."

    #pac_deps    = []
    #new_targets = targets.reverse!.threaded_each do |pkg|
      #begin
        #targets_new = []

        #args = pkg.pkgbuild.depends.collect { |x| "'#{x}'" }.join(' ')
        #deps = `pacman -T -- #{args}`.split(' ')

        #deps.threaded_each do |ddep|
          #next if pac_deps.include? ddep
          #next if targets.index {|p| p.name == ddep }

          #begin
            #p = find ddep

            #targets     << p # add to master list
            #targets_new << p # store the new ones from this round
          #rescue RabbitNotFoundError
            ## cannot be installed via AUR, hopefully a repo package
            ## todo: check that fact
            #pac_deps << ddep
          #end
        #end

        #targets_new.uniq { |p| p.name }

        #puts %{
          #warning: the following (#{deps[:pacman].length}) packages may be installed by pacman: #{deps[:pacman].join(' ')}
        #}.gsub(/^ +/,'') unless deps[:pacman].empty?

      #rescue RabbitNonError => e
        #STDERR.print "#{pkg.name}: #{e}\n"
        #next

      #rescue RabbitError => e
        #STDERR.print "#{pkg.name}: #{e}\n"
        #exit 1
      #end
    #end

    #unless new_targets.empty?
      #new_deps  = find_all_deps new_targets.flatten
      #targets  += new_deps[:targets]
      #pac_deps += new_deps[:pacman]
    #end

    ## use uniq to account for the non-thread-safeness of this whole
    ## approach...
    #return { :targets => targets.uniq { |p| p.name }.reverse,
              #:pacman => pac_deps.uniq.reverse }
  #end
#end
