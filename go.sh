#!/bin/bash

# shellcheck disable=SC2016

# Color definitions for tput
BLACK=0
RED=1
GREEN=2
YELLOW=3
BLUE=4
CYAN=6
RESET=$(tput sgr0)
TEXT_COLOR="tput setaf "
BACKGROUND_COLOR="tput setab "
CLEAR_UP="#tput cuu 1; tput ed;"

version_regex="[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]"
VERSION_REGEX="[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]"
is_latest_version="yes"

if [[ -n "$NON_INTERACTIVE" ]] && [[ "$NON_INTERACTIVE" == "true" ]]; then
  BYPASS_PROMPTS="true"
else
  BYPASS_PROMPTS=""
fi

function print_welcome() {
  echo -e "$($TEXT_COLOR $CYAN)
\t   __________        _____   ________________    __    __    __________
\t  / ____/ __ \\      /  _/ | / / ___/_  __/   |  / /   / /   / ____/ __ \\
\t / / __/ / / /_____ / //  |/ /\\__ \\ / / / /| | / /   / /   / __/ / /_/ /
\t/ /_/ / /_/ /_____// // /|  /___/ // / / ___ |/ /___/ /___/ /___/ _, _/
\t\\____/\\____/     /___/_/ |_//____//_/ /_/  |_/_____/_____/_____/_/ |_|
${RESET}"
}

function print_help() {
  if test -z $BYPASS_PROMPTS; then
    echo -e "\t$($TEXT_COLOR $BLUE)go.sh${RESET} is a tool that helps you easily install, update or uninstall Go\n
    \t$($TEXT_COLOR $GREEN)-------------------------------  Usage  -------------------------------\n
    \t$($TEXT_COLOR $YELLOW)bash go.sh${RESET}\t\t\t\tInstalls or update Go (if installed)
    \t$($TEXT_COLOR $YELLOW)bash go.sh --version [version]${RESET}\t\tInstalls a specific version of Go
    \t$($TEXT_COLOR $YELLOW)bash go.sh --version check [version]${RESET}\tChecks if a specific version of Go is installed
    \t$($TEXT_COLOR $YELLOW)bash go.sh remove${RESET}\t\t\tUninstalls the installed version of Go
    \t$($TEXT_COLOR $YELLOW)bash go.sh update${RESET}\t\t\tUpdates the installed version of Go
    \t$($TEXT_COLOR $YELLOW)bash go.sh help${RESET}\t\t\t\tPrints this help message
    "
  fi
}

function what_platform() {
  os="$(uname -s)"
  arch="$(uname -m)"

  case $os in
  "Linux")
    case $arch in
    "x86_64")
      arch=amd64
      ;;
    "armv6")
      arch=armv6l
      ;;
    "armv8" | "aarch64")
      arch=arm64
      ;;
    .*386.*)
      arch=386
      ;;
    esac
    platform="linux-$arch"
    ;;
  "Darwin")
    case $arch in
    "x86_64")
      arch=amd64
      ;;
    "arm64")
      arch=arm64
      ;;
    esac
    platform="darwin-$arch"
    ;;
  "MINGW" | "MSYS" | "CYGWIN")
    case $arch in
    "x86_64")
      arch=amd64
      ;;
    "arm64")
      arch=arm64
      ;;
    esac
    platform="windows-$arch"
    ;;
  esac
}

function what_shell_profile() {
  local CURRENT_SHELL="$SHELL"

  if test -z "$CURRENT_SHELL"; then
    CURRENT_SHELL=$(ps -p $$ | tail -n 1 | awk '{print $4}')
  fi

  case $CURRENT_SHELL in
  *zsh)
    shell_profile="zshrc"
    ;;
  *bash)
    shell_profile="bashrc"
    ;;
  *fish)
    shell_profile="config/fish/config.fish"
    ;;
  esac

  if [[ -z $shell_profile ]]; then
    echo "$($TEXT_COLOR $RED)Couldn't detect your shell profile!${RESET}"
    echo "Please add the following lines to your shell profile manually:"
    echo "export GOROOT=\$HOME/.go"
    echo "export GOPATH=\$HOME/go"
    echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin"
    exit 1
  fi
}

function what_installed_version() {
  INSTALLED_VERSION=$(go version)
}

function extract_version_from() {
  local version
  version=$(grep -o "$VERSION_REGEX" <<<"$1")
  echo "$version"
}

function get_download_command() {
  if command -v curl &>/dev/null; then
    echo "curl -s"
  elif command -v wget &>/dev/null; then
    echo "wget -qO-"
  else
    echo "$($TEXT_COLOR $RED)Error: Neither curl nor wget is available. Please install one of them.${RESET}" >&2
    exit 1
  fi
}

function find_version_link() {
  file_name="go$version_regex.$platform.tar.gz"
  link_regex="dl/$file_name"
  go_website="https://go.dev/"

  download_command=$(get_download_command)

  latest_version_link="$go_website$(
    $download_command "$go_website/dl/" | # get the HTML of golang page
      grep -o "$link_regex" |             # select installation links
      head -1                             # only get the first link i.e.(latest version)
  )"

  latest_version_file_name=$(grep -o "$file_name" <<<"$latest_version_link")
  [[ -z $latest_version_file_name ]] && echo "$($TEXT_COLOR $RED)Couldn't find $file_name on $go_website${RESET}" && exit 1
}

function go_exists() {
  go version &>/dev/null
}

function remove() {
  if ! go_exists; then
    echo "$($TEXT_COLOR $RED)Go is not installed!${RESET}"
    exit
  fi

  what_shell_profile
  what_installed_version
  echo "$($TEXT_COLOR $RED)removing $INSTALLED_VERSION${RESET} from ${GOROOT}"

  if ! rm -r -f "$GOROOT"; then
    echo "$($TEXT_COLOR $RED)Couldn't remove Go${RESET}."
    echo "Can't remove contents of $GOROOT"
    echo "Maybe you need to run the script with root privileges!"
    echo "sudo bash go.sh"
    exit 1
  fi

  RC_PROFILE="$HOME/.${shell_profile}"

  echo "Creating a backup of your ${RC_PROFILE} to ${RC_PROFILE}-BACKUP"
  cp -af "$RC_PROFILE" "${RC_PROFILE}-BACKUP"
  echo "Removing exports for GOROOT & GOPATH from ${RC_PROFILE}"
  sed -i'' -e '/export GOROOT/d' "${RC_PROFILE}"

  sed -i'' -e '/:$GOROOT/d' "${RC_PROFILE}"
  sed -i'' -e '/export GOPATH/d' "${RC_PROFILE}"
  sed -i'' -e '/:$GOPATH/d' "${RC_PROFILE}"

  echo "$($TEXT_COLOR $GREEN)Uninstalled Go Successfully!${RESET}"
}

function test_installation() {
  if [ $? -ne 0 ]; then
    echo "$($TEXT_COLOR $RED)Installation failed!!${RESET}"
    exit 1
  fi

  what_shell_profile

  echo "$($TEXT_COLOR $CYAN)Go${RESET} ($VERSION) has been installed $($TEXT_COLOR $GREEN)successfully!${RESET}"
  echo "Open a new terminal(to re login) or you can do: $($TEXT_COLOR $YELLOW)source $HOME/.${shell_profile}${RESET}"
}

function install_go() {
  local _VERSION

  _VERSION=${1:-$version_regex}

  what_shell_profile

  eval "$CLEAR_UP"

  VERSION=$(extract_version_from "$latest_version_link")
  version_name="latest version"
  [[ $is_latest_version == "no" ]] && version_name="version"
  echo "Downloading $($TEXT_COLOR $CYAN)Go${RESET} $version_name ($(
    $BACKGROUND_COLOR $BLACK
    tput smul
  )$VERSION${RESET})..."

  download_command=$(get_download_command)

  if [[ $download_command == "curl -s" ]]; then
    if ! curl -fSL --progress-bar "$latest_version_link" -o "$latest_version_file_name"; then
      echo "$($TEXT_COLOR $RED)Download failed!${RESET}"
      exit 1
    fi
  else
    # wget2 v2.1.0 changed --show-progress to --force-progress, so we need to check which one to use
    progress_arg="--show-progress"
    wget --help | grep -q -- --force-progress && progress_arg="--force-progress"

    if ! wget --quiet --continue $progress_arg "$latest_version_link"; then
      echo "$($TEXT_COLOR $RED)Download failed!${RESET}"
      exit 1
    fi
  fi

  [ -z "$GOROOT" ] && GOROOT="$HOME/.go"
  [ -z "$GOPATH" ] && GOPATH="$HOME/go"

  eval "$CLEAR_UP"

  mkdir -p "$GOPATH"/{src,pkg,bin} "$GOROOT"

  echo "Extracting $latest_version_file_name files to $GOROOT..."

  tar -xzf "$latest_version_file_name"

  if [ -d "$GOROOT/go" ]; then
    mv -f "$GOROOT/go" "$GOROOT/go-old"
  fi

  mv -f go/* "$GOROOT"

  if ! rmdir go &>/dev/null; then
    echo "$($TEXT_COLOR $RED)Failed to remove go directory${RESET}"
    if test -z $BYPASS_PROMPTS; then
      read -t 3 -r -p "Do you want to remove it manually? [y/n]: " option || option="n" # timeout after 3 seconds and default to no
      [[ $option == "y" || $option == "Y" ]] && rm -rf go
    else
      rm -rf go || exit 1
    fi
  fi

  what_shell_profile

  touch "$HOME/.${shell_profile}"
  {
    echo "export GOROOT=$GOROOT"
    echo "export GOPATH=$GOPATH"
    echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin'
  } >>"$HOME/.${shell_profile}"

  eval "$CLEAR_UP"
}

function echo_finding() {
  finding="Finding latest version"
  [[ $is_latest_version == "no" ]] && finding="You chose to install version $version_regex"
  echo "$finding of $($TEXT_COLOR $CYAN)Go${RESET} for $($TEXT_COLOR $YELLOW)$platform${RESET}..."
}

function update_go() {
  what_shell_profile

  GOPATH=$(go env GOPATH)
  GOROOT=$(go env GOROOT)
  what_installed_version
  latest=$(extract_version_from "$latest_version_link")
  current=$(extract_version_from "$INSTALLED_VERSION")

  eval "$CLEAR_UP"
  echo -e "          VERSION"
  echo -e "CURRENT:   $current"
  echo -e "CHOSEN:    $latest"

  if [[ $current == "$latest" ]]; then
    echo "You already have that version of $($TEXT_COLOR $CYAN)Go${RESET} Installed!"
    echo "$($TEXT_COLOR $BLUE)Exiting, Bye!${RESET}"
    exit 0
  fi

  echo "Installing will remove the current installed version from '$GOROOT'"

  if [[ $1 == "update" ]]; then
    option=""
  else
    if test -z $BYPASS_PROMPTS; then
      echo -e "Do you want to install $($TEXT_COLOR $GREEN)Go($latest)${RESET} and remove $($TEXT_COLOR $RED)Go($current)${RESET}? [ENTER(yes)/n]: \c"
      read -r option
    else
      option="Y"
    fi
  fi

  case $option in
  "" | Y* | y*)
    remove && install_go
    ;;
  N* | n*)
    echo "Okay, Bye!"
    exit 0
    ;;
  *)
    echo "Wrong choice!"
    exit 1
    ;;
  esac

}

function remove_downloaded_package() {
  rm -f "$latest_version_file_name"
}

function main() {
  print_welcome

  what_shell_profile

  if [[ $# == 1 ]]; then
    case $1 in
    "update")
      ;;
    "remove")
      remove
      exit
      ;;
    *)
      print_help
      exit
      ;;
    esac
  elif [[ $# == 2 ]]; then
    case $1 in
    "--version")
      version_regex=$2
      what_installed_version
      is_latest_version=$(echo "$INSTALLED_VERSION" | grep -q "$version_regex" && echo "yes" || echo "no")
      if [[ $is_latest_version == "yes" ]]; then
        echo "You already have that version of Go Installed!"
        echo "Exiting, Bye!"
        exit 0
      else
        echo "You don't have that version ($version_regex) of Go Installed!"
        echo "Installing..."

        what_platform
        echo_finding
        find_version_link

        if go_exists -eq 0; then
          echo "Go exists"
          update_go "$1"
        else
          install_go "${2:-$version_regex}"
        fi

        remove_downloaded_package
        test_installation

        exit $? # exit with the same exit code as test_installation
      fi
    ;;
    *)
      print_help
      exit
      ;;
    esac
  elif [[ $# == 3 ]]; then
    case $1 in
    "--version")
      if [[ $2 == "check" ]]; then
        version_regex=$3
        what_installed_version
        is_latest_version=$(echo "$INSTALLED_VERSION" | grep -q "$version_regex" && echo "yes" || echo "no")
        if [[ $is_latest_version == "yes" ]]; then
          echo "You already have that version of Go Installed!"
          echo "Exiting, Bye!"
          exit 0
        else
          echo "You don't have that version ($version_regex) of Go Installed!"
          echo "I can install it for you..."
          echo "If you want to install it, run the following command:"
          echo ""
          echo "$($TEXT_COLOR $YELLOW)bash go.sh --version $version_regex${RESET}"
          echo ""
          exit 0
        fi
      else
        print_help
        exit 1
      fi
    ;;
    *)
      print_help
      exit 1
    ;;
    esac
  elif [[ $# -gt 3 ]]; then
    print_help
    exit 1
  fi

  what_platform
  echo_finding
  find_version_link

  if go_exists -eq 0; then
    echo "Go exists"
    update_go "$1"
  else
    install_go
  fi

  test_installation
  remove_downloaded_package
}

main "$@"
