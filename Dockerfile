# Copies in our code and runs NPM Install
FROM node:12.14.0-alpine as builder
WORKDIR /usr/src/app
COPY package* ./
COPY src/ src/
RUN ["npm", "install"]
# Lints Code
FROM node:12.14.0-alpine as linting
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN ["npm", "run", "lint"]
# Runs Unit Tests
FROM node:12.14.0-alpine as unit-tests
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN ["npm", "run", "test"]
# Runs Accessibility Tests
FROM node:12.14.0-alpine as access-tests
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN ["npm", "run", "access-tests"]

FROM alpine:latest as toolchain
RUN apk update
RUN apk add git
RUN apk add python py2-pip
RUN pip install wheel
RUN pip install supervisor supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf
ADD ./supervisord-dev.conf /etc/supervisord-dev.conf

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Install Nginx
RUN apk add nginx

# Override Nginx's default config
RUN rm -rf /etc/nginx/conf.d/default.conf
ADD nginx/default.conf /etc/nginx/conf.d/default.conf

# !!!!!!!!!!!!!!!!!!!!!!
# Build Node.js 11.x
# !!!!!!!!!!!!!!!!!!!!!!
ENV NODE_VERSION 12.4.0
ENV NODE_PORT 3000
ENV NODE_MODE prod

RUN addgroup -g 1000 node \
    && adduser -u 1000 -G node -s /bin/sh -D node \
    && apk add --no-cache \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python \
  # gpg keys listed at https://github.com/nodejs/node#release-team
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && apk del .build-deps \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

RUN apk add --no-cache \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python
# Add Node.js app

WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .

# Build app packages
# RUN yarn build

# Install Bash Shell
RUN apk add --update bash && apk del .build-deps

# Clean up
RUN rm -rf /var/cache/apk/*

# Add a startup script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

# Expose Nginx port
EXPOSE 8080

# Run the startup script
WORKDIR /

CMD ["/start.sh"]



