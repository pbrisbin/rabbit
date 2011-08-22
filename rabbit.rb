#!/usr/bin/ruby
#
# rabbit. an aur-helper in ruby.
#
# This is a toy. There is currently little to no:
#
#   * Features
#   * Error handling
#   * Configuration
#
###
require_relative 'lib/aursearch'
require_relative 'lib/package'

def process_targets targets
  targets.each do |pkg|
    puts "installing #{pkg.name} - #{pkg.version}..."

    pkg.download
    pkg.extract
    pkg.build
    pkg.install
  end
end

case ARGV[0]
  when '-S'
    pkg = Package.find ARGV[1]
    process_targets [pkg] if pkg

  when '-Syu'
    to_update = []

    `pacman -Qm`.lines.each do |output|
      name, version = output.split(' ')

      pkg = begin Package.find name
            rescue
              nil
            end

      if pkg
        comp = `vercmp #{version} #{pkg.version}`.to_i
        case comp
        when  1; STDERR.puts "warning: #{name}, local (#{version}) is newer than aur (#{pkg.version})"
        when -1
          to_update << pkg
        end
      end
    end

    process_targets to_update

  when '-Ss' ; AurSearch.new(ARGV[1]       ).show_results
  when '-Ssi'; AurSearch.new(ARGV[1], :info).show_results

  else
    puts "usage: rabbit [ -S <pkg> | -Syu | -Ss <term> | -Ssi <term> ]"
end
