.PHONY: build_%

# Current apache hadoop releases: http://hadoop.apache.org/releases.html

HADOOP_26_VERSION = 2.6.5
HADOOP_210_VERSION = 2.10.0
HADOOP_32_VERSION = 3.2.1
PROTOBUF_VERSION = 3.13.0

DOCKER = docker
DOCKER_REPO = registry.cn-hangzhou.aliyuncs.com/fzn0268-pub/hadoop

all: build

### Build hadoop 3.2 images with native libs.
build: build-$(HADOOP_32_VERSION)
build-%: hadoop-native-%.tar
	$(DOCKER) build -t hadoop:$* \
	--build-arg HADOOP_VERSION=$* \
	.

tag: tag-$(HADOOP_32_VERSION)
tag-%:
	$(DOCKER) tag hadoop:$* $(DOCKER_REPO):$*

push: push-$(HADOOP_32_VERSION)
push-%:
	$(DOCKER) push $(DOCKER_REPO):$*

### Fetch source from closest mirror
hadoop-%-src.tar.gz:
	curl -sfL http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-$*/hadoop-$*-src.tar.gz | \
		egrep -C 3 "We suggest" | \
		perl -n -e'/href="(.*?)"/ && print $$1' | \
		xargs curl -LO

### Fetch binary distribution from closest mirror
hadoop-%.tar.gz:
	curl -sfL http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-$*/hadoop-$*.tar.gz | \
		egrep -C 3 "We suggest" | \
		perl -n -e'/href="(.*?)"/ && print $$1' | \
		xargs curl -LO

### Fetch protobuf source
protobuf-cpp-%.tar.gz:
	HTTPS_PROXY=http://localhost:8118 curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v$*/protobuf-cpp-$*.tar.gz

# Keep intermediate downloads.
.PRECIOUS: protobuf-cpp-%.tar.gz hadoop-%-src.tar.gz hadoop-%.tar.gz

### Compile native libs (~10min)
native_libs_%: hadoop-%-src.tar.gz protobuf-cpp-$(PROTOBUF_VERSION).tar.gz
	$(DOCKER) build -f Dockerfile-compile -t hadoop-nativelibs:$*\
		--build-arg=HADOOP_VERSION=$* \
		--build-arg=PROTOBUF_VERSION=$(PROTOBUF_VERSION) \
		.

### Extract native libs from previous compile target
hadoop-native-%.tar: native_libs_% hadoop-%.tar.gz
	$(DOCKER) run --rm \
	 	-e HADOOP_VERSION=$* \
		hadoop-nativelibs:$* > hadoop-native-$*.tar
