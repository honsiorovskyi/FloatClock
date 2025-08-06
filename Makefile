NAME = FloatClock
PREFIX = /usr/local
BIN_DIR = $(PREFIX)/bin
LAUNCH_AGENTS_DIR = $(HOME)/Library/LaunchAgents
BUILD_DIR = build

PLIST = $(BUILD_DIR)/$(NAME).plist
INSTALLED_PLIST = $(LAUNCH_AGENTS_DIR)/$(NAME).plist
INSTALLED_BINARY = $(BIN_DIR)/$(NAME)

APP_BUNDLE = $(BUILD_DIR)/$(NAME).app
APP_CONTENTS = $(APP_BUNDLE)/Contents
APP_MACOS = $(APP_CONTENTS)/MacOS
APP_RESOURCES = $(APP_CONTENTS)/Resources

.PHONY: install uninstall clean register unregister app dmg help

$(BUILD_DIR)/$(NAME): $(NAME).swift | $(BUILD_DIR)
	swiftc $< -o $@

$(PLIST): $(NAME).plist.in | $(BUILD_DIR)
	cat $< | sed 's,@BIN_DIR@,$(BIN_DIR),g;s,@NAME@,$(NAME),g' > $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(INSTALLED_BINARY): $(BUILD_DIR)/$(NAME)
	install -m 755 $< $(BIN_DIR)/$(NAME)

$(INSTALLED_PLIST): $(PLIST)
	install -m 644 $(PLIST) $(LAUNCH_AGENTS_DIR)/$(NAME).plist

clean:
	rm -rf $(BUILD_DIR)

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
	mkdir -p $(BUILD_DIR)/AppIcon.iconset
	
	# Check for rsvg-convert dependency first
	@if ! command -v rsvg-convert >/dev/null 2>&1; then \
		echo "ERROR: rsvg-convert is required to build the app icon."; \
		echo ""; \
		echo "To install rsvg-convert, run:"; \
		echo "  brew install librsvg"; \
		echo ""; \
		echo "If you don't have Homebrew installed, visit: https://brew.sh"; \
		rm -rf $(BUILD_DIR)/AppIcon.iconset; \
		exit 1; \
	fi
	
	# Convert SVG to PNG using rsvg-convert
	@echo "Using rsvg-convert for high-quality conversion..."
	rsvg-convert -w 1024 -h 1024 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_512x512@2x.png
	rsvg-convert -w 512 -h 512 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_512x512.png
	rsvg-convert -w 512 -h 512 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_256x256@2x.png
	rsvg-convert -w 256 -h 256 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_256x256.png
	rsvg-convert -w 256 -h 256 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_128x128@2x.png
	rsvg-convert -w 128 -h 128 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_128x128.png
	rsvg-convert -w 64 -h 64 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_32x32@2x.png
	rsvg-convert -w 32 -h 32 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_32x32.png
	rsvg-convert -w 32 -h 32 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_16x16@2x.png
	rsvg-convert -w 16 -h 16 icon.svg -o $(BUILD_DIR)/AppIcon.iconset/icon_16x16.png
	
	@echo "Creating icns file..."
	iconutil -c icns $(BUILD_DIR)/AppIcon.iconset -o $(APP_RESOURCES)/AppIcon.icns
	
	@echo "Cleaning up temporary files..."
	rm -rf $(BUILD_DIR)/AppIcon.iconset
	
	@echo "App bundle created successfully: $(APP_BUNDLE)"
	@echo "You can now run: open $(APP_BUNDLE)"

# DMG creation
dmg: $(BUILD_DIR)/$(NAME).dmg

$(BUILD_DIR)/$(NAME).dmg: $(APP_BUNDLE)
	@echo "Creating DMG file..."
	@rm -f $(BUILD_DIR)/$(NAME).dmg
	@mkdir -p $(BUILD_DIR)/dmg-temp
	@cp -R $(APP_BUNDLE) $(BUILD_DIR)/dmg-temp/
	@ln -sf /Applications $(BUILD_DIR)/dmg-temp/Applications
	@echo "Creating DMG with hdiutil..."
	@hdiutil create -volname "$(NAME)" -srcfolder $(BUILD_DIR)/dmg-temp -ov -format UDZO $(BUILD_DIR)/$(NAME).dmg
	@rm -rf $(BUILD_DIR)/dmg-temp
	@echo "DMG created successfully: $(BUILD_DIR)/$(NAME).dmg"

install: $(INSTALLED_BINARY)

uninstall: unregister
	rm -f $(INSTALLED_BINARY) $(LAUNCH_AGENTS_DIR)/$(NAME).plist

unregister:
	test -f $(LAUNCH_AGENTS_DIR)/$(NAME).plist && launchctl unload $(LAUNCH_AGENTS_DIR)/$(NAME).plist || true

register: $(INSTALLED_BINARY) $(INSTALLED_PLIST)
	launchctl load $(LAUNCH_AGENTS_DIR)/$(NAME).plist

help:
	@echo "Available targets:"
	@echo "  all       - Build the command-line binary"
	@echo "  app       - Build the macOS app bundle (FloatClock.app)"
	@echo "  dmg       - Create a DMG installer (requires app target)"
	@echo "  install   - Install the binary to $(BIN_DIR)"
	@echo "  register  - Register the LaunchAgent to start automatically"
	@echo "  unregister- Unregister the LaunchAgent"
	@echo "  uninstall - Uninstall binary and LaunchAgent"
	@echo "  clean     - Remove all build artifacts (build/ directory)"
	@echo "  help      - Show this help message"