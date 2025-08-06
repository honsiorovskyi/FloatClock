NAME = FloatClock
PREFIX = /usr/local
BIN_DIR = $(PREFIX)/bin
LAUNCH_AGENTS_DIR = $(HOME)/Library/LaunchAgents

PLIST = $(NAME).plist
INSTALLED_PLIST = $(LAUNCH_AGENTS_DIR)/$(PLIST)
INSTALLED_BINARY = $(BIN_DIR)/$(NAME)

APP_BUNDLE = $(NAME).app
APP_CONTENTS = $(APP_BUNDLE)/Contents
APP_MACOS = $(APP_CONTENTS)/MacOS
APP_RESOURCES = $(APP_CONTENTS)/Resources

.PHONY: install uninstall all clean register unregister app clean-app help


all: $(NAME)

$(NAME): $(NAME).swift
	swiftc $< -o $@

$(PLIST): $(PLIST).in
	cat $< | sed 's,@BIN_DIR@,$(BIN_DIR),g;s,@NAME@,$(NAME),g' > $@

$(INSTALLED_BINARY): $(NAME)
	install -m 755 $(NAME) $(BIN_DIR)

$(INSTALLED_PLIST): $(PLIST)
	install -m 644 $(PLIST) $(INSTALLED_PLIST)

clean:
	rm -f $(NAME) $(PLIST)

clean-app:
	rm -rf $(APP_BUNDLE)

# App bundle creation
app: $(APP_BUNDLE)

$(APP_BUNDLE): $(NAME).swift Info.plist icon.svg
	@echo "Creating app bundle..."
	mkdir -p $(APP_MACOS)
	mkdir -p $(APP_RESOURCES)
	
	@echo "Compiling Swift source..."
	swiftc $(NAME).swift -o $(APP_MACOS)/$(NAME)
	
	@echo "Copying Info.plist..."
	cp Info.plist $(APP_CONTENTS)/
	
	@echo "Converting SVG icon to iconset..."
	mkdir -p AppIcon.iconset
	
	# Check for rsvg-convert dependency first
	@if ! command -v rsvg-convert >/dev/null 2>&1; then \
		echo "ERROR: rsvg-convert is required to build the app icon."; \
		echo ""; \
		echo "To install rsvg-convert, run:"; \
		echo "  brew install librsvg"; \
		echo ""; \
		echo "If you don't have Homebrew installed, visit: https://brew.sh"; \
		rm -rf AppIcon.iconset; \
		exit 1; \
	fi
	
	# Convert SVG to PNG using rsvg-convert
	@echo "Using rsvg-convert for high-quality conversion..."
	rsvg-convert -w 1024 -h 1024 icon.svg -o AppIcon.iconset/icon_512x512@2x.png
	rsvg-convert -w 512 -h 512 icon.svg -o AppIcon.iconset/icon_512x512.png
	rsvg-convert -w 512 -h 512 icon.svg -o AppIcon.iconset/icon_256x256@2x.png
	rsvg-convert -w 256 -h 256 icon.svg -o AppIcon.iconset/icon_256x256.png
	rsvg-convert -w 256 -h 256 icon.svg -o AppIcon.iconset/icon_128x128@2x.png
	rsvg-convert -w 128 -h 128 icon.svg -o AppIcon.iconset/icon_128x128.png
	rsvg-convert -w 64 -h 64 icon.svg -o AppIcon.iconset/icon_32x32@2x.png
	rsvg-convert -w 32 -h 32 icon.svg -o AppIcon.iconset/icon_32x32.png
	rsvg-convert -w 32 -h 32 icon.svg -o AppIcon.iconset/icon_16x16@2x.png
	rsvg-convert -w 16 -h 16 icon.svg -o AppIcon.iconset/icon_16x16.png
	
	@echo "Creating icns file..."
	iconutil -c icns AppIcon.iconset -o $(APP_RESOURCES)/AppIcon.icns
	
	@echo "Cleaning up temporary files..."
	rm -rf AppIcon.iconset
	
	@echo "App bundle created successfully: $(APP_BUNDLE)"
	@echo "You can now run: open $(APP_BUNDLE)"

install: $(INSTALLED_BINARY)

uninstall: unregister
	rm -f $(INSTALLED_BINARY) $(INSTALLED_PLIST)

unregister:
	test -f $(INSTALLED_PLIST) && launchctl unload $(INSTALLED_PLIST) || true

register: $(INSTALLED_BINARY) $(INSTALLED_PLIST)
	launchctl load $(INSTALLED_PLIST)

help:
	@echo "Available targets:"
	@echo "  all       - Build the command-line binary"
	@echo "  app       - Build the macOS app bundle (FloatClock.app)"
	@echo "  install   - Install the binary to $(BIN_DIR)"
	@echo "  register  - Register the LaunchAgent to start automatically"
	@echo "  unregister- Unregister the LaunchAgent"
	@echo "  uninstall - Uninstall binary and LaunchAgent"
	@echo "  clean     - Remove binary and generated plist"
	@echo "  clean-app - Remove the app bundle"
	@echo "  help      - Show this help message"