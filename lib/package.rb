require 'open-uri'
require_relative 'aursearch'

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

  def download
    archive_url = "#{@base_url}/#{@archive}"

    begin
      a = open(archive_url)
      f = open(@archive, "wb")

      f.write(a.read)

      a.close
      f.close
    rescue
      STDERR.puts "Error downloading the package"

      a.close
      f.close

      raise
    end
  end

  def extract
    if File.exists? @archive
      unless system "tar xzf \"#{@archive}\""
        STDERR.puts "Tar threw an error"
        raise
      end
    else
      STDERR.puts "#{archive}: file not found"
      raise
    end
  end

  def build
    oldpwd = Dir.pwd
    if Dir.exists? @name
      Dir.chdir @name

      if File.exists? 'PKGBUILD'
        unless system "makepkg"
          STDERR.puts "Makepkg threw an error"
          raise
        end
      else
        STDERR.puts "PKGBUILD: file not found"
        raise
      end

      Dir.chdir oldpwd
    end
  end

  def install
    to_install = []

    # find all built packages
    Dir.glob("#{@name}/*") do |fp|
      to_install << fp if fp =~ /.*\.pkg\.tar\.[gx]z$/
    end

    unless to_install.empty?
      # make a quote separated string of args
      args = to_install.collect { |a| "'#{a}'" }.join(' ')

      # install all of them
      unless system "sudo pacman -U #{args}"
        STDERR.puts "Pacman threw an error"
        raise
      end
    else
      STDERR.puts "No packages found"
      raise
    end
  end
end
