# Bootstrap a new macOS laptop with enchant

The full ritual, top to bottom. Estimated wall time: **20–40 minutes**, mostly
unattended (Homebrew downloads).

> Run these on the **new** laptop unless explicitly told otherwise.

## 1. Open Terminal

Fresh macOS opens with stock zsh. That's fine for bootstrap — we only need
git and ssh to get going.

## 2. Bring your SSH keys over from the old laptop

Skip this section only if you want to generate brand-new keys and update
everywhere that trusts the old ones (GitHub, deploy keys, signing key in
`~/.gitconfig`, internal infra…). Most of the time, copying is easier.

### On the **old** laptop:
```sh
cd ~
tar -czf ssh-keys.tar.gz \
  --exclude='.ssh/config' \
  --exclude='.ssh/sockets' \
  --exclude='.ssh/controlmasters' \
  --exclude='.ssh/known_hosts.old' \
  .ssh
```
Then **AirDrop** `~/ssh-keys.tar.gz` to the new laptop. (AirDrop is device-
to-device encrypted; preferable to any cloud transit.)

> `.ssh/config` is excluded on purpose — chezmoi will install the canonical
> one in step 5. No conflict that way.

### On the **new** laptop:
```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
tar -xzf ~/Downloads/ssh-keys.tar.gz -C ~
chmod 600 ~/.ssh/id_* 2>/dev/null
chmod 644 ~/.ssh/*.pub 2>/dev/null
chmod 644 ~/.ssh/authorized_keys ~/.ssh/known_hosts 2>/dev/null

# Verify GitHub trusts the key:
ssh -T git@github.com    # expect: "Hi omgjlk! ..."

# Securely delete the tarball once verified:
rm -P ~/Downloads/ssh-keys.tar.gz
```

### Optional: persist passphrases in Keychain
If any of your keys have a passphrase, add them once via:
```sh
ssh-add --apple-use-keychain ~/.ssh/id_rsa     # for each passphrased key
```

## 3. Clone enchant

`enchant` is public — no auth needed.

```sh
mkdir -p ~/src
git clone https://github.com/omgjlk/enchant.git ~/src/enchant
cd ~/src/enchant
```

> If `git` isn't installed, this triggers the **Xcode Command Line Tools**
> install prompt — click through, wait, then re-run.

## 4. Cast the ritual

```sh
./enchant all
```

What happens, in order:

1. **Xcode CLT** — verified / installed (skipped if already present)
2. **Homebrew** — installed if missing
3. **`brew bundle`** — installs everything in `Brewfile`: formulae, casks,
   VS Code extensions. The bulk of the runtime.
4. **`macos/defaults.sh`** — applies system preferences (key repeat, Finder,
   Dock, screenshots, lock screen, …)
5. **chezmoi** — installs if missing, then `chezmoi init
   git@github.com:omgjlk/dotfiles.git` and `chezmoi apply`. Drops your
   bash/git/vim/ssh dotfiles into `$HOME`.

If any single step fails, fix the cause and re-run `./enchant all` (or just
the failed subcommand, e.g. `./enchant brew`). Everything is idempotent.

## 5. Switch the login shell

```sh
./enchant shell
```

Adds `/opt/homebrew/bin/bash` to `/etc/shells` (sudo prompt), then `chsh`'s
your login shell to it. Open a **new** terminal window to take effect.

You should land in modern bash with:
- Git-aware colored prompt
- 100k-entry shared history across panes (PROMPT_COMMAND + atuin Ctrl-R)
- Tab completion for hundreds of tools (bash-completion@2)
- fzf: Ctrl-T (files), Ctrl-R (atuin overrides), `**<Tab>` (path fuzz)

## 6. Re-auth the tools chezmoi intentionally didn't sync

These are excluded by `.chezmoiignore` because each tool manages its own
auth state per-machine:

| Tool | Re-auth command |
|---|---|
| GitHub CLI | `gh auth login` |
| Azure CLI | `az login` |
| Docker / OrbStack / Docker Desktop | sign in via the app |
| 1Password | open the app, sign in |
| Slack, Discord, Spotify, Dropbox, Fantastical, Signal | open each app, sign in |
| Tailscale | open the Tailscale.app, sign in |

## 7. macOS Gatekeeper

First launch of each cask app may prompt with "downloaded from the
internet" or be blocked entirely. Approve via:
**System Settings → Privacy & Security → "Open Anyway"** as needed.

## 8. Discovery loop — when you find something missing

The whole point of enchant. When you discover a tool, app, or config that
isn't tracked yet:

### A new Homebrew package
```sh
brew install <thing>           # or: brew install --cask <thing>
cd ~/src/enchant
brew bundle dump --force       # rewrite Brewfile from current state
# review the diff, prune any auto-captured noise, then:
git add Brewfile && git commit -m "add <thing>" && git push
```

### A new dotfile
```sh
chezmoi add ~/.some-new-rc
chezmoi cd                     # opens ~/.local/share/chezmoi as a shell
git add . && git commit -m "add some-new-rc" && git push
```

### A new macOS preference
```sh
defaults read > /tmp/before
# toggle the setting in System Settings
defaults read > /tmp/after && diff /tmp/before /tmp/after
# add the resulting `defaults write …` line to macos/defaults.sh in enchant
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `ssh -T git@github.com` says "Permission denied" | Key not present or not added to the agent. Re-run step 2 carefully, or run `ssh-add ~/.ssh/<your_key>`. |
| `chezmoi init` fails with "Repository not found" | Confirm `omgjlk/dotfiles` is accessible — it's a **private** repo, you need the SSH key from step 2. |
| `brew bundle` fails on a cask with "macOS too old" / "depends on…" | Open the failing cask's page on `formulae.brew.sh`, see if a `--no-quarantine` or formula bump is needed. Skip with `brew "name", link: :force` etc. and revisit later. |
| Login shell didn't change | `dscl . -read /Users/$USER UserShell` confirms current value. Re-run `./enchant shell` or manually `chsh -s /opt/homebrew/bin/bash`. |
| `.gitconfig` references `/usr/local/share/gcm-core/...` (Intel path) | Known stale. Either edit `~/.local/share/chezmoi/dot_gitconfig` to remove that line / replace with `helper = manager` if you re-add GCM, or ignore (git falls back to `osxkeychain` which works for github.com). |

## Rollback

Almost everything is reversible:

- **Dotfiles**: `chezmoi diff` shows what changed; `rm ~/.bash_profile ~/.bashrc ~/.inputrc` removes the new bash files.
- **Login shell**: `chsh -s /bin/zsh` (default macOS shell).
- **Brew packages**: `brew uninstall <name>` per package, or comment out lines in `Brewfile`.
- **macOS defaults**: most are reversed by flipping the toggle back in System Settings.

The only one that's awkward to undo is `xcode-select --install`, but you
likely want it anyway.
