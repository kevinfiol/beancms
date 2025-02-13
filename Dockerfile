FROM alpine:3 as builder
WORKDIR /app

COPY src/ src/
COPY Makefile .

RUN apk add --update zip
RUN mkdir bin && make build
RUN chmod +x ./bin/redbean.com

FROM scratch
WORKDIR /app

COPY --from=builder ./bin/redbean.com /
VOLUME ["/img", "/cms.sqlite", "/redbean.log"]
CMD ["/redbean.com", "-vv", "-p", "80", "-L", "redbean.log"]

