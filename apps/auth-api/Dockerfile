# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Download dependencies first (Docker layer caching: only re-runs if go.mod changes)
COPY go.mod go.sum* ./
RUN go mod download

# Copy source and build a statically-linked binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o auth-api .

# ── Stage 2: Run ─────────────────────────────────────────────────────────────
# Use distroless — no shell, no package manager = minimal attack surface
FROM gcr.io/distroless/static-debian12

WORKDIR /app
COPY --from=builder /app/auth-api .

# Non-root user (distroless default UID 65532)
USER 65532:65532

EXPOSE 8081

ENTRYPOINT ["/app/auth-api"]
