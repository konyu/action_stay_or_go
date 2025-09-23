# --- Builder: build stay_or_go binary from tag v0.2.0 with Go 1.25 ---
FROM golang:1.25 AS builder
WORKDIR /src
# Install stay_or_go CLI at v0.2.0
RUN go install github.com/uzumaki-inc/stay_or_go@v0.2.0

# --- Runner: minimal runtime image ---
FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /go/bin/stay_or_go /usr/local/bin/stay_or_go

# Entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]