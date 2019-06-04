#!/bin/bash

# TODO: specify the version of go, user can chose the version he wants to install
# TODO: User can choose whether to remove the installer or not 
# TODO: test macos on travis
# TODO: User can specify the place of extracting go binary (GOROOT) && workplace(GOPATH).. 

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

version_regex="[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]"
file_name="go$version_regex.$platform.tar.gz"
link_regex="https://dl.google.com/go/$file_name"

echo "Finding latest version of `$TEXT_COLOR $CYAN`Go for $($TEXT_COLOR $YELLOW)$platform${RESET}..."

latest_version_link=$(
    wget -qO- https://golang.org/dl/ | # get the HTML of golang page 
    grep -o $link_regex | # select installation links
    head -1 # only get the first link i.e.(latest version)
)  

VERSION=$(grep -o $version_regex <<< $latest_version_link)

tput cuu 1; tput ed; # move one line up; clear to end 

echo "Downloading `$TEXT_COLOR $CYAN`Go ${RESET}latest version(`$BACKGROUND_COLOR $BLACK; tput smul`$VERSION${RESET})..." 

wget --quiet --continue --show-progress $latest_version_link

if [ $? -ne 0 ]; then
    echo "Download failed! Exiting."
    exit 1
fi

destination="$HOME/.go/" # better to be an empty folder just for go 
workspace="$HOME/go/"    

tput cuu 1; tput ed; # move one line up; clear to end 

mkdir -p -v $workplace{src,pkg,bin} $destination

echo "Extracting files to $destination..."

tar -xzf $file_name

mv "go/*" "$destination"
rmdir go

if [ -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
    shell_profile="zshrc"
elif [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    shell_profile="bashrc"
fi

touch "$HOME/.${shell_profile}"
{
    echo '# GoLang'
    echo "export GOROOT=$destination"
    echo 'export GOPATH=$HOME/go'
    echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin'
} >> "$HOME/.${shell_profile}"

tput cuu 1; tput ed; # move one line up; clear to end 

echo "`$TEXT_COLOR $CYAN`Go${RESET} ($VERSION) has been installed `$TEXT_COLOR $GREEN`successfully!${RESET}"

echo "`$TEXT_COLOR $BLUE`Testing `$TEXT_COLOR $CYAN`Go${RESET}.."

test_command = << END
go version

if [ $? -ne 0 ]; then
    echo "`$TEXT_COLOR $RED`Installation failed!!"
fi
END

$SHELL -c $test_command
