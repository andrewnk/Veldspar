# To build:
# docker build -t veldspar .

# To run the miner (change the address and threads accordingly):
# docker run -it veldspar miner --address XXXXXXXX --threads 2

FROM ubuntu:16.04
LABEL maintainer="andrewnk"
LABEL Description="Docker container for Veldpsar on Ubuntu 16.04 adapted from Haris Amin's original Dockerfile"

ARG SWIFT_PLATFORM=ubuntu16.04
ARG SWIFT_BRANCH=swift-4.1.3-release
ARG SWIFT_VERSION=swift-4.1.3-RELEASE

ENV SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_VERSION=$SWIFT_VERSION

RUN apt-get -q update && \
    apt-get -q install -y \
    clang-3.8 \
    curl \
    libicu-dev \
    libcurl3 \
    libssl-dev \
    sqlite3 \
    libsqlite3-dev \
    libcurl3-dev \
    uuid-dev \
    libpython-dev \
    libxml2 \
    git && \
    update-alternatives --quiet --install /usr/bin/clang clang /usr/bin/clang-3.8 100 && \
    update-alternatives --quiet --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100 && \
    rm -r /var/lib/apt/lists/*

RUN SWIFT_URL=https://swift.org/builds/$SWIFT_BRANCH/$(echo "$SWIFT_PLATFORM" | tr -d .)/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz && \
    curl -fSsL $SWIFT_URL -o swift.tar.gz && \
    curl -fSsL $SWIFT_URL.sig -o swift.tar.gz.sig && \
    export GNUPGHOME="$(mktemp -d)" && \
    set -e; \
        for key in \
      # pub   rsa4096 2017-11-07 [SC] [expires: 2019-11-07]
      # 8513444E2DA36B7C1659AF4D7638F1FB2B2B08C4
      # uid           [ unknown] Swift Automatic Signing Key #2 <swift-infrastructure@swift.org>
          8513444E2DA36B7C1659AF4D7638F1FB2B2B08C4 \
      # pub   4096R/91D306C6 2016-05-31 [expires: 2018-05-31]
      #       Key fingerprint = A3BA FD35 56A5 9079 C068  94BD 63BC 1CFE 91D3 06C6
      # uid                  Swift 3.x Release Signing Key <swift-infrastructure@swift.org>
          A3BAFD3556A59079C06894BD63BC1CFE91D306C6 \
      # pub   4096R/71E1B235 2016-05-31 [expires: 2019-06-14]
      #       Key fingerprint = 5E4D F843 FB06 5D7F 7E24  FBA2 EF54 30F0 71E1 B235
      # uid                  Swift 4.x Release Signing Key <swift-infrastructure@swift.org>
          5E4DF843FB065D7F7E24FBA2EF5430F071E1B235 \
        ; do \
          gpg --quiet --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
        done && \
    gpg --batch --verify --quiet swift.tar.gz.sig swift.tar.gz && \
    tar -xzf swift.tar.gz --directory / --strip-components=1 && \
    rm -r "$GNUPGHOME" swift.tar.gz.sig swift.tar.gz && \
    chmod -R o+r /usr/lib/swift 

RUN git clone https://github.com/editfmah/veldspar.git

WORKDIR veldspar

RUN swift build -c release

RUN groupadd -g 2000 veldspar && \
    useradd -m -u 2001 -g veldspar veldspar && \
    mkdir -p /home/veldspar/.Veldspar && \
    chmod a+rx .build/release/miner && \
    chmod a+rx .build/release/simplewallet && \
    chmod a+rx .build/release/veldspard && \
    cp .build/release/miner /usr/local/bin && \
    cp .build/release/simplewallet /usr/local/bin && \
    cp .build/release/veldspard /usr/local/bin

WORKDIR /home/veldspar/.Veldspar

VOLUME /home/veldspar/.Veldspar

USER veldspar

EXPOSE 14242
