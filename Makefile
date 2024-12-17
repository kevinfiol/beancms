PORT=8081
HOST=127.0.0.1

REDBEAN=vendor/redbean.com
BUILD=bin/redbean.com

.PHONY: download run clean stop

# download all dependencies
download:
	curl -o ${REDBEAN} https://redbean.dev/redbean-3.0.0.com && chmod +x ${REDBEAN}
	${REDBEAN} -i scripts.lua --get-deps

add:
	cp -f ${REDBEAN} ${BUILD}
	cd src/ && ../vendor/zip.com -r ../${BUILD} `ls -A`

run: add
	${BUILD} -vv -p ${PORT} -l ${HOST}

start: add
	${REDBEAN} -i scripts.lua --start

# 	@(test ! -f ./bin/redbean.pid && \
# 		${BUILD} -vv -d -L ./bin/redbean.log -P ./bin/redbean.pid -p 8080 -l 127.0.0.1 \
# 	|| echo "Redbean is already running at $$(cat ./bin/redbean.pid)")

stop:
	@(test -f ./bin/redbean.pid && \
		kill -TERM $$(cat ./bin/redbean.pid) && \
		rm ./bin/redbean.pid \
	|| true)

restart: stop add start

watch:
	make stop
	make start && \
	trap 'make stop' EXIT INT TERM && \
	watchexec -p -w src make restart

clean:
	rm ${REDBEAN}
	rm ./vendor/unzip.com
	rm ./vendor/zip.com