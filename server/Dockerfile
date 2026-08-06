# Build
FROM golang:1.25 AS build

WORKDIR /app

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server ./src
 
# Runtime
FROM alpine:latest

WORKDIR /app

COPY --from=build /app/server .

EXPOSE 8081
CMD ["./server"]
