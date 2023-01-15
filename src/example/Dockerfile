# syntax=docker/dockerfile:1.4  

# Example simple Dockerfile for fallback() server
# with HAProxy in front for caching and rate-limiting
FROM haproxytech/haproxy-alpine:2.0

###############
# Environment #
###############
ENV ETHEREUM_RPC_URL="http://127.0.0.1:8545"

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
  mode http
  timeout client 30s
  timeout connect 60s
  timeout server 60s

frontend fallback-frontend
  bind :80
  # Rate limiting - no more than 20 requests every 10 seconds
  # https://www.haproxy.com/blog/four-examples-of-haproxy-rate-limiting/
  stick-table  type ipv6  size 25k  expire 30s  store http_req_rate(10s)
  http-request track-sc0 src
  http-request deny deny_status 429 if { sc_http_req_rate(0) gt 20 }
  maxconn 25000

  default_backend fallback-backend

  # Return cache status header
  http-response set-header X-Cache-Status HIT if !{ srv_id -m found }
  http-response set-header X-Cache-Status MISS if { srv_id -m found }


cache fallback-index-cache
  total-max-size 32 # MB
  max-object-size 10000 # bytes
  max-age 3600 # seconds

cache fallback-get-cache
  total-max-size 32 # MB
  max-object-size 10000 # bytes
  max-age 5 # seconds

backend fallback-backend
  timeout queue 30s

  # Cache GET requests, cache index for 60 minutes
  # https://www.haproxy.com/blog/accelerate-your-apis-by-using-the-haproxy-cache/
  http-request cache-use fallback-index-cache if { path / }
  http-request cache-use fallback-get-cache if { method GET } !{ path / }

  http-response cache-store fallback-index-cache
  http-response cache-store fallback-get-cache

  server server1 127.0.0.1:${PORT}
EOF

RUN mv haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
RUN apk update
RUN apk add git
RUN apk add nodejs npm

RUN git clone https://github.com/nathanhleung/fallback

WORKDIR /app/fallback/src/example
RUN npm install
RUN npm install -g pm2

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

RUN chmod +x /docker-entrypoint.sh

# To build the image, change into this directory and run:
#
# `docker build --no-cache -t nathanhleung/fallback:latest .`

# To run the image, add your env vars and run:
#
# `docker run --env ETHEREUM_RPC_URL= \
#    --env FALLBACK_SERVER_CONTRACT_ADDRESS= \
#    --env SERVER_MODE= \
#    --env PAYER_PRIVATE_KEY= \
#    --publish 8080:80 \
#    nathanhleung/fallback`
#
# This will expose the container on localhost:8080.