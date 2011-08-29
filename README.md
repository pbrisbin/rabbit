# Rabbit

I'm re-writing [aurget][] in ruby. This is purely as a learning exercise to 
get me up to speed with ruby for my new job.

I have no idea how far I'm going to take it. Right now it's just 
something to play with.

I will say this: it's quite a bit faster than aurget.

~~~ 
$ time echo n | aurget -S haskell-yesod
resolving dependencies...

warning: the following (13) packages will be installed by pacman: ...

searching AUR...

Targets (73): ...

Proceed with installation? [Y/n]
real    1m10.811s
user    0m6.523s
sys     0m2.733s

$ time echo n | ./rabbit.rb -S haskell-yesod
resolving dependencies...

warning: the following (13) packages may be installed by pacman: ...

Targets (73): ...

Proceed with installation (y/n)?
real    0m7.552s
user    0m3.833s
sys     0m3.683s
~~~

[aurget]: https://github.com/pbrisbin/aurget
