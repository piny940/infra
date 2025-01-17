ARG GO_VERSION=1.23.5
FROM golang:${GO_VERSION} AS build
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o main /app/main.go

FROM alpine:latest AS final

WORKDIR /app

# 依存関係への参照: https://blog.kozakana.net/2019/09/go-binary-not-found/
RUN mkdir /lib64 \
  && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

COPY --from=build /app/main .

CMD [ "/app/main" ]
