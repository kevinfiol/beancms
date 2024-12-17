REDBEAN=./vendor/redbean.com

.PHONY: download run clean

# download all dependencies
download:
	${REDBEAN} -i scripts.lua --get-deps

add:
	cp -f ${REDBEAN} bin/redbean.com
	cd src/ && ../vendor/zip.com -r ../bin/redbean.com `ls -A`

run: add
	./bin/redbean.com -vv -p 8080 -l 127.0.0.1

start:
	./bin/redbean.com -vv -d -L ./bin/app.log -P ./bin/app.pid -p 8080 -l 127.0.0.1

stop:
	kill -HUP $$(cat ./bin/app.pid)

clean:
	rm vendor/redbean.com
	rm vendor/unzip.com
	rm vendor/zip.com


# 	@(test ! -f ${PROJECT}.pid && \
# 		./${REDBEAN} -vv -d -L ${PROJECT}.log -P ${PROJECT}.pid && \
# 		printf "started $$(cat ${PROJECT}.pid)\n") \
# 		|| echo "already running $$(cat ${PROJECT}.pid)"


# 		@(test ! -f ${PROJECT}.pid && \
# 		./${REDBEAN} -vv -d -L ${PROJECT}.log -P ${PROJECT}.pid && \
# 		printf "started $$(cat ${PROJECT}.pid)") \
# 		|| kill -HUP $$(cat ${PROJECT}.pid) && \
# 		printf "restarted $$(cat ${PROJECT}.pid)\n"