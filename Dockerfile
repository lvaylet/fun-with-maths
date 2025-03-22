# --- Stage 1: Build the application ---
FROM rust:1.82 AS builder

# Set the working directory inside the builder image.
WORKDIR /app

# Copy and build the dependencies.
COPY Cargo.toml Cargo.lock ./
# `cargo fetch` requires a dummy app.
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo fetch --locked
RUN cargo build --locked

# Build the application in release mode (optimized).
COPY src src/
RUN cargo build --release --locked

# --- Stage 2: Create a lean runtime image ---
FROM gcr.io/distroless/cc-debian12 AS runner

# Set the working directory in the runtime image.
WORKDIR /app

# Copy the built binary from the builder stage
COPY --from=builder /app/target/release/fun-with-maths .

# Expose the port your web server listens on.
EXPOSE 3030

# Run the application.
CMD ["./fun-with-maths"]
