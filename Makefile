REBAR ?= $(shell which rebar 2>/dev/null || which ./rebar)
REBAR_FLAGS ?=

VSN := "0.9.18"
BUILD_DATE := `LANG=C date +"%a %b %d %Y"`
NAME := ser
UNAME := $(shell uname -s)

ERLANG_ROOT := $(shell erl -eval 'io:format("~s", [code:root_dir()])' -s init stop -noshell)
ERLDIR=$(ERLANG_ROOT)/lib/$(NAME)-$(VSN)

EBIN_DIR := ebin
ERL_SOURCES  := $(wildcard src/*.erl)
ERL_OBJECTS  := $(ERL_SOURCES:src/%.erl=$(EBIN_DIR)/%.beam)
APP_FILE := $(EBIN_DIR)/$(NAME).app

all: compile

compile:
	@VSN=$(VSN) BUILD_DATE=$(BUILD_DATE) $(REBAR) compile $(REBAR_FLAGS)

rel: compile
	rm -rf rel/ser
	$(REBAR) generate $(REBAR_FLAGS)

run: rel
	chmod 755 ./rel/ser/bin/ser
	./rel/ser/bin/ser start

check: test
test: all
	$(REBAR) eunit $(REBAR_FLAGS)


install: all
ifeq ($(UNAME), Darwin)
	@test -d $(DESTDIR)$(ERLDIR) || mkdir -p $(DESTDIR)$(ERLDIR)/$(EBIN_DIR)
	@install -p -m 0644 $(APP_FILE) $(DESTDIR)$(ERLDIR)/$(APP_FILE)
	@install -p -m 0644 $(ERL_OBJECTS) $(DESTDIR)$(ERLDIR)/$(EBIN_DIR)
	@install -p -m 0644 priv/erlrtpproxy-ser.config $(DESTDIR)$(prefix)/etc/$(NAME).config
#	@install -p -m 0755 priv/erlrtpproxy-ser.init $(DESTDIR)$(prefix)/etc/rc.d/init.d/$(NAME)
	@install -p -m 0644 priv/erlrtpproxy-ser.sysconfig $(DESTDIR)$(prefix)/etc/$(NAME)
	@install -d $(DESTDIR)$(prefix)/var/lib/$(NAME)
	@echo "$(NAME) installed. \n"
else
	install -D -p -m 0644 $(APP_FILE) $(DESTDIR)$(ERLDIR)/$(APP_FILE)
	install -p -m 0644 $(ERL_OBJECTS) $(DESTDIR)$(ERLDIR)/$(EBIN_DIR)
	install -D -p -m 0644 priv/erlrtpproxy-ser.config $(DESTDIR)/etc/$(NAME).config
	install -D -p -m 0755 priv/erlrtpproxy-ser.init $(DESTDIR)/etc/rc.d/init.d/$(NAME)
	install -D -p -m 0644 priv/erlrtpproxy-ser.sysconfig $(DESTDIR)/etc/sysconfig/$(NAME)
	install -d $(DESTDIR)/var/lib/$(NAME)
endif

clean:
	@$(REBAR) clean $(REBAR_FLAGS)

uninstall:
	@if test -d $(ERLDIR); then rm -rf $(ERLDIR); fi
	if test -f /etc/$(NAME).config; then rm -rf /etc/$(NAME).config; fi
	@if test -f /etc/$(NAME); then rm -rf /etc/$(NAME); fi
	@if test -d /var/lib/$(NAME); then rm -rf /var/lib/$(NAME); fi
	@echo "$(NAME) uninstalled. \n
