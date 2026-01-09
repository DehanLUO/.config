# Makefile for compiling zsh-easymotion.zsh into a zwc (zcompiled) file.
#
# This Makefile automates the process of generating an autoloadable,
# zcompiled version of the zsh-easymotion plugin for faster shell startup.
#
# Usage:
#   make               # Compile the plugin in the current directory.
#   make clean         # Remove generated .zwc and auxiliary files.
#   make install       # (Optional) Install to a standard config path.
#
# The default installation directory matches the one used in the original script:
# ~/.config/zsh/zsh-easymotion

SHELL := /bin/zsh
PLUGIN_NAME := zsh-easymotion
SOURCE_FILE := $(PLUGIN_NAME).zsh
CURRENT_DIR := $(shell pwd)
INSTALL_DIR ?= $(HOME)/.config/zsh/$(PLUGIN_NAME)

# Ensure the source file exists before proceeding.
ifeq ($(wildcard $(SOURCE_FILE)),)
$(error Source file "$(SOURCE_FILE)" not found in current directory.)
endif

.PHONY: all compile clean install help

# Default target: compile the plugin in the current directory.
all: compile

# Compile the plugin using its built-in zcompile function.
#
# This loads the plugin, then invokes `zsh-easymotion-zcompile`
# with the source file and output directory both set to the current working directory.
compile:
	@echo "Compiling $(SOURCE_FILE) into zwc format..."
	@Z=$(CURRENT_DIR)/$(SOURCE_FILE); . "$$Z" && \
		zsh-easymotion-zcompile "$$Z" "$(CURRENT_DIR)"

# Remove all compiled artefacts from the current directory.
clean:
	@echo "Cleaning compiled files in $(CURRENT_DIR)..."
	@rm -f $(CURRENT_DIR)/$(PLUGIN_NAME){,.zwc*}

# Install the compiled plugin to the standard configuration directory.
#
# This creates the target directory, compiles directly into it,
# and prints instructions for updating ~/.zshrc.
install:
	@echo "Installing compiled plugin to $(INSTALL_DIR)..."
	@mkdir -p "$(INSTALL_DIR)"
	@Z=$(CURRENT_DIR)/$(SOURCE_FILE); . "$$Z" && \
		zsh-easymotion-zcompile "$$Z" "$(INSTALL_DIR)"
	@echo
	@echo "Installation complete."
	@echo "Add the following to your ~/.zshrc to use the compiled version:"
	@echo
	@echo "  fpath+=($(subst $(HOME),~,$(INSTALL_DIR)))"
	@echo "  autoload -w $(subst $(HOME),~,$(INSTALL_DIR))/$(PLUGIN_NAME).zwc"
	@echo "  zle -N $(PLUGIN_NAME)"
	@echo "  bindkey -M viins '^X/' $(PLUGIN_NAME)"
	@echo

# Display brief usage information.
help:
	@echo "Available targets:"
	@echo "  make          - Compile plugin in current directory."
	@echo "  make clean    - Remove local compiled files."
	@echo "  make install  - Install compiled plugin to $(INSTALL_DIR)."
	@echo "  make help     - Show this message."