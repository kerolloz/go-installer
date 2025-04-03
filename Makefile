APP_NAME := go-installer
ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPT_NAME := $(ROOT_DIR)go.sh
TEST_SCRIPT_NAME := $(ROOT_DIR)test.sh
ARGS :=

# Colors
COLOR_RESET := \033[0m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_RED := \033[31m
COLOR_BLUE := \033[34m

# Logging Functions
log = @printf "$(COLOR_BLUE)[LOG]$(COLOR_RESET) %s\n" "$(1)"
success = @printf "$(COLOR_GREEN)[SUCCESS]$(COLOR_RESET) %s\n" "$(1)"
warning = @printf "$(COLOR_YELLOW)[WARNING]$(COLOR_RESET) %s\n" "$(1)"
break = @printf "$(COLOR_BLUE)[LOG]$(COLOR_RESET)\n"
error = @printf "$(COLOR_RED)[ERROR]$(COLOR_RESET) %s\n" "$(1)" && exit 1

# Install Go using the provided shell script
install:
	$(call log, Installing Go )
	$(call break, b )
	@bash $(SCRIPT_NAME) $(ARGS) || exit 1
	$(call break, b )
	$(call success, Installation completed )

# Update Go using the provided shell script
update:
	$(call log, Updating Go )
	$(call break, b )
	@bash $(SCRIPT_NAME) update $(ARGS) || exit 1
	$(call break, b )
	$(call success, Update completed )

# Remove Go using the provided shell script
remove:
	$(call log, Removing Go )
	$(call break, b )
	@bash $(SCRIPT_NAME) remove $(ARGS) || exit 1
	$(call break, b )
	$(call success, Removal completed )

# Run tests (placeholder for actual test commands)
test:
	$(call log, Running tests)
	$(call break, b )
	@bash $(TEST_SCRIPT_NAME) $(ARGS) || exit 1
	$(call break, b )
	$(call success, Tests completed successfully)

# Install Go using the provided PowerShell script
install-windows:
	$(call log, Installing Go on Windows)
	$(call break, b)
	@powershell -ExecutionPolicy Bypass -File go.ps1 -Command install $(ARGS) || exit 1
	$(call break, b)
	$(call success, Installation completed)

# Update Go using the provided PowerShell script
update-windows:
	$(call log, Updating Go on Windows)
	$(call break, b)
	@powershell -ExecutionPolicy Bypass -File go.ps1 -Command update $(ARGS) || exit 1
	$(call break, b)
	$(call success, Update completed)

# Remove Go using the provided PowerShell script
remove-windows:
	$(call log, Removing Go on Windows)
	$(call break, b)
	@powershell -ExecutionPolicy Bypass -File go.ps1 -Command remove $(ARGS) || exit 1
	$(call break, b)
	$(call success, Removal completed)

# Run tests using the provided PowerShell script
test-windows:
	$(call log, Running tests on Windows)
	$(call break, b)
	@powershell -ExecutionPolicy Bypass -File go.ps1 -Command test $(ARGS) || exit 1
	$(call break, b)
	$(call success, Tests completed successfully)

# Display this help message
help:
	$(call log, $(APP_NAME) Makefile )
	$(call break, b )
	$(call log, Usage: )
	$(call log,   make [target] [ARGS='--custom-arg value'] )
	$(call break, b )
	$(call log, Available targets: )
	$(call log,   make install    - Install Go using the provided shell script)
	$(call log,   make update     - Update Go using the provided shell script)
	$(call log,   make remove     - Remove Go using the provided shell script)
	$(call log,   make test       - Run tests (placeholder))
	$(call log,   make help       - Display this help message)
	$(call break, b )
	$(call log, Usage with arguments: )
	$(call log,   make install ARGS='--version 1.16.3' - Install a specific version of Go)
	$(call break, b )
	$(call log, Example: )
	$(call log,   make install ARGS='--version 1.16.3')
	$(call break, b )
	$(call log, For more information, visit: )
	$(call log, 'https://github.com/kerolloz/go-installer' )
	$(call break, b )
	$(call success, End of help message)