# Rabbit

I'm re-writing [aurget][] in ruby. This is purely as a learning exercise to 
get me up to speed with ruby for my new job.

I have no idea how far I'm going to take it. Right now it's just 
something to play with.

I will say this: it's quite a bit faster than aurget:

~~~ 
#
# A simple package with no deps:
#
###
//blue/0/~/ time echo "n" | aurget -S aurget
resolving dependencies...
searching AUR...
warning: aurget-3.3.0-1 is up to date -- reinstalling

Targets (1): aurget-3.3.0-1

Proceed with installation? [Y/n]
real    0m1.009s
user    0m0.220s
sys     0m0.040s
//blue/0/~/ time echo "n" | rabbit.rb -S aurget
resolving dependencies...

Targets (1): aurget

Proceed with installation (y/n)?
real    0m0.325s
user    0m0.097s
sys     0m0.013s

#
# A package with a lot of dependencies:
#
###
//blue/0/~/ time echo "n" | aurget -S haskell-yesod
resolving dependencies...

warning: the following (13) packages will be installed by pacman: ...

searching AUR...

Targets (73): ...

Proceed with installation? [Y/n]
real    1m10.811s
user    0m6.523s
sys     0m2.733s
//blue/0/~/ time echo "n" | rabbit.rb -S haskell-yesod
resolving dependencies...

warning: the following (13) packages may be installed by pacman: ...

Targets (73): ...

Proceed with installation (y/n)?
real    0m20.216s
user    0m1.657s
sys     0m1.387s
~~~

[aurget]: https://github.com/pbrisbin/aurget
