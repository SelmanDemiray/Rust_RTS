FROM rust:1.81 as builder

WORKDIR /app

# Install sqlx-cli for offline mode preparation (if needed)
RUN cargo install sqlx-cli --no-default-features --features native-tls,postgres

# Copy manifests and source
COPY RUST_Infinite/Cargo.toml Cargo.toml
COPY RUST_Infinite/rts_core/Cargo.toml rts_core/Cargo.toml
COPY RUST_Infinite/rts_server/Cargo.toml rts_server/Cargo.toml
COPY RUST_Infinite/rts_server/src rts_server/src
COPY RUST_Infinite/rts_core/src rts_core/src
COPY RUST_Infinite/rts_client_wasm/Cargo.toml rts_client_wasm/Cargo.toml
COPY RUST_Infinite/rts_client_wasm/src rts_client_wasm/src

# Copy migrations and .env
COPY RUST_Infinite/rts_server/migrations rts_server/migrations
COPY RUST_Infinite/rts_server/.env rts_server/.env

# Build the server in release mode with SQLx offline mode
ENV SQLX_OFFLINE=true
RUN cargo build --release -p rts_server

# Final image
FROM debian:bookworm-slim

WORKDIR /app

# Install openssl for sqlx
RUN apt-get update && apt-get install -y libssl-dev libssl3 ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/rts_server /usr/local/bin/rts_server
COPY --from=builder /app/rts_server/migrations ./migrations
COPY --from=builder /app/rts_server/.env .env
# Copy sqlx-cli from the builder stage to the final stage
COPY --from=builder /usr/local/cargo/bin/sqlx /usr/local/bin/sqlx

# Add entrypoint script (uses the base image's /bin/sh)
RUN echo '#!/bin/sh\n\
set -e\n\
echo "Running migrations..."\n\
# Use the copied sqlx binary\n\
/usr/local/bin/sqlx migrate run --source ./migrations || exit 1\n\
echo "Starting server..."\n\
exec /usr/local/bin/rts_server\n' > /start.sh && chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
