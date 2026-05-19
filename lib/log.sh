# Tiny logging helpers for enchant.

if [[ -t 1 ]]; then
  _C_RESET=$'\033[0m'
  _C_DIM=$'\033[2m'
  _C_BLUE=$'\033[34m'
  _C_GREEN=$'\033[32m'
  _C_YELLOW=$'\033[33m'
  _C_RED=$'\033[31m'
else
  _C_RESET=""; _C_DIM=""; _C_BLUE=""; _C_GREEN=""; _C_YELLOW=""; _C_RED=""
fi

log()  { printf '%s•%s %s\n' "$_C_BLUE"  "$_C_RESET" "$*"; }
ok()   { printf '%s✓%s %s\n' "$_C_GREEN" "$_C_RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$_C_YELLOW" "$_C_RESET" "$*" >&2; }
fail() { printf '%s✗%s %s\n' "$_C_RED" "$_C_RESET" "$*" >&2; exit 1; }
