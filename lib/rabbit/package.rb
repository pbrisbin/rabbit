module Rabbit
  # main Package datatype -- has a name, version and a PkgBuild. TODO:
  # methods to download, build, install, etc.
  class Package
    extend Json

    attr_reader :name, :version, :pkg_build

    private_class_method :new

    def to_s; name end

    # create a Package from the result hash returned by the rpc's search
    # or multiinfo methods
    def init_from_json(result)
      @name = result.Name
      @version = result.Version

      url = "http://aur.archlinux.org/packages/#{@name[0..1]}/#{@name}/PKGBUILD"
      @pkg_build = PkgBuild.new(url)

      self
    end

    # find a single package by name or return nil
    def self.find(name)
      retry_count = 10 # aur flakeyness

      results = fetch_json(url_for_info([name]))
      return nil if results.empty?

      pkg = new
      pkg.init_from_json(results.first)

    rescue => ex
      if retry_count > 0
        retry_count -= 1
        retry
      else
        $stderr.puts "error finding #{name}: #{ex}"
      end

      nil
    end

    # find all packages with newer versions available on the aur. for
    # now just prints what's available
    def self.upgrades
      pkgs = {}

      `pacman -Qm`.split("\n").threaded_each do |line|
        pkg, version = line.split(' ')
        pkgs[pkg] = version
      end

      return [] if pkgs.empty?

      available = fetch_json(url_for_info(pkgs.keys)) do |result|
        name    = result['Name']
        version = result['Version']
        local   = pkgs[name]

        vercmp(version, local) == 1 ? result : nil
      end

      return [] if available.empty?

      available.threaded_each do |result|
        pkg = new
        pkg.init_from_json(result)
      end
    end

    private

    def self.vercmp(a, b)
      `vercmp #{a} #{b}`.to_i rescue 0
    end
  end

  # a PkgBuild can be downloaded and parsed for depends and make depends
  class PkgBuild
    def initialize(url)
      @url = url
    end

    def download
      unless @content
        require 'net/http'
        resp = Net::HTTP.get_response(URI.parse(@url))
        @content = resp.body
      end

      @content
    rescue => ex
      $stderr.puts "#{ex}"
      @content = ''
    end

    def depends;     @depends     ||= parse('depends')     end
    def makedepends; @makedepends ||= parse('makedepends') end

    private

    def parse(key)
      content = download

      deps = []
      if content =~ /(^|\s)#{key}=\((.*?)\)/m
        # remove inline comments, join multiline statements, split on
        # whitespace, pull out just the package name from a variety of
        # quoting and/or version bounds
        deps = $2.split(/#.*?\n/m).join.split(/[\s]+/).collect do |dep|
          dep =~ /("|')([^><=]*)[><=]{0,2}.*\1/ ? $2 : dep
        end

        deps.delete ""
      end

      deps
    end
  end
end
