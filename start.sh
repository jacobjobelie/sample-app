#!/bin/bash

if [[ -z "${NODE_PORT}" ]]; then
  NODE_PORT="3000"
else
  NODE_PORT="${NODE_PORT}"
fi

# Map NODE_PORT to Nginx default.conf

sed -i "s/___NODE_PORT___/$NODE_PORT/g" /etc/nginx/conf.d/default.conf

# Update nginx to match worker_processes to no. of cpu's
procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes  1/worker_processes $procs/" /etc/nginx/nginx.conf

# Always chown webroot for better mounting
mkdir -p /usr/share/nginx/html
chown -Rf nginx.nginx /usr/share/nginx/html

# Start supervisord and services

if [[ -z "${NODE_MODE}" ]]; then
  NODE_MODE="prod"
else
  NODE_MODE="${NODE_MODE}"
fi

# Create Nginx pid
mkdir -p /run/nginx

if [[ "${NODE_MODE}" = "prod" ]]; then
/usr/bin/supervisord -n -c /etc/supervisord.conf
elif [[ "${NODE_MODE}" = "dev" ]]; then
/usr/bin/supervisord -n -c /etc/supervisord-dev.conf
fi
