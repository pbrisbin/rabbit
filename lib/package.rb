require 'find'
require 'open-uri'

require_relative 'aursearch'

class Package
  attr_reader :name, :version, :pkg_url

  def initialize name, version, pkg_url
    @name         = name
    @version      = version
    @pkg_url      = pkg_url
    @archive_path = File.basename(@pkg_url)
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
    begin
      puts "Downloading #{@pkg_url}..."
      f = open(@archive_path, "wb")
      f.write(open(@pkg_url).read)
      f.close
    rescue
      STDERR.puts "Error downloading the package"
      raise
    end
  end

  def extract
    puts "Extracting #{@archive_path}..."
    unless system "tar xzf \"#{@archive_path}\""
      STDERR.puts "Tar threw an error"
      raise
    end
  end

  def build
    oldpwd = Dir.pwd
    if Dir.exists? @name
      Dir.chdir @name

      if File.exists? 'PKGBUILD'
        puts "Building #{@name}/PKGBUILD..."
        unless system "makepkg"
          STDERR.puts "Makepkg threw an error"
          raise
        end
      end

      Dir.chdir oldpwd
    end
  end

  def install
    if Dir.exists? @name
      Find.find(@name) do |fp|
        if fp =~ /.*\.pkg\.tar\.[gx]z$/
          puts "Installing #{fp}..."
          unless system "sudo pacman -U \"#{fp}\""
            STDERR.puts "Pacman threw an error"
            raise
          end

          return
        end
      end
    end
  end
end
