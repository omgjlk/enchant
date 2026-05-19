# enchant

> Turn a bare macOS laptop into your fully equipped dev machine — idempotently.

`enchant` is a small, opinionated bootstrapper. It is the spiritual successor to
[`ansibox`](https://github.com/omgjlk/ansibox): same goal, far less ceremony.

It composes three modern, boring tools:

| Concern              | Tool                                                |
| -------------------- | --------------------------------------------------- |
| Packages & apps      | [`brew bundle`](https://github.com/Homebrew/homebrew-bundle) via `Brewfile` |
| Dotfiles             | [`chezmoi`](https://www.chezmoi.io/) backed by `omgjlk/dotfiles` |
| macOS system defaults| `defaults write` script (`macos/defaults.sh`)       |

Everything is idempotent: re-run any time, on any laptop.

## Quick start (new laptop)

```sh
# 1. Install git via Xcode CLT prompt (one click — enchant handles this).
# 2. Clone:
git clone https://github.com/omgjlk/enchant.git ~/src/enchant
cd ~/src/enchant
# 3. Cast:
./enchant
```

That's it. You will be prompted by macOS for Xcode CLT and possibly for
dotfiles repo access (which uses your SSH key).

## Subcommands

```sh
./enchant           # cast the full ritual (default)
./enchant brew      # only sync Homebrew from Brewfile
./enchant defaults  # only apply macOS defaults
./enchant dotfiles  # only sync dotfiles via chezmoi
./enchant doctor    # show what's installed but missing from Brewfile
```

## The discovery loop

When you find something on your laptop that isn't tracked yet:

### Found a new package or app
```sh
brew install <thing>           # or: brew install --cask <thing>
brew bundle dump --force       # rewrite Brewfile from current state
git add Brewfile && git commit -m "add <thing>"
```

`enchant doctor` will also list installed leaves/casks that aren't yet in
the Brewfile, so you can audit drift.

### Found a new dotfile
```sh
chezmoi add ~/.some-new-rc
chezmoi cd                     # opens the dotfiles repo
git add . && git commit -m "add some-new-rc" && git push
```

### Found a new macOS preference
1. `defaults read > /tmp/before`
2. Toggle the setting in System Settings.
3. `defaults read > /tmp/after && diff /tmp/before /tmp/after`
4. Add the resulting `defaults write` line to `macos/defaults.sh`.

## Layout

```
enchant/
├── enchant             # entry-point shell script
├── Brewfile            # packages, casks, taps, VS Code ext, go installs
├── lib/log.sh          # shared logging helpers
├── macos/defaults.sh   # system preferences
└── README.md
```

## Why not Ansible / Nix / dotbot?

- **Ansible** (ansibox) works but is heavy for one laptop; needs Python to
  bootstrap itself, and `homebrew_*` modules lag behind `brew bundle`.
- **Nix + home-manager** is the most powerful option but a substantial
  learning investment and reproducibility tradeoff.
- **dotbot / yadm / bare-repo** handle dotfiles but not packages.

`brew bundle` + `chezmoi` covers 95% of "make this laptop mine" with two
boring, well-maintained tools and zero glue.
