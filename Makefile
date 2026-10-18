PREFIX ?= /usr
DESTDIR ?=
SHARE = $(DESTDIR)$(PREFIX)/share/omarchy-mac-keys

test:
	lua tests/run.lua
	bash -n bin/mac-keys
	luac -p hypr/*.lua

install:
	install -Dm755 bin/mac-keys $(SHARE)/bin/mac-keys
	install -Dm644 -t $(SHARE)/hypr hypr/*.lua
	install -Dm644 -t $(SHARE)/ghostty ghostty/mac-keys.conf
	for p in shell/*/; do install -Dm644 -t $(SHARE)/$$p $$p*; done
	install -dm755 $(DESTDIR)$(PREFIX)/bin
	ln -sf ../share/omarchy-mac-keys/bin/mac-keys $(DESTDIR)$(PREFIX)/bin/mac-keys
	install -Dm644 LICENSE $(DESTDIR)$(PREFIX)/share/licenses/omarchy-mac-keys/LICENSE

.PHONY: test install
