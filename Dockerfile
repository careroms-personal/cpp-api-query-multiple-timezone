FROM gcc:13-bookworm AS builder

WORKDIR /app
COPY . .

RUN chmod +x build.sh && sh build.sh

FROM debian:bookworm-slim

WORKDIR /app
COPY --from=builder /app/server /app/server

EXPOSE 3333
CMD ["./server"]