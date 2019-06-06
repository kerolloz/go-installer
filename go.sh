#!/bin/bash

# TODO:
#       User can remove installed version of Go
#       User can update current version of Go

# Colors definitions for tput

BLACK=0
RED=1
GREEN=2
YELLOW=3
BLUE=4
MAGENTA=5
CYAN=6
WHITE=7
RESET=`tput sgr0`
TEXT_COLOR="tput setaf "
BACKGROUND_COLOR="tput setab "
CLEAR_UP="tput cuu 1; tput ed;"

version_regex="[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]"

function what_platform(){
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
            "armv8")
                arch=arm64
                ;;
            .*386.*)
                arch=386
                ;;
            esac
            platform="linux-$arch"
        ;;
        "Darwin")
            platform="darwin-amd64"
        ;;
    esac
}

function what_shell_profile(){
    if [ -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
        shell_profile="zshrc"
    elif [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
        shell_profile="bashrc"
    fi
}

function extract_version_from(){
    local version=$(grep -o $version_regex <<< "$1")
    echo "$version"
}

function find_latest_version_link(){

    file_name="go$version_regex.$platform.tar.gz"
    link_regex="https://dl.google.com/go/$file_name"

    latest_version_link=$(
        wget -qO- https://golang.org/dl/ | # get the HTML of golang page
        grep -o $link_regex | # select installation links
        head -1 # only get the first link i.e.(latest version)
    )

}

function go_exists(){
    go version &> /dev/null
}

function remove(){
    go_exists
    if [[ $? -ne 0 ]]; then 
        echo "`$TEXT_COLOR $RED`Go is not installed!${RESET}"
        exit 1
    fi
    what_shell_profile

    echo "`$TEXT_COLOR $RED`removing $INSTALLED_VERSION${RESET} from ${GOROOT}"

    rm -r $GOROOT

    if [[ $? -ne 0 ]]; then
        echo "`$TEXT_COLOR $RED`Couldn't remove Go${RESET}."
        echo "Can't remove contents of $GOROOT"
        echo "Maybe you need to run the script with root privileges!"
        echo "sudo bash go.sh"
        exit 1
    fi
    
    RC_PROFILE="$HOME/.${shell_profile}"

    echo "Creating a backup of your ${RC_PROFILE} to ${RC_PROFILE}-BACKUP"
    cp "$RC_PROFILE" "${RC_PROFILE}-BACKUP"
    sed -i '/export GOROOT/d' "${RC_PROFILE}"
    sed -i '/:$GOROOT/d' "${RC_PROFILE}"
    sed -i '/export GOPATH/d' "${RC_PROFILE}"
    sed -i '/:$GOPATH/d' "${RC_PROFILE}"
    
    echo "`$TEXT_COLOR $GREEN`Unistalled Go Successfully!${RESET}"
}

function test_installaion(){
    echo "`$BACKGROUND_COLOR $BLACK`Testing installation.."

    $GOROOT/bin/go version $> /dev/null

    if [ $? -ne 0 ]; then
        echo "`$TEXT_COLOR $RED`Installation failed!!${RESET}"
        exit 1
    fi

    echo "`$TEXT_COLOR $CYAN`Go${RESET} ($VERSION) has been installed `$TEXT_COLOR $GREEN`successfully!${RESET}"
    echo "Open a new terminal(to relogin) or you can do: `$TEXT_COLOR $YELLOW`source $HOME/.${shell_profile}${RESET}"    
}

function install_go(){

    eval $CLEAR_UP
    
    VERSION=$(extract_version_from $latest_version_link)
    echo "Downloading `$TEXT_COLOR $CYAN`Go ${RESET}latest version(`$BACKGROUND_COLOR $BLACK; tput smul`$VERSION${RESET})..."

    wget --quiet --continue --show-progress $latest_version_link

    if [ $? -ne 0 ]; then
        echo "`$TEXT_COLOR $RED`Download failed!"
        exit 1
    fi

    [ -z "$GOROOT" ] && GOROOT="$HOME/.go"
    [ -z "$GOPATH" ] && GOPATH="$HOME/go"

    eval $CLEAR_UP

    mkdir -p $GOPATH/{src,pkg,bin} $GOROOT

    echo "Extracting files to $GOROOT..."

    tar -xzf $file_name

    mv go/* $GOROOT
    rmdir go
    
    what_shell_profile

    touch "$HOME/.${shell_profile}"
    {
        echo "export GOROOT=$GOROOT"
        echo "export GOPATH=$GOPATH" 
        echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin'
    } >> "$HOME/.${shell_profile}"

    eval $CLEAR_UP

}

function echo_finding(){
    echo "Finding latest version of `$TEXT_COLOR $CYAN`Go${RESET} for $($TEXT_COLOR $YELLOW)$platform${RESET}..."
}

function update_go(){
    INSTALLED_VERSION=$(go version)
    GOPATH=$(go env GOPATH)
    GOROOT=$(go env GOROOT)


    latest=`extract_version_from "$latest_version_link"`
    current=`extract_version_from "$INSTALLED_VERSION"`

    eval $CLEAR_UP
    echo -e "          VERSION"
    echo -e "LATEST:   $latest"
    echo -e "CURRENT:  $current"

    if [[ $current == $latest ]]; then
        echo "You already have the latest version of `$TEXT_COLOR $CYAN`Go${RESET} Installed!"
        echo "`$TEXT_COLOR $BLUE`Exiting, Bye!${RESET}"
        exit
    fi
    echo "Updating will remove the current installed version from $GOROOT."
    echo -e  "Do you want to update to Go(${latest})? [ENTER(yes)/n]: " 
    read option

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

function print_help(){
    echo -e "\n`$TEXT_COLOR $BLUE`go.sh${RESET} is a tool that helps you easily install, upgrade or unistall Go\n"
    echo -e "[USAGE]\n\t`$TEXT_COLOR $YELLOW`bash go.sh${RESET}\t\tInstalls or upgrades Go (if already installed)"
    echo -e "\t`$TEXT_COLOR $YELLOW`bash go.sh remove${RESET}\tUnistalls the currently installed version of Go"
    echo -e "\t`$TEXT_COLOR $YELLOW`bash go.sh help${RESET}\t\tPrints this help message"
}

function print_welcome(){
    
    echo "`$TEXT_COLOR $CYAN`
  ____  ___       ___ _   _ ____ _____  _    _     _     _____ ____  
 / ___|/ _ \     |_ _| \ | / ___|_   _|/ \  | |   | |   | ____|  _ \ 
| |  _| | | |_____| ||  \| \___ \ | | / _ \ | |   | |   |  _| | |_) |
| |_| | |_| |_____| || |\  |___) || |/ ___ \| |___| |___| |___|  _ < 
 \____|\___/     |___|_| \_|____/ |_/_/   \_\_____|_____|_____|_| \_\\
 ${RESET}"

}

function main(){
    print_welcome

    if [[ $# == 1 ]]; then
        case $1 in 
        "remove")
            remove 
        ;;
        *)
            print_help 
            exit 1 
        ;;
        esac
        exit 
    fi

    what_platform
    echo_finding
    find_latest_version_link
    go_exists
    if [[ $? == 0 ]]; then
        update_go
    else
        install_go
    fi

    test_installaion 
}

main "$@"
