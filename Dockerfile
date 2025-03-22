# --- Stage 1: Build the application ---
FROM rust:1.82 AS builder

# Install the toolchain.
RUN rustup toolchain install stable

# Set the working directory inside the builder image.
WORKDIR /app

COPY . ./

# Build the dependencies.
RUN cargo fetch --locked
RUN cargo build --locked

# Build the application in release mode (optimized).
RUN cargo build --release --locked

# --- Stage 2: Create a lean runtime image ---
FROM debian:bullseye-slim AS runner

# Set the working directory in the runtime image.
WORKDIR /app

# Install minimal dependencies. If you need more, update this line.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the built binary from the builder stage
COPY --from=builder /app/target/release/fun-with-maths /app/fun-with-maths

# Expose the port your web server listens on.
EXPOSE 3030

# Run the application.
CMD ["/app/fun-with-maths"]
