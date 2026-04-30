#!/bin/bash
set -euo pipefail

# ==============================================================================
# 1. Bootstrap
# ==============================================================================
GOROOT="${GOROOT:-$HOME/.go}"
GOPATH="${GOPATH:-$HOME/go}"
GO_API="https://go.dev/dl/?mode=json"
VERSION_RE='[0-9]+\.[0-9]+(\.[0-9]+)?'

OS="" ARCH="" PLATFORM=""
SHELL_PROFILE=""
FETCHER="" HASHER=""
TEMP_DIR=""

DOWNLOAD_URL="" FILENAME="" CHECKSUM="" LATEST_VERSION=""
ACTION="install" REQUESTED_VERSION=""

RED="" GREEN="" YELLOW="" BLUE="" CYAN="" RESET=""

setup_colors() {
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RED=$(tput setaf 1) GREEN=$(tput setaf 2) YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4) CYAN=$(tput setaf 6) RESET=$(tput sgr0)
  else
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" RESET=""
  fi
}

cleanup() { [ -n "${TEMP_DIR:-}" ] && [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"; true; }
trap cleanup EXIT INT TERM

# ==============================================================================
# 2. Platform Layer
# ==============================================================================
detect_os() {
  case "$(uname -s)" in
    Linux)  OS="linux" ;;
    Darwin) OS="darwin" ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64)        ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv6*)        ARCH="armv6l" ;;
    *386*)         ARCH="386" ;;
    *)             die "Unsupported architecture: $(uname -m)" ;;
  esac
  PLATFORM="${OS}-${ARCH}"
}

detect_shell_profile() {
  [ -n "${SHELL_PROFILE:-}" ] && return 0
  case "$(basename "${SHELL:-/bin/bash}")" in
    zsh)  SHELL_PROFILE="$HOME/.zshrc" ;;
    fish) SHELL_PROFILE="$HOME/.config/fish/config.fish" ;;
    ksh)  SHELL_PROFILE="$HOME/.kshrc" ;;
    bash)
      if [ "$OS" = "darwin" ]; then
        SHELL_PROFILE="$HOME/.bash_profile"
      else
        SHELL_PROFILE="$HOME/.bashrc"
      fi
      ;;
    *)    SHELL_PROFILE="$HOME/.profile" ;;
  esac
}

detect_tooling() {
  if command -v curl >/dev/null 2>&1; then
    FETCHER="curl"
  elif command -v wget >/dev/null 2>&1; then
    FETCHER="wget"
  else
    die "Neither curl nor wget found."
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    HASHER="sha256sum"
  elif command -v shasum >/dev/null 2>&1; then
    HASHER="shasum"
  elif command -v openssl >/dev/null 2>&1; then
    HASHER="openssl"
  else
    HASHER=""
  fi
}

# ==============================================================================
# 3. I/O Layer
# ==============================================================================
log()  { printf '%b\n' "$1"; }
warn() { printf '%b\n' "${YELLOW}WARNING:${RESET} $1" >&2; }
err()  { printf '%b\n' "${RED}ERROR:${RESET} $1" >&2; }
step() { printf '%b\n' "${CYAN}==>${RESET} $1"; }
die()  { err "$1"; exit 1; }

confirm() {
  local msg="$1" default="${2:-n}"
  if [ ! -t 0 ]; then
    [ "$default" = "y" ] && return 0 || return 1
  fi
  local hint="[y/N]"
  [ "$default" = "y" ] && hint="[Y/n]"
  printf '%b ' "${YELLOW}${msg} ${hint}:${RESET}"
  read -r ans
  case "${ans:-$default}" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

fetch() {
  if [ "$FETCHER" = "curl" ]; then
    curl -fsSL --connect-timeout 10 --max-time 30 "$1"
  else
    wget -qO- --timeout=30 "$1"
  fi
}

download() {
  local url="$1" out="$2"
  if [ "$FETCHER" = "curl" ]; then
    curl -fSL --progress-bar --connect-timeout 10 --max-time 300 "$url" -o "$out" || die "Download failed."
  else
    wget --timeout=300 "$url" -O "$out" || die "Download failed."
  fi
}

compute_sha256() {
  case "$HASHER" in
    sha256sum) sha256sum "$1" | awk '{print $1}' ;;
    shasum)    shasum -a 256 "$1" | awk '{print $1}' ;;
    openssl)   openssl dgst -sha256 "$1" | awk '{print $NF}' ;;
  esac
}

verify_checksum() {
  local file="$1" expected="$2"
  if [ -z "$expected" ]; then
    warn "No checksum available for this release."
    confirm "Proceed without verification?" "n" || die "Aborted."
    return 0
  fi
  if [ -z "$HASHER" ]; then
    warn "No hashing tool found (sha256sum, shasum, or openssl)."
    confirm "Proceed without verification?" "n" || die "Aborted."
    return 0
  fi
  step "Verifying checksum..."
  local actual
  actual=$(compute_sha256 "$file")
  if [ "$actual" != "$expected" ]; then
    die "Checksum mismatch.\nExpected: $expected\nActual:   $actual"
  fi
  log "${GREEN}Checksum verified.${RESET}"
}

extract_version() { grep -oE "$VERSION_RE" <<< "$1" | head -1; }

resolve_release() {
  local req="$1"
  local url="$GO_API"
  [ -n "$req" ] && url="${GO_API}&include=all"

  step "Fetching release info..."
  local json
  json=$(fetch "$url") || die "Failed to reach Go release API."

  if [ -n "$req" ]; then
    FILENAME="go${req}.${PLATFORM}.tar.gz"
    printf '%s' "$json" | grep -q "\"filename\" *: *\"$FILENAME\"" \
      || die "No Go release found for version $req on platform $PLATFORM."
  else
    FILENAME=$(printf '%s' "$json" | grep -oE "\"filename\" *: *\"go${VERSION_RE}\.${PLATFORM}\.tar\.gz\"" | head -1 | awk -F'"' '{print $4}') || true
  fi

  [ -z "$FILENAME" ] && die "No Go release found for ${req:+version $req on }$PLATFORM."

  CHECKSUM=$(printf '%s' "$json" | grep -A5 "\"filename\" *: *\"$FILENAME\"" | grep -oE '"sha256" *: *"[a-f0-9]+"' | head -1 | awk -F'"' '{print $4}') || true
  LATEST_VERSION="${req:-$(extract_version "$FILENAME")}"
  DOWNLOAD_URL="https://go.dev/dl/${FILENAME}"
}

# ==============================================================================
# 4. Action Layer
# ==============================================================================
download_and_stage() {
  step "Downloading Go $LATEST_VERSION for $PLATFORM..."
  local tarball="$TEMP_DIR/$FILENAME"
  download "$DOWNLOAD_URL" "$tarball"
  verify_checksum "$tarball" "$CHECKSUM"

  step "Extracting..."
  tar -xzf "$tarball" -C "$TEMP_DIR" || die "Extraction failed."
  GOROOT="$TEMP_DIR/go" "$TEMP_DIR/go/bin/go" version >/dev/null 2>&1 || die "Staged binary failed to execute."
}

update_shell_profile() {
  local begin_marker="# >>> go.sh managed block >>>"
  local end_marker="# <<< go.sh managed block <<<"
  local block

  mkdir -p "$(dirname "$SHELL_PROFILE")"
  [ -f "$SHELL_PROFILE" ] || touch "$SHELL_PROFILE"

  case "$(basename "${SHELL:-/bin/bash}")" in
    fish)
      block=$(printf '%s\n' \
        "$begin_marker" \
        "set -gx GOROOT $GOROOT" \
        "set -gx GOPATH $GOPATH" \
        "set -gx PATH \$PATH $GOROOT/bin $GOPATH/bin" \
        "$end_marker")
      ;;
    *)
      block=$(printf '%s\n' \
        "$begin_marker" \
        "export GOROOT=$GOROOT" \
        "export GOPATH=$GOPATH" \
        'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' \
        "$end_marker")
      ;;
  esac

  step "Updating $SHELL_PROFILE..."
  if grep -Fq "$begin_marker" "$SHELL_PROFILE"; then
    local tmpfile
    tmpfile=$(mktemp 2>/dev/null || mktemp -t go-profile)
    awk -v begin="$begin_marker" -v end="$end_marker" -v replacement="$block" '
      $0 == begin {
        print replacement
        in_block = 1
        next
      }
      $0 == end {
        in_block = 0
        next
      }
      !in_block { print }
    ' "$SHELL_PROFILE" > "$tmpfile"
    mv "$tmpfile" "$SHELL_PROFILE"
  else
    printf '\n%s\n' "$block" >> "$SHELL_PROFILE"
  fi
}

action_install() {
  download_and_stage

  step "Installing to $GOROOT..."
  mkdir -p "$GOPATH"/{src,pkg,bin}
  mkdir -p "$(dirname "$GOROOT")"
  if [ -e "$GOROOT" ]; then
    [ -d "$GOROOT" ] || die "$GOROOT exists and is not a directory."
    rm -rf "$GOROOT" || die "Failed to remove existing $GOROOT."
  fi
  mv "$TEMP_DIR/go" "$GOROOT" || die "Failed to install to $GOROOT."

  update_shell_profile

  local v
  v=$("$GOROOT/bin/go" version | grep -oE "$VERSION_RE" | head -1)
  step "${GREEN}Go $v installed successfully.${RESET}"
  log "Run: ${YELLOW}source $SHELL_PROFILE${RESET}"
}

action_update() {
  local current

  if [ ! -f "$GOROOT/bin/go" ]; then
    die "No Go installation found at $GOROOT. Run without 'update' to install."
  fi

  current=$(extract_version "$("$GOROOT/bin/go" version 2>/dev/null || true)")

  log "Installed: ${current:-none}"
  log "Available: $LATEST_VERSION"

  if [ "$current" = "$LATEST_VERSION" ]; then
    step "Already on Go $current — nothing to do."
    return 0
  fi

  confirm "Switch from $current to $LATEST_VERSION?" "y" || die "Cancelled."

  download_and_stage

  step "Backing up current installation..."
  local backup="${GOROOT}.bak"
  rm -rf "$backup"
  mv "$GOROOT" "$backup" || die "Backup failed."

  step "Installing new version..."
  mkdir -p "$(dirname "$GOROOT")"
  if mv "$TEMP_DIR/go" "$GOROOT"; then
    rm -rf "$backup"
    update_shell_profile
    step "${GREEN}Updated to Go $LATEST_VERSION.${RESET}"
  else
    err "Install failed — rolling back..."
    rm -rf "$GOROOT" 2>/dev/null
    mv "$backup" "$GOROOT" || die "Rollback failed. Previous version at: $backup"
    die "Update failed. Previous version restored."
  fi
}

action_remove() {
  step "Removing Go from $GOROOT..."

  if [ "$GOROOT" = "/" ] || [ "$GOROOT" = "$HOME" ]; then
    die "Refusing to remove suspicious GOROOT: $GOROOT"
  fi
  local depth
  depth=$(printf '%s' "$GOROOT" | tr -cd '/' | wc -c | tr -d ' ')
  [ "$depth" -lt 2 ] && die "Refusing to remove suspicious GOROOT: $GOROOT"

  if [ ! -f "$GOROOT/bin/go" ]; then
    step "No Go installation found at $GOROOT — nothing to do."
    return 0
  fi

  if ! "$GOROOT/bin/go" version >/dev/null 2>&1; then
    step "Go installation at $GOROOT is not usable — nothing to do."
    return 0
  fi

  chmod -R u+w "$GOROOT" 2>/dev/null || true
  rm -rf "$GOROOT" || die "Failed to remove $GOROOT."

  if [ -f "$SHELL_PROFILE" ]; then
    local begin_marker="# >>> go.sh managed block >>>"
    local end_marker="# <<< go.sh managed block <<<"
    if grep -Fq "$begin_marker" "$SHELL_PROFILE"; then
      step "Cleaning $SHELL_PROFILE..."
      local tmpfile
      tmpfile=$(mktemp 2>/dev/null || mktemp -t go-profile)
      cp "$SHELL_PROFILE" "${SHELL_PROFILE}.bak"
      awk -v begin="$begin_marker" -v end="$end_marker" '
        $0 == begin { in_block = 1; next }
        $0 == end   { in_block = 0; next }
        !in_block   { print }
      ' "$SHELL_PROFILE" > "$tmpfile"
      mv "$tmpfile" "$SHELL_PROFILE"
    fi
  fi

  step "${GREEN}Go removed.${RESET}"
}

go_exists() { [ -x "$GOROOT/bin/go" ]; }

# ==============================================================================
# 5. Main
# ==============================================================================
print_banner() {
  printf '%b' "${CYAN}
\t  ____  ___       ___ _   _ ____ _____  _    _     _     _____ ____  
\t / ___|/ _ \\     |_ _| \\ | / ___|_   _|/ \\  | |   | |   | ____|  _ \\ 
\t| |  _| | | |_____| ||  \\| \\___ \\ | | / _ \\ | |   | |   |  _| | |_) |
\t| |_| | |_| |_____| || |\\  |___) || |/ ___ \\| |___| |___| |___|  _ < 
\t \\____|\\___/     |___|_| \\_|____/ |_/_/   \\_\\_____|_____|_____|_| \\_\\\\
\t ${RESET}
"
}

print_help() {
  cat <<EOF
  ${BLUE}go.sh${RESET} — install, update, or remove Go

  ${GREEN}Usage:${RESET}
    ${YELLOW}bash go.sh${RESET}                      Install or update Go (latest)
    ${YELLOW}bash go.sh --version <ver>${RESET}       Install a specific version
    ${YELLOW}bash go.sh update${RESET}                Update to latest version
    ${YELLOW}bash go.sh remove${RESET}                Uninstall Go
    ${YELLOW}bash go.sh help${RESET}                  Show this message
EOF
}

parse_args() {
  case "${1:-}" in
    remove)          ACTION="remove" ;;
    update)          ACTION="install" ;;
    help|--help|-h)  ACTION="help" ;;
    --version)
      [ -n "${2:-}" ] || die "Usage: bash go.sh --version <version>"
      REQUESTED_VERSION="$2"
      ;;
    "") ;;
    *)  print_help; exit 1 ;;
  esac
}

main() {
  setup_colors
  parse_args "$@"

  if [ "$ACTION" = "help" ]; then
    print_banner
    print_help
    exit 0
  fi

  print_banner
  TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t go-installer)

  detect_os
  detect_arch
  detect_shell_profile
  detect_tooling

  if [ "$ACTION" = "remove" ]; then
    action_remove
    exit 0
  fi

  resolve_release "$REQUESTED_VERSION"

  if go_exists; then
    action_update
  else
    action_install
  fi
}

main "$@"
