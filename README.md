# Go Installer

[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/dwyl/esta/issues)
[![HitCount](http://hits.dwyl.io/kerolloz/go-installer.svg)](http://hits.dwyl.io/kerolloz/go-installer)
[![Build Status](https://travis-ci.com/kerolloz/go-installer.svg?branch=master)](https://travis-ci.com/kerolloz/go-installer)

> Travis tests run on Linux and Mac

## Usage

You can clone the repository or just use `wget` as following

```bash
wget https://raw.githubusercontent.com/kerolloz/go-installer/master/go.sh
bash go.sh
```

## How it works

The script does the following steps:

- automatically checks the installed operating system (Linux or Mac)
- detects system architecture (armv6, armv8, amd64, i386)
- parses the [golang](https://golang.org/dl) download page for the latest version of Go that is available for your platform and architecture
- downloads the latest version
- creates needed folders for workspace and Go binaries
- extracts the files of the downloaded package
- adds the binaries to PATH environmental variable

![](https://media.giphy.com/media/fAKdnja3pZuc4SHt5g/giphy.gif)

> Inspired by [golang-tools-install-script](https://github.com/canha/golang-tools-install-script) by canha
