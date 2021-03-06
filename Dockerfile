# Copies in our code and runs NPM Install
FROM node:12.14.0-alpine as builder
WORKDIR /usr/src/app
COPY rollup.config.js rollup.config.js
COPY package* ./
COPY src/ src/
COPY nginx/ nginx/
COPY public/ public/
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
# Run build
FROM node:12.14.0-alpine as build
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ .
RUN ["npm", "run", "build"]

##### ALPINE CODE ########
FROM nginx:alpine
RUN apk add --no-cache --virtual .build-deps \
        nano

# Override Nginx's default config
RUN rm /etc/nginx/nginx.conf
COPY --from=builder /usr/src/app/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /usr/src/app/nginx/nginx.feedback.conf /etc/nginx/sites-available/feedback.conf
#
RUN mkdir -p /etc/nginx/sites-enabled/ && ln -s /etc/nginx/sites-available/feedback.conf etc/nginx/sites-enabled/feedback.conf && rm /etc/nginx/conf.d/default.conf

COPY --from=build /usr/src/app/public /usr/share/nginx/html

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]



