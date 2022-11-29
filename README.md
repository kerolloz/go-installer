<h1 align="left">Go Installer 🐹
  <a target="_blank" href="https://kounter.tk">
    <img align="right" src="https://t.ly/qgt4" />
  </a>
</h1>

<img align="right" src="https://user-images.githubusercontent.com/36763164/169433445-04f8485b-aa8d-45d0-a3cf-6e69c6456b2f.png" width="35%">

> Install Golang on Linux or Mac <strike>with hassle of environment variables setting</strike>.  

<a href="https://github.com/kerolloz/go-installer/issues">
  <img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat">
</a>

## How to use it 🤔

### Installing (or even _updating_) Go ⬇️

You can _clone_ the repository then run `bash go.sh`.

Or by simply running whatever suits you from the following commands (`wget`[^1] or `curl`):

[^1]: the script depends on wget ([1](https://github.com/kerolloz/go-installer/blob/836e09a79411cda39879a0ce8f69f199f4423562/go.sh#L67-L71), [2](https://github.com/kerolloz/go-installer/blob/836e09a79411cda39879a0ce8f69f199f4423562/go.sh#L132))

```bash
# downloads then runs the script
wget https://git.io/go-installer.sh && bash go-installer.sh
```

```bash
# doesn't download the script ~ runs the script directly 
bash <(curl -sL https://git.io/go-installer)
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

Read more about [workspaces](https://go.dev/doc/code.html#Workspaces) in Go.

### Uninstalling Go ❌

```bash
bash go.sh remove
```

## How it works ⚙️

The script does the following steps:

- Checks if Go is already installed.
- Detects the installed operating system (Linux or Mac).
- Detects system architecture (armv6, armv8, amd64, i386).
- Parses the <https://go.dev/dl> download page to find the latest version of Go that is available for your platform and architecture.
- Exits if you have the latest version of Go already installed.
- Downloads the latest version of Go.
- Creates the needed directories for workspace and Go binaries.
- Extracts the files of the downloaded package.
- Adds the binaries to PATH environment variable.

<p align="center">
  <img  src="https://media.giphy.com/media/U7PEFPIq1GrgSg4j5j/source.gif" width="80%">
  <p align="center">🔥 WORKS LIKE A CHARM 🚀</p>
</p>

## License

[MIT License](/LICENSE.md)
