# Bare-bones floating clock for macOS

My setup has auto-hide for menu bar and dock, so I use this clock to show the
current time in the bottom right corner.

Screenshot:

![screenshot](screenshot.png)

Forked and slightly reworked from https://github.com/kolbusa/FloatClock.

## Build instructions

Requires Swift

Build command-line version: `make all`

**Build macOS app bundle: `make app`**

Clean: `make clean`

Install: `sudo make install`

Add to login items: `make register`

Remove from login items: `make unregister`

Uninstall: `make uninstall`

## Usage

### App Bundle
Run `make app` to create `FloatClock.app` which you can double-click to run or drag to your Applications folder.

### Features
- Auto-hides when mouse is away from the bottom of the screen
- Shows when mouse approaches the bottom edge (2px threshold)  
- Left-click opens Calendar app
- Right-click shows context menu with "Quit" option
- Displays time and date in a floating window
