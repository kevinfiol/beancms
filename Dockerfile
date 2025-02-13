FROM alpine:3 AS builder
WORKDIR /app

COPY src/ src/
COPY Makefile .

# download deps
RUN apk add --update zip make curl
RUN mkdir vendor && make download

# build
RUN mkdir bin && make build
RUN chmod +x ./bin/redbean.com

FROM scratch
WORKDIR /app

COPY --from=builder /app/bin/redbean.com /app/redbean.com
VOLUME ["/data", "/redbean.log"]
CMD ["/app/redbean.com", "-vv", "-p", "80", "-L", "redbean.log"]

