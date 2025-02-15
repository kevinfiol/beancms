# constants
PORT=8081
HOST=localhost

# vendor
REDBEAN=vendor/redbean.com
ASSIMILATE=vendor/assimilate

# build
BUILD=bin/redbean.com
DATA_DIR=bin/data
PID_FILE=bin/redbean.pid
LOG_FILE=bin/redbean.log

.PHONY: download run clean stop logs watch docker-build docker-run

# download dependencies
download:
	curl -o ${REDBEAN} https://redbean.dev/redbean-3.0.0.com && chmod +x ${REDBEAN}
	curl -o ${ASSIMILATE} https://cosmo.zip/pub/cosmos/bin/assimilate && chmod +x ${ASSIMILATE}

build:
	cp -f ${REDBEAN} ${BUILD}
	cd src/ && zip -r ../${BUILD} `ls -A`

run: build
	${BUILD} -vv -p ${PORT} -l ${HOST} -D ./bin/

start: build
	@(test ! -f ./bin/redbean.pid && \
		REDBEAN_MODE=dev ${BUILD} -vv -d -L ${LOG_FILE} -P ${PID_FILE} -p ${PORT} -l ${HOST} -D ./bin/ \
	|| echo "Redbean is already running at $$(cat ${PID_FILE})")

stop:
	@(test -f ${PID_FILE} && \
		kill -TERM $$(cat ${PID_FILE}) && \
		rm ${PID_FILE} \
	|| true)

restart: stop build start

watch:
	make stop
	make start && \
	trap 'make stop' EXIT INT TERM && \
	watchexec -p -w src make restart

logs:
	tail -f ${LOG_FILE}

clean:
	rm -f ${REDBEAN}
	rm -f ${BUILD}
	rm -f ${LOG_FILE}
	rm -f ${PID_FILE}
	rm -rf ${DATA_DIR}

docker-build:
	docker build --tag=beancms .

docker-run:
	docker run --detach \
		--name=beancms \
		--publish ${PORT}:80 \
		--restart unless-stopped \
		--mount type=bind,source=./${DATA_DIR},target=/app/data/ \
		--mount type=bind,source=./${LOG_FILE},target=/app/redbean.log \
		beancms

docker-stop:
	docker stop beancms && docker rm beancms