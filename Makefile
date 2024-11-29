SHELL := /bin/bash

# Define colors
GREEN := \033[32m
RED := \033[31m
GRAY := \033[90m
CYAN := \033[36m
NC := \033[0m
CHECK := $(GREEN)✓$(NC)
CROSS := $(RED)✗$(NC)
DASH := $(GRAY)-$(NC)

.PHONY: help check-os install-deps install-flutter install-android install-ios check-deps setup-web doctor check-arch check-shell check-environment check-rosetta check-status install-zsh install-rosetta install-xcode

.DEFAULT_GOAL := help

# Add this near the top with your other variable definitions
DRY_RUN ?= false

# Add this helper function
define execute
	@if [ "$(DRY_RUN)" = "true" ]; then \
		echo "$(1)"; \
	else \
		$(1); \
	fi
endef

check-os: ## Verify this is running on macOS
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "This Makefile is intended for macOS only"; \
		exit 1; \
	fi

install-deps: check-os install-zsh install-rosetta install-xcode ## Install basic dependencies using Homebrew
	@echo "Installing basic dependencies..."
	@which brew || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@brew update
	@brew install cocoapods
	@brew install wget
	@brew install git
	@brew install --cask android-studio
	@brew install --cask visual-studio-code

install-flutter: install-deps ## Install Flutter SDK and add to PATH
	@echo "Installing Flutter..."
	@if [ ! -d "$(HOME)/development" ]; then \
		mkdir -p $(HOME)/development; \
	fi
	@if [ ! -d "$(HOME)/development/flutter" ]; then \
		git clone https://github.com/flutter/flutter.git $(HOME)/development/flutter; \
	fi
	@echo 'export PATH="$$PATH:$$HOME/development/flutter/bin"' >> $(HOME)/.zshrc
	@echo 'export PATH="$$PATH:$$HOME/development/flutter/bin"' >> $(HOME)/.bashrc
	@source $(HOME)/.zshrc || source $(HOME)/.bashrc
	@flutter precache

install-android: ## Setup Android development environment and accept licenses
	@echo "Setting up Android development environment..."
	@echo 'export ANDROID_HOME=$$HOME/Library/Android/sdk' >> $(HOME)/.zshrc
	@echo 'export PATH=$$PATH:$$ANDROID_HOME/tools' >> $(HOME)/.zshrc
	@echo 'export PATH=$$PATH:$$ANDROID_HOME/platform-tools' >> $(HOME)/.zshrc
	@source $(HOME)/.zshrc
	@flutter config --android-sdk $$ANDROID_HOME
	@yes | flutter doctor --android-licenses

install-ios: check-os ## Setup iOS development environment and Xcode
	@echo "Setting up iOS development environment..."
	@xcode-select --install || true
	@sudo xcodebuild -license accept || true
	@pod setup

setup-web: ## Enable Flutter web development support
	@echo "Setting up web development..."
	@flutter config --enable-web

check-deps: ## Verify all required dependencies are installed
	@echo "Checking dependencies..."
	@which flutter >/dev/null || (echo "Flutter is not installed" && exit 1)
	@which git >/dev/null || (echo "Git is not installed" && exit 1)
	@which pod >/dev/null || (echo "CocoaPods is not installed" && exit 1)
	@which java >/dev/null || (echo "Java is not installed" && exit 1)

doctor: check-deps ## Run Flutter doctor for environment verification
	@echo "Running Flutter doctor..."
	@flutter doctor -v

check-arch: ## Check if running on Apple Silicon
	@if [ "$$(uname -m)" = "arm64" ]; then \
		echo "Running on Apple Silicon"; \
	else \
		echo "Running on Intel Mac"; \
	fi

check-shell: ## Check if using ZSH shell
	@if [ "$$SHELL" = "/bin/zsh" ]; then \
		echo "Using ZSH shell"; \
	else \
		echo "Not using ZSH shell (required to switch to ZSH)"; \
		echo "Current shell: $$SHELL"; \
		exit 1; \
	fi

check-rosetta: ## Check Rosetta 2 installation status on Apple Silicon
	@if [ "$$(uname -m)" = "arm64" ]; then \
		if pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto > /dev/null 2>&1; then \
			echo "Rosetta 2 is installed"; \
		else \
			echo "Rosetta 2 is not installed"; \
			exit 1; \
		fi \
	else \
		echo "Rosetta 2 check skipped - not running on Apple Silicon"; \
	fi

check-environment: check-os check-arch check-shell check-rosetta ## Check complete environment (OS, Architecture, Shell, Rosetta)
	@echo "Environment check complete"

check-status: ## Display status of all required components with checkmarks
	@echo "=== System Requirements Status ==="
	@# Check macOS
	@if [ "$$(uname)" = "Darwin" ]; then \
		printf "[$(CHECK)] macOS\n"; \
	else \
		printf "[$(CROSS)] macOS ($(GREEN)System requirement - must use macOS$(NC))\n"; \
	fi
	@# Check ZSH
	@if [ "$$SHELL" = "/bin/zsh" ]; then \
		printf "[$(CHECK)] ZSH Shell\n"; \
	else \
		printf "[$(CROSS)] ZSH Shell ($(GREEN)chsh -s /bin/zsh$(NC))\n"; \
	fi
	@# Check Homebrew
	@if which brew > /dev/null 2>&1; then \
		printf "[$(CHECK)] Homebrew\n"; \
	else \
		printf "[$(CROSS)] Homebrew ($(GREEN)make install-deps$(NC))\n"; \
	fi
	@# Check Rosetta 2 on Apple Silicon
	@if [ "$$(uname -m)" = "arm64" ]; then \
		if pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto > /dev/null 2>&1; then \
			printf "[$(CHECK)] Rosetta 2\n"; \
		else \
			printf "[$(CROSS)] Rosetta 2 ($(GREEN)make install-rosetta$(NC))\n"; \
		fi \
	else \
		printf "[$(DASH)] Rosetta 2 (Not Required - Intel Mac)\n"; \
	fi
	@# Check Xcode
	@if xcode-select -p > /dev/null 2>&1; then \
		printf "[$(CHECK)] Xcode Command Line Tools\n"; \
	else \
		printf "[$(CROSS)] Xcode Command Line Tools ($(GREEN)make install-xcode$(NC))\n"; \
	fi
	@# Check CocoaPods
	@if which pod > /dev/null 2>&1; then \
		printf "[$(CHECK)] CocoaPods\n"; \
	else \
		printf "[$(CROSS)] CocoaPods ($(GREEN)make install-deps$(NC))\n"; \
	fi
	@echo ""

install-zsh: ## Set ZSH as the default shell
	@echo "Setting ZSH as default shell..."
	$(call execute,if [ "$$SHELL" != "/bin/zsh" ]; then \
		chsh -s /bin/zsh; \
		echo "ZSH set as default shell. Please restart your terminal."; \
	else \
		echo "ZSH is already the default shell."; \
	fi)

install-rosetta: check-os ## Install Rosetta 2 for Apple Silicon Macs
	@echo "Installing Rosetta 2..."
	$(call execute,if [ "$$(uname -m)" = "arm64" ]; then \
		if ! pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto > /dev/null 2>&1; then \
			softwareupdate --install-rosetta --agree-to-license; \
			echo "Rosetta 2 installed successfully."; \
		else \
			echo "Rosetta 2 is already installed."; \
		fi; \
	else \
		echo "Rosetta 2 is not needed on Intel Macs."; \
	fi)

install-xcode: check-os ## Install Xcode Command Line Tools
	@echo "Installing Xcode Command Line Tools..."
	$(call execute,if ! xcode-select -p > /dev/null 2>&1; then \
		xcode-select --install; \
		echo "Please wait for the Xcode Command Line Tools installation to complete."; \
		echo "A system dialog may have opened requesting permission."; \
	else \
		echo "Xcode Command Line Tools are already installed."; \
	fi)

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-30s$(NC) %s\n", $$1, $$2}' 