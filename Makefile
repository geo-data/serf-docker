##
# Install the serf from within a docker container
#
# This Makefile is designed to be run from within a docker container in order to
# install the application in the target.  The following is an example invocation:
#
# make install
#

SERF := /usr/local/bin/serf
SERF_VERSION := 0.6.4
SERVICE = serf

install: $(SERF)

runit: $(SERF) /etc/$(SERVICE)/config.d /etc/service/$(SERVICE)

docker:
	docker build -t geodata/serf:$(SERF_VERSION) . \
	&& docker tag -f geodata/serf:$(SERF_VERSION) geodata/serf:latest

$(SERF):
	curl -L --progress-bar https://dl.bintray.com/mitchellh/serf/$(SERF_VERSION)_linux_amd64.zip | funzip > $(SERF) \
	&& chmod +x $(SERF)

/etc/service/$(SERVICE): /etc/sv/$(SERVICE)/run
	ln -s /etc/sv/$(SERVICE) /etc/service/$(SERVICE)

/etc/sv/$(SERVICE)/run: run /etc/sv/$(SERVICE)
	sed 's/SERVICE/$(SERVICE)/g' run > /etc/sv/$(SERVICE)/run \
	&& chmod +x /etc/sv/$(SERVICE)/run

/etc/sv/$(SERVICE):
	mkdir -p /etc/sv/$(SERVICE)

/etc/$(SERVICE)/config.d:
	mkdir -p /etc/$(SERVICE)/config.d

.PHONY: install runit docker
