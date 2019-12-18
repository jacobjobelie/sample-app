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
RUN ["npm", "lint"]
# Gets Sonarqube Scanner from Dockerhub and runs it
FROM newmitch/sonar-scanner:latest as sonarqube
COPY --from=builder /usr/src/app/src /root/src
# Runs Unit Tests
FROM node:12.14.0-alpine as unit-tests
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN ["npm", "test"]
# Runs Accessibility Tests
FROM node:12.14.0-alpine as access-tests
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN ["npm", "access-tests"]
# Starts and Serves Web Page
FROM node:12.14.0-alpine as serve
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app ./
COPY --from=builder package* ./
RUN ["npm", "start"]