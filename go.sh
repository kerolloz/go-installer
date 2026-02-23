#!/bin/bash
set -euo pipefail

# --- Colors (disabled when not connected to a terminal) ---
if [ -t 1 ]; then
  RED=$(tput setaf 1) GREEN=$(tput setaf 2) YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4) CYAN=$(tput setaf 6) RESET=$(tput sgr0)
else
  RED="" GREEN="" YELLOW="" BLUE="" CYAN="" RESET=""
fi

GOROOT="${GOROOT:-/usr/local/go}"
GOPATH="${GOPATH:-$HOME/go}"
VERSION_REGEX='[0-9]+\.[0-9]+\.[0-9]+'
GO_API="https://go.dev/dl/?mode=json"

# --- Helpers ---

die() { echo "${RED}$1${RESET}" >&2; exit 1; }

print_welcome() {
  echo -e "${CYAN}
\t  ____  ___       ___ _   _ ____ _____  _    _     _     _____ ____  
\t / ___|/ _ \\     |_ _| \\ | / ___|_   _|/ \\  | |   | |   | ____|  _ \\ 
\t| |  _| | | |_____| ||  \\| \\___ \\ | | / _ \\ | |   | |   |  _| | |_) |
\t| |_| | |_| |_____| || |\\  |___) || |/ ___ \\| |___| |___| |___|  _ < 
\t \\____|\\___/     |___|_| \\_|____/ |_/_/   \\_\\_____|_____|_____|_| \\_\\\\
\t ${RESET}"
}

print_help() {
  cat <<EOF
  ${BLUE}go.sh${RESET} – easily install, update or uninstall Go

  ${GREEN}Usage:${RESET}
    ${YELLOW}bash go.sh${RESET}                      Install or update Go
    ${YELLOW}bash go.sh --version <ver>${RESET}       Install a specific version
    ${YELLOW}bash go.sh remove${RESET}                Uninstall Go
    ${YELLOW}bash go.sh help${RESET}                  Show this help
EOF
}

# Detect curl or wget for fetching URLs
fetch() {
  if command -v curl &>/dev/null; then
    curl -fsSL "$1"
  elif command -v wget &>/dev/null; then
    wget -qO- "$1"
  else
    die "Error: Neither curl nor wget is available. Please install one of them."
  fi
}

# Download a file with progress bar
download() {
  local url="$1" out="$2"
  if command -v curl &>/dev/null; then
    curl -fSL --progress-bar "$url" -o "$out" || die "Download failed!"
  elif command -v wget &>/dev/null; then
    local progress="--show-progress"
    wget --help 2>&1 | grep -q -- --force-progress && progress="--force-progress"
    wget --quiet --continue $progress "$url" -O "$out" || die "Download failed!"
  fi
}

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux)  os="linux" ;;
    Darwin) os="darwin" ;;
    *)      die "Unsupported OS: $os" ;;
  esac

  case "$arch" in
    x86_64)          arch="amd64" ;;
    aarch64|arm64)   arch="arm64" ;;
    armv6*)          arch="armv6l" ;;
    *386*)           arch="386" ;;
  esac

  PLATFORM="${os}-${arch}"
}

detect_shell_profile() {
  if [ -n "$($SHELL -c 'echo $ZSH_VERSION')" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
  elif [ -n "$($SHELL -c 'echo $BASH_VERSION')" ]; then
    [[ "$(uname -s)" == "Darwin" ]] && SHELL_PROFILE="$HOME/.bash_profile" || SHELL_PROFILE="$HOME/.bashrc"
  else
    SHELL_PROFILE="$HOME/.profile"
  fi
}

extract_version() { grep -oE "$VERSION_REGEX" <<< "$1" | head -1; }

# Resolve the download filename via the JSON API
resolve_download() {
  local requested="${1:-}"
  if [[ -n "$requested" ]]; then
    FILENAME="go${requested}.${PLATFORM}.tar.gz"
  else
    local json
    json=$(fetch "$GO_API")
    FILENAME=$(echo "$json" | grep -oE "\"filename\": *\"go${VERSION_REGEX}\.${PLATFORM}\.tar\.gz\"" | head -1 | grep -oE 'go[^"]+') || true
  fi
  [[ -z "$FILENAME" ]] && die "Couldn't find a Go release for $PLATFORM"
  DOWNLOAD_URL="https://go.dev/dl/${FILENAME}"
}

go_exists() {
  command -v go &>/dev/null || [ -x "$GOROOT/bin/go" ]
}

# --- Core actions ---

do_remove() {
  detect_shell_profile

  # Resolve current GOROOT from the running Go, or use default
  if command -v go &>/dev/null; then
    GOROOT=$(go env GOROOT)
    GOPATH=$(go env GOPATH)
  elif [ -x "$GOROOT/bin/go" ]; then
    : # already set from env/defaults
  else
    die "Go is not installed!"
  fi

  echo "${RED}Removing Go from ${GOROOT}...${RESET}"

  # Go module cache files are read-only; make them writable before removal
  chmod -R u+w "$GOROOT" 2>/dev/null
  rm -rf "$GOROOT" || die "Couldn't remove $GOROOT – try: sudo bash go.sh remove"

  # Clean shell profile
  if [ -f "$SHELL_PROFILE" ]; then
    echo "Backing up ${SHELL_PROFILE} to ${SHELL_PROFILE}-BACKUP"
    cp "$SHELL_PROFILE" "${SHELL_PROFILE}-BACKUP"
    sed -e '/export GOROOT/d' -e '/:$GOROOT/d' \
        -e '/export GOPATH/d' -e '/:$GOPATH/d' \
        "$SHELL_PROFILE" > "${SHELL_PROFILE}.tmp" && mv "${SHELL_PROFILE}.tmp" "$SHELL_PROFILE"
  fi

  echo "${GREEN}Uninstalled Go successfully!${RESET}"
}

do_install() {
  local version
  version=$(extract_version "$DOWNLOAD_URL")
  echo "Downloading ${CYAN}Go${RESET} ${version} for ${YELLOW}${PLATFORM}${RESET}..."

  download "$DOWNLOAD_URL" "$FILENAME"

  mkdir -p "$GOPATH"/{src,pkg,bin} "$GOROOT"
  echo "Extracting to $GOROOT..."

  local tmp_dir
  tmp_dir=$(mktemp -d)
  tar -xzf "$FILENAME" -C "$tmp_dir" || { rm -rf "$tmp_dir"; die "Extraction failed!"; }
  # Use cp instead of mv so hidden files are included
  cp -a "$tmp_dir/go/." "$GOROOT/"
  rm -rf "$tmp_dir" "$FILENAME"

  # Update shell profile (avoid duplicates)
  detect_shell_profile
  touch "$SHELL_PROFILE"
  if ! grep -q 'export GOROOT' "$SHELL_PROFILE"; then
    {
      echo "export GOROOT=$GOROOT"
      echo "export GOPATH=$GOPATH"
      echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin'
    } >> "$SHELL_PROFILE"
  fi

  # Verify
  if ! "$GOROOT/bin/go" version &>/dev/null; then
    die "Installation failed!"
  fi
  local installed
  installed=$(extract_version "$("$GOROOT/bin/go" version)")
  echo "${CYAN}Go${RESET} ($installed) installed ${GREEN}successfully!${RESET}"
  echo "Run: ${YELLOW}source $SHELL_PROFILE${RESET}"
}

do_update() {
  local latest current force="$1"
  latest=$(extract_version "$DOWNLOAD_URL")
  current=$(extract_version "$(go version)")

  echo "  CURRENT:  $current"
  echo "  CHOSEN:   $latest"

  if [[ "$current" == "$latest" ]]; then
    echo "Already on ${CYAN}Go${RESET} $current – nothing to do."
    exit 0
  fi

  if [[ "$force" != "update" ]]; then
    echo -en "Install ${GREEN}Go($latest)${RESET} and remove ${RED}Go($current)${RESET}? [Y/n]: "
    read -r answer
    case "${answer:-y}" in
      [Yy]*) ;; *) echo "Cancelled."; exit 0 ;;
    esac
  fi

  do_remove
  do_install
}

# --- Main ---

main() {
  print_welcome

  case "${1:-}" in
    remove) do_remove; exit ;;
    help|--help|-h) print_help; exit ;;
  esac

  local requested_version=""
  if [[ "${1:-}" == "--version" ]]; then
    [[ -z "${2:-}" ]] && die "Usage: bash go.sh --version <version>"
    requested_version="$2"
  elif [[ $# -gt 1 ]]; then
    print_help; exit 1
  fi

  detect_platform
  resolve_download "$requested_version"

  if go_exists; then
    do_update "${1:-}"
  else
    do_install
  fi
}

main "$@"
