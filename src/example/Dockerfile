# syntax=docker/dockerfile:1.4  

# Example simple Dockerfile for fallback() server
# with HAProxy in front
FROM haproxytech/haproxy-alpine:2.0

###############
# Environment #
###############
ENV ETHEREUM_RPC_HOST="127.0.0.1"
ENV ETHEREUM_RPC_PORT=8545

ENV PORT=8000
ENV FALLBACK_SERVER_CONTRACT_ADDRESS=""

# `call` or `send`
ENV SERVER_MODE="call"
# Only required if using `send` mode (i.e. `send-server.js`)
ENV PAYER_PRIVATE_KEY=""

##########
# Set Up #
##########
WORKDIR /app

COPY <<EOF haproxy.cfg
defaults
  mode tcp
  timeout client 30s

frontend fallback-frontend
  bind :80
  # Rate limiting
  # https://www.haproxy.com/blog/four-examples-of-haproxy-rate-limiting/
  stick-table  type ipv6  size 25k  expire 30s  store http_req_rate(10s)
  http-request track-sc0 src
  http-request deny deny_status 429 if { sc_http_req_rate(0) gt 20 }
  maxconn 25000

  default_backend fallback-backend

backend fallback-backend
  timeout queue 30s
  server server1 127.0.0.1:${PORT}
EOF

RUN mv haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
RUN apk add --update nodejs npm

RUN git clone https://github.com/nathanhleung/fallback

WORKDIR /app/fallback/src/example
RUN npm install

# Overwrite default HAProxy `docker-entrypoint.sh`. Mostly copied from
# https://github.com/haproxytech/haproxy-docker-alpine/blob/main/2.8/docker-entrypoint.sh
COPY <<'EOF' /docker-entrypoint.sh
#!/bin/sh
set -e

# Start server
npx pm2 start "/app/fallback/src/example/${SERVER_MODE}-server.js"

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	shift # "haproxy"
	# if the user wants "haproxy", let's add a couple useful flags
	#   -W  -- "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
	#   -db -- disables background mode
	set -- haproxy -W -db "$@"
fi

exec "$@"
EOF