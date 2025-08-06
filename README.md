# Bare-bones floating clock for macOS

My setup has auto-hide for menu bar and dock, so I use this clock to show the
current time in the bottom right corner.

Screenshot:

![screenshot](screenshot.png)

Forked and slightly reworked from https://github.com/kolbusa/FloatClock.

## Quick Install

Download the latest DMG from the [releases page](https://github.com/honsiorovskyi/FloatClock/releases/latest) and drag the app to your Applications folder.

## Build instructions

Requires Swift and `rsvg-convert` (for app icon generation):
```bash
brew install librsvg
```

**Build targets:**
- `make` or `make all` - Build CLI binary to `build/FloatClock`
- `make app` - Build macOS app bundle to `build/FloatClock.app`
- `make dmg` - Create DMG installer at `build/FloatClock.dmg`
- `make clean` - Remove all build artifacts (`build/` directory)

**Installation targets:**
- `sudo make install` - Install CLI version to `/usr/local/bin`
- `make register` - Add CLI version to login items (auto-start)
- `make unregister` - Remove CLI version from login items
- `make uninstall` - Uninstall CLI version and remove from login items

All build artifacts are placed in the `build/` directory to keep the project root clean.

## Usage

### App Bundle
Run `make app` to create `build/FloatClock.app` which you can double-click to run or drag to your Applications folder.

### DMG Installer
Run `make dmg` to create `build/FloatClock.dmg` - a disk image with the app and Applications folder shortcut for easy installation.

### CLI Version
Run `make` to build the command-line version to `build/FloatClock`, or use `sudo make install` to install it system-wide.

### Features
- Auto-hides when mouse is away from the bottom of the screen
- Shows when mouse approaches the bottom edge (2px threshold)  
- Left-click opens Calendar app
- Right-click shows context menu with "Quit" option
- Displays time and date in a floating window
