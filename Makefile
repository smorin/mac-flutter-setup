SHELL := /bin/zsh

# Text colors
BLACK := \033[30m
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
WHITE := \033[37m
GRAY := \033[90m

# Background colors
BG_BLACK := \033[40m
BG_RED := \033[41m
BG_GREEN := \033[42m
BG_YELLOW := \033[43m
BG_BLUE := \033[44m
BG_MAGENTA := \033[45m
BG_CYAN := \033[46m
BG_WHITE := \033[47m

# Text styles
BOLD := \033[1m
DIM := \033[2m
ITALIC := \033[3m
UNDERLINE := \033[4m

# Reset
NC := \033[0m

CHECK := $(GREEN)✓$(NC)
CROSS := $(RED)✗$(NC)
DASH := $(GRAY)-$(NC)

.PHONY: help check-os install-all install-flutter install-android install-ios check-deps setup-web doctor check-arch check-shell check-environment check-base-environment check-rosetta check-status install-zsh install-rosetta install-xcode install-homebrew install-cocoapods install-git install-android-studio install-vscode setup-flutter-path

.DEFAULT_GOAL := help

# Add this helper function
define execute
	@if [ "$(DRY_RUN)" = "true" ]; then \
		echo "$(1)"; \
	else \
		$(1); \
	fi
endef

# Print help options and examples
define print-help
	@echo "Options:"
	@echo "  DRY_RUN=true  # Dry run (prints commands without executing)"
	@echo "  FORCE=true    # Force installation (reinstalls even if already present)"
	@echo "  FLUTTER_HOME=$(HOME)/flutter  # Set the Flutter home directory"
	@echo ""
	@echo "Examples:"
	@echo "  # Force installation (reinstalls even if already present)"
	@echo -e "  ${BLUE}make install-vscode FORCE=true${NC}"
	@echo ""
	@echo "  # Install all dependencies (skips existing installations)"
	@echo -e "  ${BLUE}make install-all${NC}"
	@echo ""
	@echo "  # Force install all dependencies"
	@echo -e "  ${BLUE}make install-all FORCE=true${NC}"
	@echo ""
	@echo "  # Combine with DRY_RUN to see what would happen"
	@echo -e "  ${BLUE}make install-all FORCE=true DRY_RUN=true${NC}"
endef

help: ## Display this help screen
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-30s$(NC) %s\n", $$1, $$2}' 
	@echo ""
	@$(call print-help)
	@echo ""
	@echo -e "Main Target:"
	@echo -e "  ${BLUE}make check-status${NC}"
	@echo -e "    ${GRAY}Check if all required components are installed${NC}"
	@echo -e "  ${BLUE}make install-all${NC}"
	@echo -e "    ${GRAY}Install all dependencies${NC}"
# Add this near the top with your other variable definitions
DRY_RUN ?= false
FORCE ?= false

check-os: ## Verify this is running on macOS
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "This Makefile is intended for macOS only"; \
		exit 1; \
	fi

check-arch: ## Check if running on Apple Silicon
	@if [ "$$(uname -m)" = "arm64" ]; then \
		echo "Running on Apple Silicon"; \
	else \
		echo "Running on Intel Mac"; \
	fi

check-shell: ## Check if using ZSH shell
	@echo "SHELL: $$SHELL"
	@shell_process=$$(ps -p $$$$ -o comm=); \
	if [ "$$SHELL" = "/bin/zsh" ] && { [ "$$shell_process" = "/bin/zsh" ] || [ "$$shell_process" = "zsh" ]; }; then \
		echo -e "[$(CHECK)] Using ZSH shell"; \
	else \
		echo -e "[$(CROSS)] Not using ZSH shell (required to switch to ZSH)"; \
		echo "Current shell ($$SHELL): $$shell_process"; \
		exit 1; \
	fi

check-base-environment: check-os check-shell ## Check complete environment (OS, Shell)
	@echo "Environment check complete"
	
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

# Define check_command macro - checks if a command exists
define check_command
	@if which $(1) > /dev/null 2>&1; then \
		printf "[$(CHECK)] $(2)\n"; \
	else \
		printf "[$(CROSS)] $(2) ($(GREEN)make $(3)$(NC))\n"; \
	fi
endef

# Define check_app macro - checks if an app exists in /Applications
define check_app
	@if [ -d "/Applications/$(1)" ] || [ -d "/Applications/$(1).app" ]; then \
		printf "[$(CHECK)] $(2)\n"; \
	else \
		printf "[$(CROSS)] $(2) ($(GREEN)make $(3)$(NC))\n"; \
	fi
endef

# Define check_command_or_app macro - checks if either command exists or app is installed
define check_command_or_app
	@if which $(1) > /dev/null 2>&1 || [ -d "/Applications/$(2)" ] || [ -d "/Applications/$(2).app" ]; then \
		printf "[$(CHECK)] $(3)\n"; \
	else \
		printf "[$(CROSS)] $(3) ($(GREEN)make $(4)$(NC))\n"; \
	fi
endef

define check_flutter_doctor
	@if which flutter > /dev/null 2>&1; then \
		printf "[$(CHECK)] Flutter\n"; \
		echo "Running Flutter doctor..."; \
		flutter doctor -v; \
	else \
		if [ "$(1)" != "PASS" ]; then \
			printf "[$(CROSS)] Flutter ($(GREEN)make install-flutter$(NC))\n"; \
			echo "Cannot run Flutter doctor - Flutter is not installed."; \
		fi; \
	fi
endef

#

check-status: check-shell ## Display status of all required components with checkmarks
	@echo "=== System Requirements Status ==="
	@# Check macOS
	@if [ "$$(uname)" = "Darwin" ]; then \
		printf "[$(CHECK)] macOS\n"; \
	else \
		printf "[$(CROSS)] macOS ($(GREEN)System requirement - must use macOS$(NC))\n"; \
	fi
	$(call check_command,zsh,ZSH Shell,install-zsh)
	$(call check_command,brew,Homebrew,install-homebrew)
	@if [ "$$(uname -m)" = "arm64" ]; then \
		if pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto > /dev/null 2>&1; then \
			printf "[$(CHECK)] Rosetta 2\n"; \
		else \
			printf "[$(CROSS)] Rosetta 2 ($(GREEN)make install-rosetta$(NC))\n"; \
		fi; \
	else \
		printf "[$(DASH)] Rosetta 2 (Not Required - Intel Mac)\n"; \
	fi
	$(call check_command,xcode-select,Xcode Command Line Tools,install-xcode)
	$(call check_command,pod,CocoaPods,install-cocoapods)
	$(call check_command,git,git,install-git)
	$(call check_app,Android Studio.app,Android Studio,install-android-studio)
	$(call check_command_or_app,code,Visual Studio Code,Visual Studio Code,install-vscode)
	$(call check_command,flutter,Flutter,install-flutter)
	$(call check_flutter_doctor,PASS)
	@echo ""
	@echo "${RED}Run manual steps recommended by flutter doctor${NC}"
	@echo ""
	@echo "Example:"
	@echo -e "  ${BLUE}make install-git FORCE=true DRY_RUN=true${NC}"

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
		if ! pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto > /dev/null 2>\&1; then \
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

install-homebrew: check-base-environment ## Install Homebrew
	@echo "Checking Homebrew installation..."
	$(call execute,if [ "$(FORCE)" = "true" ] || ! which brew > /dev/null 2>&1; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo >> $(HOME)/.zprofile; \
		echo 'eval "$$(/opt/homebrew/bin/brew shellenv)"' >> /Users/smorin/.zprofile ; \
		eval "$$(/opt/homebrew/bin/brew shellenv)"; \
		brew update; \
	else \
		echo "Homebrew is already installed. Use FORCE=true to reinstall."; \
	fi)

install-cocoapods: install-homebrew ## Install CocoaPods
	@echo "Checking CocoaPods installation..."
	$(call execute,if [ "$(FORCE)" = "true" ] || ! which pod > /dev/null 2>&1; then \
		echo "Installing CocoaPods..."; \
		brew install cocoapods; \
	else \
		echo "CocoaPods is already installed. Use FORCE=true to reinstall."; \
	fi)

install-git: install-homebrew ## Install git
	@echo "Checking git installation..."
	$(call execute,if [ "$(FORCE)" = "true" ] || ! which git > /dev/null 2>&1; then \
		echo "Installing git..."; \
		brew install git; \
	else \
		echo "git is already installed. Use FORCE=true to reinstall."; \
	fi)

install-android-studio: install-homebrew ## Install Android Studio
	@echo "Checking Android Studio installation..."
	$(call execute,echo "before")
	$(call execute,echo "in macro"; \
	if [ "$(FORCE)" = "true" ] || ! ls "/Applications/Android Studio.app" > /dev/null 2>&1; then \
		echo "Installing Android Studio..."; \
		echo ""; \
		brew install --cask android-studio; \
		echo ""; \
		echo -e "${RED}1. MANUAL STEP NEXT - 1st${NC}"; \
		echo ""; \
		echo "Summary: install Android SDK"; \
		echo "1. Open Android Studio."; \
		echo "2. In Android Studio: click Configure > SDK Manager."; \
		echo "3. In SDK Tools: check Show Package Details."; \
		echo "4. Expand Android SDK Location and click Install Packages."; \
		echo "5. Check Include Android SDK."; \
		echo "6. Click Next and Install."; \
		echo "7. Click Finish."; \
		echo ""; \
		open /Applications/Android\ Studio.app; \
		echo ""; \
		echo -e "${RED}2. MANUAL STEP NEXT - 2nd${NC}"; \
		echo ""; \
		echo "Summary: install command-line tools manually:"; \
		echo "1. Open Android Studio"; \
		echo "2. Click 'More Actions' > 'SDK Manager'"; \
		echo "3. Select 'SDK Tools' tab"; \
		echo "4. Check 'Android SDK Command-line Tools (latest)'"; \
		echo "5. Click 'Apply' and accept the license"; \
		echo -e "Run ${RED}path/to/sdkmanager --install \"cmdline-tools;latest\"${NC}"; \
		echo "See https://developer.android.com/studio/command-line for more details."; \
		echo -e "Run ${RED}flutter doctor --android-licenses${NC} to accept the SDK licenses."; \
	else \
		echo "Android Studio is already installed. Use FORCE=true to reinstall."; \
		echo "To install command-line tools manually:"; \
		echo "1. Open Android Studio"; \
		echo "2. Click 'More Actions' > 'SDK Manager'"; \
		echo "3. Select 'SDK Tools' tab"; \
		echo "4. Check 'Android SDK Command-line Tools (latest)'"; \
		echo "5. Click 'Apply' and accept the license"; \
	fi)
	echo "after"

install-vscode: ## Install Visual Studio Code
	@echo "Checking Visual Studio Code installation..."
	@echo "Installing Visual Studio Code..."
	@echo "Please install Visual Studio Code manually:"
	$(call execute,open "https://code.visualstudio.com/")
	@echo "Please install the Flutter extension manually:"
	$(call execute,open "https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter")

install-flutter: ## Instructions to prompt VS Code to install Flutter shoudl be run manually and use very clear language
	@echo ""
	@echo -e "${RED}Run manual steps${NC}"
	@echo ""
	@echo "Summary: You'll prompt VS Code to install Flutter and add to path."
	@echo ""
	@echo "1. Open VS Code."
	@echo "2. Open the Command Palette, press Command + Shift + P."
	@echo "3. Type flutter in the Command Palette."
	@echo "4. Select Flutter: New Project."
	@echo "5. VS Code prompts you to locate the Flutter SDK on your computer."
	@echo "		If you have the Flutter SDK installed, click Locate SDK."
	@echo "		If you do not have the Flutter SDK installed, click Download"
	@echo "			 SDK. VS Code will download the Flutter SDK and add it "
	@echo "			 to your PATH."
	@echo "		You can verify the Flutter SDK is in your PATH "
	@echo "			by running 'flutter' in your terminal."
	@echo ""
	@echo "For more information, see https://flutter.dev/docs/get-started/install/macos"
	@echo ""
	@echo "6. Copy the path. VS Code will present a button to copy the "
	@echo "		Flutter PATH to the clipboard."
	@echo -e "7. ${BLUE}make setup-flutter-path FLUTTER_HOME=/REPLACE/FLUTTER/PATH${NC}"

# TODO: Need to validate if this is needed
#install-ios: check-os ## Setup iOS development environment and Xcode
#	@echo "Setting up iOS development environment..."
#	@xcode-select --install || true
#	@sudo xcodebuild -license accept || true
#	@pod setup

# Main installation target that depends on all other installations
install-all: check-os install-zsh install-rosetta install-xcode install-homebrew install-cocoapods install-git install-android-studio install-vscode install-flutter ## Install all dependencies
	@echo "All dependencies installed successfully!"

setup-web: ## Enable Flutter web development support
	@echo "Setting up web development..."
	@flutter config --enable-web

setup-flutter-path: ## Setup Flutter PATH in .zshenv
	@if [ -z "$(FLUTTER_HOME)" ]; then \
		echo "FLUTTER_HOME is not set. Please set FLUTTER_HOME to the Flutter installation directory."; \
		exit 1; \
	fi
	@echo "Setting up Flutter PATH... in file: $(HOME).zshenv"
	@echo "  Using FLUTTER_HOME: $(FLUTTER_HOME)"
	$(call execute,if [ ! -f "$(HOME)/.zshenv" ]; then \
		touch "$(HOME)/.zshenv"; \
	fi)
	$(call execute,if ! grep -q "export PATH=\$$PATH:\$$FLUTTER_HOME/bin" "$(HOME)/.zshenv"; then \
		echo "export FLUTTER_HOME=\"$(FLUTTER_HOME)\"" >> "$(HOME)/.zshenv"; \
		echo 'export PATH=$$PATH:$$FLUTTER_HOME/bin' >> "$(HOME)/.zshenv"; \
		echo "Flutter PATH added to $(HOME)/.zshenv"; \
		echo "Please restart your terminal or run: source $(HOME)/.zshenv"; \
	else \
		echo "Flutter PATH already exists in .zshenv"; \
	fi)

