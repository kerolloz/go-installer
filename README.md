<h1 align="left">Go Installer 🐹
  <a target="_blank" href="https://kounter.kerolloz.dev">
    <img align="right" src="https://kounter.kerolloz.dev/badge/kerolloz.go-installer?style=for-the-badge&color=69d7e4&label=Views&labelColor=69d7e4" />
  </a>
</h1>

<img align="right" src="https://user-images.githubusercontent.com/36763164/169433445-04f8485b-aa8d-45d0-a3cf-6e69c6456b2f.png" width="33%">

> Install Golang on Linux, Mac or Windows <strike>with hassle of environment variables setting</strike>.

![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)
[![.github/workflows/test.yml](https://github.com/kerolloz/go-installer/actions/workflows/test.yml/badge.svg)](https://github.com/kerolloz/go-installer/actions/workflows/test.yml)

## How to use it (Linux/MacOS) 🤔

### Installing (or even _updating_) Go ⬇️

You can _clone_ the repository and then choose how you want to run the script:

```shell
git clone
cd go-installer
```

- By running the script directly:

    * Linux: `bash go.sh`
    * MacOS: `./go.sh`
    * Windows: `.\go.ps1`

Or by simply running whatever suits you from the following commands (`wget` or `curl`):

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

`$HOME/.go` is where Go will be installed.
`$HOME/go` is the default workspace.

To install Go to another location or set a custom workspace, set the environment variables `GOROOT` or `GOPATH` before installing (or uninstalling) Go.

For example:

```bash
export GOROOT=/opt/go            # where Go is installed
export GOPATH=$HOME/projects/go  # your workspace
```

Read more about [workspaces](https://go.dev/doc/code.html#Workspaces) in Go.

### Specifying a version to install 🧐

By default, the script installs the latest version available.
You can choose what version to install by adding the `--version` flag, followed by the version you want to install.

```bash
bash go.sh --version 1.19.4
```

### Checking if a specific version is installed 🔍

You can check if a specific version of Go is installed by using the `--version check` flag, followed by the version you want to check.

```bash
bash go.sh --version check 1.19.4
```

### Show Help Message 🍁

To show the following help message use `bash go.sh help`.

<p align="center">
  <img src="https://user-images.githubusercontent.com/36763164/207301551-c686e069-df78-4d28-af78-bedd02b36354.gif" />
</p>

### Uninstalling Go ❌

```bash
bash go.sh remove
```

### Running Tests Locally with Docker 🐳

You can run tests locally using Docker to ensure a consistent environment and prevent side-effects on your host system. On CI environments, tests will run normally.

To run tests locally, simply use the `make test` command, and all the magic will happen:

```bash
make test
```

This command will build the Docker image and run the tests inside the Docker container.

## How to use it (Windows) 🤔

### Installing (or even _updating_) Go ⬇️

```powershell
.\go.ps1 -Command install
```

### Specifying a version to install 🧐

```powershell
.\go.ps1 -Command install -Version 1.19.2
```

### Checking if a specific version is installed 🔍

```powershell
.\go.ps1 -Command remove
```

### Uninstalling Go ❌

```powershell
.\go.ps1 -Command update
```

### Show Help Message 🍁

```powershell
.\go.ps1 -Command help
```

### Running Tests Locally with Docker 🐳

```powershell
.\go.ps1 -Command test
```

## Using Makefile for Common Tasks 🛠️

A `Makefile` is provided to simplify common tasks. Here are some useful commands:

- Linux/MacOS
    - Install Go: `make install`
    - Uninstall Go: `make uninstall`
    - Check if a specific version is installed: `make check-version VERSION=1.19.4`
    - Run tests: `make test`

- Windows
    - Install Go: `make install-windows`
    - Uninstall Go: `make uninstall-windows`
    - Check if a specific version is installed: `make check-version-windows VERSION=1.19.4`
    - Run tests: `make test-windows`

## How to Contribute 🤝

1. Fork the repository.
2. Clone the forked repository.
3. Create a new branch.
4. Make your changes.
5. Commit your changes.
6. Push the changes to your fork.
7. Create a pull request.
8. Star the repository.
9. Wait for the pull request to be reviewed and merged.
10. Celebrate 🎉

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
- Removes the downloaded installation file.

https://user-images.githubusercontent.com/36763164/207317882-7e50e2de-628e-43f0-bf7c-bee6b1e68001.mp4

<p align="center">🔥 WORKS LIKE A CHARM 🚀</p>