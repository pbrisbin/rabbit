> [!NOTE]
> All of my GitHub repositories have been **archived** and will be migrated to
> Codeberg as I next work on them. This repository either now lives, or will
> live, at:
>
> https://codeberg.org/pbrisbin/rabbit
>
> If you need to report an Issue or raise a PR, and this migration hasn't
> happened yet, send an email to me@pbrisbin.com.

# Rabbit

I'm re-writing [aurget][] in ruby. This is purely as a learning exercise to 
get me up to speed with ruby for my new job.

I have no idea how far I'm going to take it. Right now it's just 
something to play with.

## Installation

If you're so inclined...

    git clone https://github.com/pbrisbin/rabbit
    rake install

**Note that it's not always in a working state.**

[aurget]: https://github.com/pbrisbin/aurget

## Speedup?

    $ time echo n | aurget -S haskell-yesod &>/dev/null

    real    0m57.294s
    user    0m7.276s
    sys     0m3.160s

    $ time rabbit -S haskell-yesod &>/dev/null

    real    0m9.160s
    user    0m8.519s
    sys     0m10.409s

    $ time echo n | aurget -Syu &>/dev/null

    real    0m15.536s
    user    0m1.673s
    sys     0m0.463s

    $ time rabbit -Syu &>/dev/null

    real    0m0.551s
    user    0m0.247s
    sys     0m0.073s

    $ time aurget -Ss python &>/dev/null

    real    0m1.420s
    user    0m0.673s
    sys     0m0.227s

    $ time rabbit -Ss python &>/dev/null

    real    0m3.360s
    user    0m2.250s
    sys     0m0.127s
