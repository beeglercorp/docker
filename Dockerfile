# @see https://github.com/nodejs/docker-node/blob/master/Dockerfile-alpine.template
# @see https://github.com/mhart/alpine-node/blob/master/Dockerfile
FROM alpine:3.6

ARG NODE_VERSION=8.9.0
ARG YARN_VERSION=latest

# nodejs build dependencies
RUN apk add --no-cache --virtual .build-dependencies curl make gcc g++ python linux-headers binutils-gold gnupg libstdc++

RUN for key in \
    # nodejs gpg keys listed at https://github.com/nodejs/node#release-team
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    # yarn
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done

# nodejs
RUN curl -sfSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.xz
RUN curl -sfSL https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc \
  | gpg --batch --decrypt \
  | grep " node-v${NODE_VERSION}.tar.xz\$" \
  | sha256sum -c \
  | grep .
RUN tar -xf node-v${NODE_VERSION}.tar.xz
RUN cd node-v${NODE_VERSION} && \
  ./configure --prefix=/usr --fully-static && \
  make -j$(getconf _NPROCESSORS_ONLN) && \
  make install

# yarn
RUN cd / && curl -sfSL -O https://yarnpkg.com/${YARN_VERSION}.tar.gz -O https://yarnpkg.com/${YARN_VERSION}.tar.gz.asc
RUN gpg --batch --verify /${YARN_VERSION}.tar.gz.asc /${YARN_VERSION}.tar.gz
RUN mkdir /usr/local/share/yarn
RUN tar -xf /${YARN_VERSION}.tar.gz -C /usr/local/share/yarn --strip 1
RUN ln -s /usr/local/share/yarn/bin/yarn /usr/local/bin/
RUN ln -s /usr/local/share/yarn/bin/yarnpkg /usr/local/bin/

# cleanup
RUN apk del .build-dependencies
RUN rm -rf \
  /usr/include \
  /node-v${NODE_VERSION}* \
  /usr/share/man \
  /tmp/* \
  /var/cache/apk/* \
  /root/.npm \
  /root/.node-gyp \
  /root/.gnupg \
  /usr/lib/node_modules/npm/changelogs \
  /usr/lib/node_modules/npm/man \
  /usr/lib/node_modules/npm/doc \
  /usr/lib/node_modules/npm/html \
  /usr/lib/node_modules/npm/scripts \
  /usr/lib/node_modules/npm/changelogs \
  /${YARN_VERSION}.tar.gz*;
RUN find /usr/lib/node_modules/ -type d -name "__tests__" -name "coverage" -name "tests" -exec rm -rf {} \;
