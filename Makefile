MAINTAINER = 'Peter Fern <github@0xc0dedbad.com>'

VERSION ?= 1.4.0
ITERATION ?= 1
ARCH ?= amd64
DEB_DIST ?= unstable
RPM_DIST ?= el7
DEB_ETC_DIR ?= /etc/consul.d
RPM_ETC_DIR ?= /etc/consul
URL = https://releases.hashicorp.com/consul/$(VERSION)/consul_$(VERSION)_linux_$(ARCH).zip

BASE_DIR = $(CURDIR)
CACHE_DIR = $(BASE_DIR)/.cache/$(VERSION)
MAIN_BUILD_DIR = $(CACHE_DIR)/$(ARCH)/build
OUT_DIR = $(BASE_DIR)/pkg/$(VERSION)

define PKG_DESCRIPTION
A tool for discovering and configuring services - main package
 Consul is a tool for service discovery and configuration. Consul is
 distributed, highly available, and extremely scalable. Consul provides
 several key features:
 * Service Discovery - Consul makes it simple for services to register
 themselves and to discover other services via a DNS or HTTP interface.
 External services such as SaaS providers can be registered as well.
 * Health Checking - Health Checking enables Consul to quickly alert
 operators about any issues in a cluster. The integration with service
 discovery prevents routing traffic to unhealthy hosts and enables service
 level circuit breakers.
 * Key/Value Storage - A flexible key/value store enables storing
 dynamic configuration, feature flagging, coordination, leader election and
 more. The simple HTTP API makes it easy to use anywhere.
 * Multi-Datacenter - Consul is built to be datacenter aware, and can
 support any number of regions without complex configuration.
 .
 This is the main package. It installs the consul binary, which is the only
 required component on both client and server nodes.
endef

export PKG_DESCRIPTION

.PHONY: all

all: deb rpm

clean:
	rm -rf $(OUT_DIR)
	rm -rf $(CACHE_DIR)

distclean:
	rm -rf $(BASE_DIR)/.cache
	rm -rf $(BASE_DIR)/pkg

rpm: download unpack
	# Unfortunately, deb and rpm packages differ in config directory, so mangle
	# that here
	[ -d $(MAIN_BUILD_DIR)$(DEB_ETC_DIR) ] && rm -rf $(MAIN_BUILD_DIR)$(DEB_ETC_DIR) || true
	## Build main package
	mkdir -p $(MAIN_BUILD_DIR)$(RPM_ETC_DIR)
	# Install systemd unit
	mkdir -p $(MAIN_BUILD_DIR)/lib/systemd/system
	cp $(BASE_DIR)/init/systemd/consul.rpm $(MAIN_BUILD_DIR)/lib/systemd/system/consul.service
	mkdir -p $(MAIN_BUILD_DIR)/etc/sysconfig
	cp $(BASE_DIR)/init/sysconfig/consul $(MAIN_BUILD_DIR)/etc/sysconfig/
	# Install base config
	cp $(BASE_DIR)/etc/consul.d/20-agent.json $(MAIN_BUILD_DIR)$(RPM_ETC_DIR)/20-agent.json-dist
	mkdir -p $(OUT_DIR)
	cd $(OUT_DIR) ; \
	fpm -t rpm -s dir -C $(MAIN_BUILD_DIR) --name consul \
		--version $(VERSION) --iteration $(ITERATION) --license MPL-2.0 \
		--architecture $(ARCH) --maintainer $(MAINTAINER) \
		--description "$${PKG_DESCRIPTION}" \
		--url https://www.consul.io/ \
		--post-install $(BASE_DIR)/actions/postinst \
		--template-scripts --template-value config_dir=$(RPM_ETC_DIR) \
		--rpm-tag 'Requires(post): /usr/sbin/groupadd, /usr/sbin/useradd, /usr/bin/getent' \
		--rpm-os linux \
		--rpm-dist $(RPM_DIST) \
		usr etc var lib
	@echo
	@echo rpm package available at $(OUT_DIR)
	@echo

deb: download unpack
	# Unfortunately, deb and rpm packages differ in config directory, so mangle
	# that here
	[ -d $(MAIN_BUILD_DIR)$(RPM_ETC_DIR) ] && rm -rf $(MAIN_BUILD_DIR)$(RPM_ETC_DIR) || true
	[ -d $(MAIN_BUILD_DIR)/etc/sysconfig ] && rm -rf $(MAIN_BUILD_DIR)/etc/sysconfig || true
	## Build main package
	mkdir -p $(MAIN_BUILD_DIR)$(DEB_ETC_DIR)
	# Install base config
	cp $(BASE_DIR)/etc/consul.d/20-agent.json $(MAIN_BUILD_DIR)$(DEB_ETC_DIR)
	mkdir -p $(OUT_DIR)
	cd $(OUT_DIR) ; \
	fpm -t deb -s dir -C $(MAIN_BUILD_DIR) --name consul \
		--version $(VERSION) --iteration "$(ITERATION)~$(DEB_DIST)0" --license MPL-2.0 \
		--architecture $(ARCH) --maintainer $(MAINTAINER) \
		--description "$${PKG_DESCRIPTION}" \
		--url https://www.consul.io/ \
		--post-install $(BASE_DIR)/actions/postinst \
		--template-scripts --template-value config_dir=$(DEB_ETC_DIR) \
		--deb-compression xz \
		--deb-default $(BASE_DIR)/init/default/consul \
		--deb-upstart $(BASE_DIR)/init/upstart/consul \
		--deb-systemd $(BASE_DIR)/init/systemd/consul \
		usr etc var
	@echo
	@echo deb package available at $(OUT_DIR)
	@echo

download:
	if [ ! -f $(CACHE_DIR)/$(ARCH)/consul.zip ]; then \
		mkdir -p $(CACHE_DIR)/$(ARCH) ; \
		wget $(URL) -O $(CACHE_DIR)/$(ARCH)/consul.zip ; \
	fi

unpack:
	mkdir -p $(MAIN_BUILD_DIR)/usr/bin
	cd $(MAIN_BUILD_DIR)/usr/bin/ ; \
	unzip -o $(CACHE_DIR)/$(ARCH)/consul.zip
	mkdir -p $(MAIN_BUILD_DIR)/var/lib/consul
