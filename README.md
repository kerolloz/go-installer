

<p align="center">

<h1 align="center"> Go Installer 🐹 </h1>

<p align="center">

  <a href="https://github.com/kerolloz/go-installer/issues">
    <img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat">
  </a>

  <a href="http://hits.dwyl.io/kerolloz/go-installer">
    <img src="http://hits.dwyl.io/kerolloz/go-installer.svg">
  </a>

  <a href="https://travis-ci.com/kerolloz/go-installer">
    <img src="https://travis-ci.com/kerolloz/go-installer.svg?branch=master">
  </a>

</p>

<p align="center">
  Install Golang on Linux or Mac with no more <strike>hassle of environment variables setting</strike>.
</p>

</p>

<p align="center">
  <img src="https://pilsniak.com/wp-content/uploads/2017/04/golang.jpg" width="50%">
</p>

## How to use it :thinking:

### Installing(or updating) Go :arrow_down:

You can clone the repository or just use `wget` to download the script

```bash
wget https://raw.githubusercontent.com/kerolloz/go-installer/master/go.sh
bash go.sh
```

Now, You can go grab a cup of coffee :coffee:, set back :relieved: and watch the magic happen! :crystal_ball:

#### Please Note that

By default the script will create `.go` and `go` folders on your _HOME_ directory, add the needed variables to your _PATH_ variable.  

`$HOME/.go is location where Go will be installed to.`  
`$HOME/go is the default workspace.`  

In order to install Go to other location or set custom workspace. You can set environment variables GOROOT or GOPATH before installing (or uninstalling) Go.  

For example:  
```bash
export GOROOT=/opt/go            # where Go is installed
export GOPATH=$HOME/projects/go  # your workspace
```
Read more about [workspaces](https://golang.org/doc/code.html#Workspaces) in Go.

### Uninstalling Go :trash:

```bash
bash go.sh remove
```

## How it works :fire:

The script does the following steps:

- checks if you have already installed Go!
- automatically checks the installed operating system (Linux or Mac)
- detects system architecture (armv6, armv8, amd64, i386)
- parses the [golang](https://golang.org/dl) download page to find the latest version of Go that is available for your platform and architecture
- in case of having **already installed Go**, if the latest and the current version are equal, the script **exits** :wave:
- downloads the latest version
- creates needed folders for workspace and Go binaries
- extracts the files of the downloaded package
- adds the binaries to PATH environmental variable

<p align="center">

  <img src="https://media.giphy.com/media/U7PEFPIq1GrgSg4j5j/source.gif" width="80%">
  <p align="center">
    <blockquote align="center">WORKS LIKE A CHARM :rocket:</blockquote>
  </p>
</p>

## Tests

Tested by Travis :heavy_check_mark: on:
- Linux :penguin:
- Mac :computer:

Tested manually on:
- Ubuntu
- Manjaro

## Acknowledgments

- Inspired by [golang-tools-install-script](https://github.com/canha/golang-tools-install-script) by canha :sparkles:

## License

[MIT License](/LICENSE.md)
