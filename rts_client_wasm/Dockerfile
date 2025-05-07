FROM rust:1.81 as builder

WORKDIR /app

# Install wasm-pack
RUN cargo install wasm-pack --locked

# Copy manifests and source
COPY RUST_Infinite/Cargo.toml Cargo.toml
COPY RUST_Infinite/rts_core/Cargo.toml rts_core/Cargo.toml
COPY RUST_Infinite/rts_client_wasm/Cargo.toml rts_client_wasm/Cargo.toml
# Add rts_server manifest and sources for workspace resolution
COPY RUST_Infinite/rts_server/Cargo.toml rts_server/Cargo.toml
COPY RUST_Infinite/rts_client_wasm/src rts_client_wasm/src
COPY RUST_Infinite/rts_core/src rts_core/src
COPY RUST_Infinite/rts_server/src rts_server/src

# copy client crate into the workspace
COPY RUST_Infinite/rts_client_wasm/Cargo.toml   rts_client_wasm/Cargo.toml
COPY RUST_Infinite/rts_client_wasm/src          rts_client_wasm/src

# Switch into the client crate directory before building
WORKDIR /app/rts_client_wasm
RUN wasm-pack build --release --target web

# Create an improved runtime configuration script and startup entrypoint
RUN cat <<'EOF' > /app/rts_client_wasm/start.sh
#!/bin/sh
# Get the server host from environment variable or use a safe default
# PUBLIC_HOST should be set to the externally accessible hostname/IP of the server
HOST_ADDR="${PUBLIC_HOST:-$SERVER_HOST}"

# Create config with external-facing URLs for browser access
echo "window.RTS_CONFIG = {" > /web/config.js
echo "  serverUrl: \"ws://$HOST_ADDR:$SERVER_PORT/ws\"," >> /web/config.js
echo "  apiUrl: \"http://$HOST_ADDR:$SERVER_PORT/\"" >> /web/config.js
echo "};" >> /web/config.js

echo "Generated config.js with serverUrl: ws://$HOST_ADDR:$SERVER_PORT/ws"

# Copy admin.html to admin/index.html right before serving to ensure it's up to date
mkdir -p /web/admin
cp -f /web/admin.html /web/admin/index.html

# Use a custom serve.json to properly handle routing
cat > /web/serve.json <<SERVECFG
{
  "public": "/web",
  "rewrites": [
    { "source": "/admin", "destination": "/admin/index.html" },
    { "source": "/admin/*", "destination": "/admin/index.html" }
  ],
  "cleanUrls": true
}
SERVECFG

exec npx serve -p 80 -c /web/serve.json
EOF
RUN chmod +x /app/rts_client_wasm/start.sh

# Final image: use debian:bookworm-slim
FROM debian:bookworm-slim

WORKDIR /web

# Copy the generated pkg from the correct location
COPY --from=builder /app/rts_client_wasm/pkg ./pkg
COPY RUST_Infinite/rts_client_wasm/index.html ./index.html
COPY RUST_Infinite/rts_client_wasm/admin.html ./admin.html
COPY --from=builder /app/rts_client_wasm/start.sh /start.sh

# Fix line endings and permissions for start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

# Install Node.js instead of the problematic static-file-server
RUN apt-get update && apt-get install -y curl ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g serve && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 80

ENTRYPOINT ["/start.sh"]
