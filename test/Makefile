# passable options: VERBOSE=1 SA_ALL=1
# sa = static analysis, ut = unit tests, st = system tests
MAKEFLAGS := -rR
SHELL := /bin/bash
is_parallel := $(if $(shell ps -p $${PPID} -o cmd|grep -P '\s+(--jobs|-\w*j(\s*[0-9]|\s|$$))'),1,)
project_root := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))/..)
maybe_devnull := $(if $(VERBOSE),,>/dev/null)
maybe_quiet := $(if $(VERBOSE),,-q)
st_root := $(project_root)/test/st
st_common := $(st_root)/common
systems := $(filter-out common,$(notdir $(wildcard $(st_root)/*)))
st := $(sort $(subst /,___,$(patsubst $(st_root)/%.sh,%,$(foreach f,$(systems),$(wildcard $(st_root)/$f/*.sh)))) \
             $(foreach s,$(systems),$s___$(patsubst %.sh,%,$(notdir $(wildcard $(st_common)/*.sh)))))

.PHONY: all clean sa st $(st) ut
.$(VERBOSE)SILENT:
.DELETE_ON_ERROR:
.INTERMEDIATE: $(st_common)/vpngate.csv $(project_root)/openvpn-unroot.bash

all: sa ut st

sa: $(project_root)/openvpn-unroot
	shellcheck -s bash $(if $(SA_ALL),,-e SC2155 )"$<"

$(project_root)/openvpn-unroot.bash: %.bash: %
	ln -s "$(@:%.bash=%)" "$@"

ut: | $(project_root)/openvpn-unroot.bash
	! $(project_root)/test/ut/ut.bats $(UT_OPTS)|grep -P '^(not|#)'

st: $(st)

$(st_common)/vpngate.csv:
	curl -s http://www.vpngate.net/api/iphone/|tail -n +3|head -n -1 >"$@"

$(st_common)/random.conf: | $(st_common)/vpngate.csv
	shuf -n1 "$|"|cut -d, -f15|tr -d '\r'|base64 --decode >"$@"

$(st): system = $(word 1,$(subst ___, ,$@))
$(st): script = $(word 2,$(subst ___, ,$@.sh))
$(filter %___random,$(st)): $(st_common)/random.conf
.SECONDEXPANSION:
$(st): %: $(st_root)/$$(system)/Dockerfile
	docker build $(maybe_quiet) -t "openvpn-unroot/$(system):latest" -f "$<" "$(dir $<)" $(maybe_devnull)
	docker run --rm --cap-add=NET_ADMIN --device /dev/net/tun -v "$(project_root)/openvpn-unroot:/usr/bin/openvpn-unroot" \
	           $$(for f in $(st_root)/common/* $(st_root)/$(system)/*; do echo -v "$$f:/tmp/test/$$(basename $$f)"; done) \
	           $(if $(is_parallel),,-it )-w "/tmp/test" openvpn-unroot/$(system):latest "./$(script)" $(maybe_devnull)

clean:
	rm -f $(project_root)/openvpn-unroot.bash $(st_common)/vpngate.csv $(st_common)/random.conf
