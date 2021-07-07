MicroMusic
==========

When I think of a minimalist music player, I think of something that has a queue of music to play, plays music, and has a nice, minimal, out-of-your-way interface.

However, when I search for minimalist music players, I get things like `cmus`, `mpd` and friends, etc., which are actually kind of bloated.

So this here is my take on a truly minimalist music player. It has less than 200 lines of shell script code.

Dependencies
------------

We need the following dependencies:

- [`mpv`](https://mpv.io/)
- [`socat`](https://linux.die.net/man/1/socat)
- [`jq`](https://stedolan.github.io/jq/)

Installation
------------

If you want to install to `/usr/bin/`, then run

```sh
sudo ./install.sh
```

If you want to install to `~/.local/bin/`, then run

```sh
./install.sh
```

If you want to install to `$YOUR_OWN_PATH/bin/`, then you can run

```sh
PREFIX="$YOUR_OWN_PATH" ./install.sh
```

Usage
-----

TODO
