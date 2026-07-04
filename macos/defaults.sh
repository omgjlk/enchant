#!/usr/bin/env bash
# macOS system defaults — idempotent. Add new spells as you discover them.
#
# To discover the current value of any setting:
#   defaults read <domain> <key>
#
# To diff the whole defaults system before/after a UI change:
#   defaults read > /tmp/before
#   # ...flip the toggle in System Settings...
#   defaults read > /tmp/after
#   diff /tmp/before /tmp/after

set -euo pipefail

osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true

# --- Keyboard ---------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Remap Caps Lock -> Escape for ALL keyboards (the special "-1-0" key applies
# globally regardless of a keyboard's vendor/product id, covering built-in and
# external keyboards). The HID usage codes are:
#   Caps Lock = 30064771129 (0x700000039)
#   Escape    = 30064771113 (0x700000029)
# Persist the setting (takes effect at next login / keyboard reconnect)...
defaults -currentHost write -g "com.apple.keyboard.modifiermapping.-1-0" -array \
  '{ HIDKeyboardModifierMappingDst = 30064771113; HIDKeyboardModifierMappingSrc = 30064771129; }'
# ...and apply immediately for the current session so no logout is needed.
hidutil property --set \
  '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}' \
  >/dev/null 2>&1 || true

# --- Finder -----------------------------------------------------------------
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Dock -------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false

# --- Screenshots ------------------------------------------------------------
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"

# --- Trackpad ---------------------------------------------------------------
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# --- Safety -----------------------------------------------------------------
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

for app in Finder Dock SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done

echo "macOS defaults applied. Some changes require a logout/restart."
