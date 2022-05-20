# Go Installer 🐹
<img align="right" src="https://user-images.githubusercontent.com/36763164/169433445-04f8485b-aa8d-45d0-a3cf-6e69c6456b2f.png" width="35%">

> Install Golang on Linux or Mac <strike>with hassle of environment variables setting</strike>.  
<a href="https://github.com/kerolloz/go-installer/issues">
  <img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat">
</a>
<a href="https://travis-ci.com/kerolloz/go-installer">
  <img src="https://travis-ci.com/kerolloz/go-installer.svg?branch=master">
</a>


## How to use it :thinking:

### Installing (or even _updating_) Go :arrow_down:

You can _clone_ the repository then run `bash go.sh`.

Or by simply running whatever suits you from the following commands (`wget`[^1] or `curl`):

[^1]: the script depends on wget ([1](https://github.com/kerolloz/go-installer/blob/836e09a79411cda39879a0ce8f69f199f4423562/go.sh#L67-L71), [2](https://github.com/kerolloz/go-installer/blob/836e09a79411cda39879a0ce8f69f199f4423562/go.sh#L132))

```bash
# downloads then runs the script
wget https://git.io/go-installer.sh && bash go-installer.sh
```

```bash
# doesn't download the script ~ runs the script directly from stdout 
curl -sL https://git.io/go-installer | bash
```

Now, you can go grab a cup of coffee :coffee:, sit back :relieved: and relax while the magic happens! :crystal_ball:

> **Note**  
> By default the script will create `.go` and `go` folders on your _HOME_ directory & add the needed variables to your _PATH_ variable.  

`$HOME/.go` is the location where Go will be installed to.   
`$HOME/go` is the default workspace.

In order to install Go to other location or set custom workspace. You can set environment variables GOROOT or GOPATH before installing (or uninstalling) Go.

For example:

```bash
export GOROOT=/opt/go            # where Go is installed
export GOPATH=$HOME/projects/go  # your workspace
```

Read more about [workspaces](https://golang.org/doc/code.html#Workspaces) in Go.

### Uninstalling Go :x:

```bash
bash go.sh remove
```

## How it works :fire:

The script does the following steps:

- checks if you have already installed Go!
- detects the installed operating system (Linux or Mac)
- detects system architecture (armv6, armv8, amd64, i386)
- parses the [golang](https://golang.org/dl) download page to find the latest version of Go that is available for your platform and architecture
- in the case of having **Go already installed**, if the latest and the current version are equal, the script will **exit** :wave:
- downloads the latest version
- creates the needed directories for workspace and Go binaries
- extracts the files of the downloaded package
- adds the binaries to PATH environmental variable

<p align="center">
  <picture>
  <img  src="https://media.giphy.com/media/U7PEFPIq1GrgSg4j5j/source.gif" width="80%">
  </picture>
  <p align="center">WORKS LIKE A CHARM :rocket:</p>
</p>

## Tests

Tested by Travis :heavy_check_mark: on:

- Linux :penguin:
- Mac :computer:

Tested manually on:

- Ubuntu
- Manjaro

## License

[MIT License](/LICENSE.md)
