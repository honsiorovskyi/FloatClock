NAME = FloatClock
PREFIX = /usr/local
BIN_DIR = $(PREFIX)/bin
LAUNCH_AGENTS_DIR = $(HOME)/Library/LaunchAgents

PLIST = $(NAME).plist
INSTALLED_PLIST = $(LAUNCH_AGENTS_DIR)/$(PLIST)
INSTALLED_BINARY = $(BIN_DIR)/$(NAME)

.PHONY: install uninstall all clean register unregister

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

install: $(INSTALLED_BINARY)

uninstall: unregister
	rm -f $(INSTALLED_BINARY) $(INSTALLED_PLIST)

unregister:
	test -f $(INSTALLED_PLIST) && launchctl unload $(INSTALLED_PLIST) || true

register: $(INSTALLED_BINARY) $(INSTALLED_PLIST)
	launchctl load $(INSTALLED_PLIST)
