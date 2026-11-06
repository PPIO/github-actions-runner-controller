FROM golang:1.27.3-bookworm AS build
ARG VERSION=dev
ARG GOPROXY=https://proxy.golang.org,direct
WORKDIR /src
COPY go.mod go.sum ./
RUN GOPROXY="${GOPROXY}" go mod download
COPY cmd ./cmd
COPY internal ./internal
RUN CGO_ENABLED=0 go build -trimpath \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/controller ./cmd/ppio-actions-controller

FROM python:3.12.12-slim-bookworm
ARG VERSION=dev
LABEL org.opencontainers.image.source="https://github.com/ppio/github-actions-runner-controller" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.title="PPIO GitHub Actions Controller"
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY --from=build /out/controller /usr/local/bin/ppio-actions-controller
COPY provisioner ./provisioner
USER 65532:65532
EXPOSE 8080
CMD ["/usr/local/bin/ppio-actions-controller"]
