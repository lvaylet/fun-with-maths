# Use a Rust base image
FROM rust:1.75-slim as builder

# Set the working directory
WORKDIR /app

# Copy Cargo files
COPY Cargo.toml Cargo.lock ./

# Download dependencies
RUN cargo fetch

# Copy source files
COPY src ./src

# Build the application (release mode)
RUN cargo build --release

# Use a smaller runtime image
FROM debian:bullseye-slim

# Copy the built binary
COPY --from=builder /app/target/release/fun-with-maths /app/fun-with-maths

# Expose the port your application listens on
EXPOSE 3030

# Run the application
CMD ["/app/fun-with-maths"]
