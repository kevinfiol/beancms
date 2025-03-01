FROM alpine:3 AS builder
WORKDIR /app

COPY src/ src/
COPY Makefile .

# download deps
RUN apk add --update zip make curl
RUN mkdir vendor && make download

# build
RUN mkdir bin && make build
RUN chmod +x ./bin/beancms.com

# assimilate executable into local format
RUN sh ./vendor/assimilate ./bin/beancms.com

FROM scratch
WORKDIR /app

COPY --from=builder /app/bin/beancms.com /app/beancms.com
VOLUME ["/app/data", "/app/redbean.log"]
ENTRYPOINT ["/app/beancms.com", "-vv", "-p", "80", "-L", "/app/redbean.log", "-D", "./"]
