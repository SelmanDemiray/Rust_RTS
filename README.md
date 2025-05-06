# RTS_RUST

A cross-platform, scalable real-time strategy (RTS) game engine and demo, written in Rust.  
This project separates core logic, server, and WASM client for maximum flexibility and performance.

## Project Structure

- **rts_core**: Shared protocol types, core logic/data structures.
- **rts_server**: Server backend (Axum, SQLx) with REST, WebSocket, and game state management.
- **rts_client_wasm**: WebAssembly client for modern browsers, using Web APIs.
- *(planned)*: Desktop/mobile clients, admin UI, etc.

---

## Deployment Types

RTS_RUST supports several deployment environments:

### 1. Local Development (Recommended for testing)

- **Run the server and client locally.**
- Requires Rust, Node.js (for WASM), PostgreSQL.

#### Setup Steps:
1. **Set up PostgreSQL**  
   Edit `rts_server/.env` with your DB credentials.  
   Start PostgreSQL locally (or use Docker).

2. **Run migrations:**
   ```sh
   cd rts_server
   sqlx migrate run
   ```

3. **Start the server:**
   ```sh
   cargo run -p rts_server
   ```

4. **Build the WASM client:**
   ```sh
   cd ../rts_client_wasm
   wasm-pack build --target web
   ```

5. **Serve the client (static files):**
   ```sh
   basic-http-server .   # or python -m http.server
   ```

6. **Open the game in your browser:**  
   Go to `http://localhost:4000` (or your chosen port).

#### Shutting Down
- **Stop the server:**  
  Press `Ctrl+C` in the terminal running `cargo run`.
- **Stop the static file server:**  
  Press `Ctrl+C` in the terminal running `basic-http-server` or `python -m http.server`.
- **Stop PostgreSQL:**  
  Use your system's service manager or stop the Docker container.

#### Resetting the Project
- **Reset the database (dangerous, erases all data):**
   ```sh
   cd rts_server
   sqlx migrate revert --all
   sqlx migrate run
   ```
- **Remove build artifacts:**
   ```sh
   cargo clean
   cd ../rts_client_wasm
   wasm-pack clean
   ```

---

### 2. Production (Self-Hosted)

- **Deploy server on a cloud VM or container.**
- **Serve WASM client via NGINX or CDN.**
- Use SSL/TLS for WebSocket and API.
- Configure environment variables for DB, address, CORS, etc.

#### Steps:
- Build server and WASM client in release mode.
- Configure and run PostgreSQL.
- Serve static files (`rts_client_wasm/pkg`, `index.html`) with NGINX or similar.
- (Optional) Use Docker for the server and/or database.

#### Shutting Down
- Stop the server process (systemd, Docker, etc.).
- Stop the static file server.
- Stop the database service.

#### Resetting
- Drop and recreate the database, or use migration tools as above.

---

### 3. Docker Compose (Recommended for Integration Tests & Deployment)

- **Run everything in containers for easy setup and reproducibility.**
- Includes persistent storage for the database, environment variable configuration, and production-ready build steps.
- **Exposes server and client on random available ports so multiple instances can run and users can join from any device on the network.**

#### Example `docker-compose.yml`:

```yaml
version: '3.8'
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: rts_game
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 5s
      timeout: 5s
      retries: 5

  server:
    build:
      context: ./rts_server
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgres://user:password@db/rts_game
      SERVER_ADDR: 0.0.0.0:8080
      # Add other environment variables as needed
    depends_on:
      db:
        condition: service_healthy
    # Expose on a random available host port
    ports:
      - "0:8080"
    restart: unless-stopped

  client:
    image: halverneus/static-file-server
    volumes:
      - ./rts_client_wasm/pkg:/web
      - ./rts_client_wasm/index.html:/web/index.html
    # Expose on a random available host port
    ports:
      - "0:80"
    restart: unless-stopped

volumes:
  db_data:
```

#### Build and Run

1. **Build WASM client locally (recommended for dev):**
   ```sh
   cd rts_client_wasm
   wasm-pack build --release --target web
   cd ..
   ```

2. **Set your host IP environment variable for WebSocket connections:**
   - On Linux/macOS:
     ```sh
     export HOST_IP=$(hostname -I | awk '{print $1}')
     ```
   - On Windows (PowerShell):
     ```powershell
     $env:HOST_IP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
     # Or WiFi:
     $env:HOST_IP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi).IPAddress
     ```

3. **Build and start all services:**
   ```sh
   docker-compose up --build -d
   ```

4. **Find the mapped ports:**
   ```sh
   docker-compose ps
   ```
   or for just the client:
   ```sh
   docker-compose port client 80
   ```
   and for the server:
   ```sh
   docker-compose port server 8080
   ```
   The output will show the random host ports, e.g. `0.0.0.0:49154->80/tcp`.

5. **Find your host IP address (for others on your network):**
   - On Linux/macOS: `hostname -I` or `ip addr`
   - On Windows: `ipconfig`
   - Use the IP of your main network interface.

6. **Access the game from any device on your network:**
   - Open a browser and go to `http://<host-ip>:<client-port>`
   - The server API/WebSocket will be at `http://<host-ip>:<server-port>`

7. **Apply database migrations (from host):**
   ```sh
   docker-compose exec server sqlx migrate run
   ```

#### Shutting Down
- Run:
  ```sh
  docker-compose down
  ```

#### Resetting
- Remove all containers, volumes, and networks:
  ```sh
  docker-compose down -v
  ```
- This will erase all database data.

#### Tips

- For production, set strong passwords and use secrets for environment variables.
- Use a reverse proxy (NGINX, Traefik) for SSL/TLS and routing.
- You can add a Dockerfile to `rts_client_wasm` for fully containerized builds.
- **To see the mapped ports at any time, run:**
  ```sh
  docker-compose ps
  ```
  or
  ```sh
  docker-compose port client 80
  docker-compose port server 8080
  ```
- **To allow anyone on your network to join, share your host IP and the mapped client port.**
- **For WebSocket connections to work properly:**
  ```
  Set the HOST_IP environment variable to your machine's LAN IP address
  before running docker-compose up. This ensures browsers can connect to
  your WebSocket server.
  ```

---

### 4. Cloud (Heroku, Fly.io, AWS, etc.)

- **Deploy server and DB using provider's native services.**
- **Serve Web client via static site hosting (S3, Vercel, Netlify, etc.).**
- Use environment variables for secrets/config.
- Ensure CORS is set appropriately on the server.

#### Shutting Down
- Use your provider's dashboard or CLI to stop services.

#### Resetting
- Drop/recreate the database using provider tools.

---

### 5. Desktop Client (Planned)

- **Build a native desktop client using egui, winit, or a game engine.**
- Connects to the same WebSocket API as the browser client.

---

## Notes

- **WebSocket endpoint:** `/ws` (e.g. `ws://127.0.0.1:8080/ws`)
- **REST API:** `/api/register`, `/api/login`
- **Database:** PostgreSQL (see `rts_server/.env` and migrations)
- **Authentication:** Token-based (JWT planned, currently dummy tokens)

---

## Requirements

- Rust (1.70+ recommended)
- wasm-pack (`cargo install wasm-pack`)
- PostgreSQL
- Node.js (optional, for some dev tools)
- Docker & Docker Compose (for containerized deployment)

---

## License

MIT

---
