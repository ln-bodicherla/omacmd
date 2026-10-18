PREFIX ?= /usr
DESTDIR ?=
SHARE = $(DESTDIR)$(PREFIX)/share/omacmd

test:
	lua tests/run.lua
	bash -n bin/omacmd
	luac -p hypr/*.lua

install:
	install -Dm755 bin/omacmd $(SHARE)/bin/omacmd
	install -Dm644 -t $(SHARE)/hypr hypr/*.lua
	install -Dm644 -t $(SHARE)/ghostty ghostty/omacmd.conf
	for p in shell/*/; do install -Dm644 -t $(SHARE)/$$p $$p*; done
	install -dm755 $(DESTDIR)$(PREFIX)/bin
	ln -sf ../share/omacmd/bin/omacmd $(DESTDIR)$(PREFIX)/bin/omacmd
	install -Dm644 LICENSE $(DESTDIR)$(PREFIX)/share/licenses/omacmd/LICENSE

.PHONY: test install
