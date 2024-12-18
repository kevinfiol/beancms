# constants
PORT=8081
HOST=127.0.0.1

# vendor
REDBEAN=vendor/redbean.com
ZIP=vendor/zip.com
UNZIP=vendor/unzip.com

# build
BUILD=bin/redbean.com
PID_FILE=bin/redbean.pid
LOG_FILE=bin/redbean.log

.PHONY: download run clean stop

# download all dependencies
download:
	curl -o ${REDBEAN} https://redbean.dev/redbean-3.0.0.com && chmod +x ${REDBEAN}
	curl -o ${ZIP} https://redbean.dev/zip.com && chmod +x ${ZIP}
	curl -o ${UNZIP} https://redbean.dev/unzip.com && chmod +x ${UNZIP}

add:
	cp -f ${REDBEAN} ${BUILD}
	cd src/ && ../${ZIP} -r ../${BUILD} `ls -A`

run: add
	${BUILD} -vv -p ${PORT} -l ${HOST}

start: add
	@(test ! -f ./bin/redbean.pid && \
		${BUILD} -vv -d -L ${LOG_FILE} -P ${PID_FILE} -p ${PORT} -l ${HOST} \
	|| echo "Redbean is already running at $$(cat ${PID_FILE})")

stop:
	@(test -f ${PID_FILE} && \
		kill -TERM $$(cat ${PID_FILE}) && \
		rm ${PID_FILE} \
	|| true)

restart: stop add start

watch:
	make stop
	make start && \
	trap 'make stop' EXIT INT TERM && \
	watchexec -p -w src make restart

clean:
	rm ${REDBEAN}
	rm ${ZIP}
	rm ${UNZIP}
	rm ${BUILD}
	rm ${LOG_FILE}
	rm ${PID_FILE}