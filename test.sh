#!/usr/bin/env bash
bash go.sh update # Update command to bypass the read prompt in update function
bash go.sh update # Try to update again. It should exit peacefully.
bash go.sh remove # Remove go
bash go.sh remove # Try to remove again. It should exit peacefully.
bash go.sh # Install go
bash go.sh # Try to install again. It should exit peacefully.
bash go.sh help # Print help message and exit
bash go.sh --version 1.19.2 # Try to install a specifi version of Go.