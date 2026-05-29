# FRONTEND
FROM node:22-alpine as client 
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /tmp
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm run build


# BACKEND
FROM rust:1.85-alpine as backend
WORKDIR /tmp

# ADDED: ca-certificates to populate the empty Alpine trust store for Cargo
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk add --no-cache libc-dev openssl-dev alpine-sdk ca-certificates

COPY fortinet.crt /tmp/fortinet.crt

ENV CARGO_HTTP_CAINFO=/tmp/fortinet.crt
ENV SSL_CERT_FILE=/tmp/fortinet.crt



COPY ./packages/backend ./
RUN RUSTFLAGS="-Ctarget-feature=-crt-static" cargo build --release


# RUNNER
FROM alpine:3.19
WORKDIR /app

# ADDED: ca-certificates here as well, so your final app can make outgoing HTTPS requests if needed
RUN sed -i 's/https/http/g' /etc/apk/repositories && \
    apk add --no-cache curl libgcc ca-certificates

COPY --from=backend /tmp/target/release/cryptgeon .
COPY --from=client /tmp/packages/frontend/build ./frontend
ENV FRONTEND_PATH="./frontend"
ENV REDIS="redis://redis/"
EXPOSE 8000
ENTRYPOINT [ "/app/cryptgeon" ]
