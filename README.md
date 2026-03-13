# lawn.sh

`lawn.sh` is a tiny launcher for directory-local `.lawnrc` files.

## Manifest

Each launch target is just a `.lawnrc` file inside the directory you want to launch:

```bash
exec ./launch.sh
```

Because the manifest is plain Bash, awkward launch cases stay simple:

```bash
exec gamescope -f -- umu-run ./game.exe
```

```bash
exec nix run .
```

`lawn.sh` runs the manifest with that directory as the working directory.

## Config

Create `~/.config/lawn.sh/config` or `$XDG_CONFIG_HOME/lawn.sh/config`.

Each non-empty, non-comment line must be an absolute directory path. `lawn.sh` searches every configured root for `.lawnrc` files.

Example:

```text
/mnt/games
/home/pikdum/stuff
```

## Usage

Run the launcher:

```bash
lawn.sh
```

Useful non-interactive commands:

```bash
lawn.sh list
lawn.sh run /absolute/path/to/.lawnrc
```

`list` prints TAB-separated display name and manifest path. Duplicate directory names are disambiguated by appending the full parent path.

## Nix

Package and run it with:

```bash
nix run github:pikdum/lawn.sh
```

Run checks with:

```bash
nix flake check
```
