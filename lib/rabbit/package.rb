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
  class SkipError     < StandardError; end
  class FatalError    < StandardError; end

  class AurPackage
    attr_accessor :name, :version, :base_url, :archive

    # returns an array of AurPackages
    def self.init_from_json(json, &block)
      pkgs = []

      if json.hask_key?('results') && json['results'].class == Array && !json['results'].empty?
        json['results'].threaded_each do |result|
          next if block_given? && !block.call(result)

          pkg = AurPackage.new

          pkg.name       = result['Name']
          pkg.version    = result['Version']
          pkg.base_url   = File.dirname(result['URLPath'])
          pkg.archive    = File.basename(result['URLPath'])
          pkg.pkgbuild   = nil
          pkg.built_pkgs = nil

          pkgs << pkg
        end
      end

      pkgs
    end

    def self.find_pkgs(names, &block)
      pkgs = []
      url = AurSearch.json_request_url(:info, names.join(' '))
      raise NotFoundError unless url

      AurSearch.with_json_response(url) do |json|
        pkgs = init_from_json(json, &block)
      end

      if pkgs.length != names.length
        missing = names - pkgs.map(&:name)
        raise NotFoundError, "Package(s) #{missing.join(', ')} not found"
      end

      pkgs
    end

    def self.find(name)
      pkgs = find_pkgs([name]) # throws NotFoundError
      pkgs.first

    rescue => e
      puts e.full_message
      raise SkipError, "Package #{name} will be skipped."
    end

    def pkgbuild
      unless @pkgbuild
        url  = @base_url + '/PKGBUILD'
        resp = Net::HTTP.get_response(URI.parse(url))
        @pkgbuild = Pkgbuild.new(resp.body)
      end

      @pkgbuild

    rescue => e
      puts e
      raise SkipError, "Failure downloading PKGBUILD for #{@pkg.name}"
    end

    #def built_pkgs
      #unless @built_pkgs
        #@built_pkgs = []

        #Dir.glob("#{@name}/*") do |fp|
          #@built_pkgs << fp if fp =~ /.*\.pkg\.tar\.[gx]z$/
        #end
      #end

      #@built_pkgs
    #end

    #def download
      #archive_url = "#{@base_url}/#{@archive}"

      #a = open(archive_url)
      #f = open(@archive, "wb")
      #f.write(a.read)

    #rescue => e
      #STDERR.puts e.message
      #raise SkipError
    #ensure
      #a.close
      #f.close
    #end

    #def extract
      #unless File.exists? @archive
        #begin download
        #rescue SkipError => e
          #STDERR.puts e.message
          #return
        #end
      #end

      #raise SkipError unless system "tar xzf \"#{@archive}\""

      #File.delete @archive if $config.discard_tarball
    #end

    #def build
      #unless File.exists? "#{@name}/PKGBUILD"
        #begin extract
        #rescue SkipError => e
          #STDERR.puts e.message
          #return
        #end
      #end

      #Dir.chdir @name do
        #raise SkipError unless File.exists? 'PKGBUILD'
        #raise SkipError unless system $config.makepkg

        ## maybe discard the sources
        #if $config.discard_sources
          #Dir.glob("./*") do |fp|
            ## keep built packages
            #FileUtils.rm_rf fp unless fp =~ /.*\.pkg\.tar\.[gx]z$/
          #end
        #end
      #end
    #end

    #def save_pkgs
      #unless Dir.exists? $config.package_directory
        #begin FileUtils.mkdir_p $config.package_directory
        #rescue => e
          #@built_pkgs = [] # so we don't try to save them
          #STDERR.puts e.message
          #raise SkipError
        #end
      #end

      #built_pkgs.each do |pkg|
        #begin
          #from = open(pkg, "rb")
          #to   = open("#{$config.package_directory}/#{File.basename pkg}", "wb")
          #to.write(from.read)

          #File.delete pkg
        #rescue => e
          #STDERR.puts e.message
          #raise SkipError
        #ensure
          #from.close
          #to.close
        #end
      #end

      ## silently ignore
      #Dir.delete @name rescue Errno::ENOTEMPTY
    #end

    #def install
      #args = built_pkgs.collect { |a| "'#{a}'" }.join(' ')
      #raise SkipError unless system "#{$config.pacman} #{args}"
      #built_pkgs.each { |pkg| File.delete pkg } if $config.discard_package
    #end
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
  end

  #def self.install names
    #targets = []

    #names.each do |name|
      #begin
        #targets << find(name)
      #rescue RabbitNotFoundError
        #STDERR.puts "#{name}: package not found"
      #end
    #end

    #process_targets targets unless targets.empty?
  #end

  # accepts Packages, returns nothing
  def self.process_targets(targets)
    #if $config.resolve_deps
      #puts "resolving dependencies..."

      #deps = find_all_deps targets

      #puts %{
        #warning: the following (#{deps[:pacman].length}) packages may be installed by pacman: #{deps[:pacman].join(' ')}
      #}.gsub(/^ +/,'') unless deps[:pacman].empty?

      #targets = deps[:targets]
    #end

    print %{
      #Targets (#{targets.length}): #{targets.collect { |x| "#{x.name}-#{x.version}" }.join(' ')}

      #Proceed with installation (y/n)? }.gsub(/^ +/,'')

    exit
    exit unless STDIN.gets.chomp =~ /y(es)?/i
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

  # accepts Packages, returns { :targets => Packages, :pacman => names }
  #def self.find_all_deps targets
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

end
