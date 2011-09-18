class Pkgbuild
  def initialize pkgbuild_contents
    @pkgbuild = pkgbuild_contents
    @depends  = nil
  end

  def depends
    unless @depends
      deps = []
      [:depends, :makedepends].each do |varname|
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
          deps << items
        end
      end

      @depends = deps.flatten
    end

    @depends
  end
end
