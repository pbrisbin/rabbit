class Pkgbuild
  attr_reader :depends, :makedepends

  # argument is the pkgbuild contents as a string
  def initialize pkgbuild
    @pkgbuild = pkgbuild
  end

  def parse!
    @depends     = parse_bash_array :depends
    @makedepends = parse_bash_array :makedepends
  end

  private

  def parse_bash_array varname
    if @pkgbuild =~ /(^|\s)#{varname.to_s}=\((.*?)\)/m
      # remove inline comments, join multiline statements, split on
      # whitespace, pull out just the package name from a variety of
      # quoting and/or version bounds
      items = $2.split(/#.*?\n/m).join.split(/[\s]+/).collect do |item|
        if item =~ /("|')([^><=]*)[><=]{0,2}.*\1/
          $2
        else
          item
        end
      end

      items.delete ""
      items
    else
      []
    end
  end
end
