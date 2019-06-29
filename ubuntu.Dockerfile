FROM	nexus166/gobld as gown
RUN	CGO_ENABLED=0 go get -v -u -ldflags="-s -w" github.com/nexus166/gown

FROM	ubuntu:_TAG_

SHELL	["/bin/bash", "-xeuo", "pipefail", "-c"]

RUN	export DEBIAN_FRONTEND=noninteractive; \
	apt-get update; \
	apt-get dist-upgrade -y; \
	apt-get install -y --no-install-recommends \
		apt-transport-https ca-certificates curl gnupg2; \
	curl -fsSLo- https://www.mongodb.org/static/pgp/server-4.0.asc | apt-key add -; \
	eval $(< /etc/os-release); \
	_os="$(printf '%s' ${ID} | tr '[[:upper:]]' '[[:lower:]]')"; \
	_version="$(printf '%s' "${VERSION}" | awk -F'[()]' '{print tolower($2)}' | cut -d' ' -f1)"; \
	printf 'deb http://repo.mongodb.org/apt/%s %s/mongodb-org/4.0 multiverse\n' "${_os}" "${_version}" | tee -a /etc/apt/sources.list.d/mongo.list; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		mongodb-org-server mongodb-org-shell; \
	apt-get remove --purge --autoremove -y \
		apt-transport-https curl gnupg2; \
	apt-get clean; \
	apt-get autoclean; \
	rm -fr /root/.cache /tmp/* /var/lib/apt/*; \
	sed -i "s/^#  engine:/  engine: mmapv1/" /etc/mongod.conf; \
	sed -i "s/^#replication:/replication:\n replSetName: rs01/" /etc/mongod.conf

WORKDIR	/home/mongodb

COPY	--from=gown /opt/go/bin/gown /opt/gown
RUN	chown -vR mongodb:mongodb /opt; \
	chown -v 0:0 /opt/gown; \
	chmod -v 4755 /opt/gown

RUN	printf '#!/usr/bin/env bash\n(sleep 5 && /usr/bin/mongo --eval "printjson(rs.initiate())") &\n${@}\n' | tee /usr/local/bin/entrypoint.sh; \
	chmod -v 755 /usr/local/bin/entrypoint.sh

RUN	printf '#!/usr/bin/env bash\nset -x\n/opt/gown /home/mongodb /opt/gown\nrm /opt/gown\n/usr/bin/mongod --dbpath /home/mongodb --smallfiles --oplogSize 128 --replSet rs01 --bind_ip 0.0.0.0\n' | tee /usr/local/bin/mongod.sh; \
	chmod -v 755 /usr/local/bin/mongod.sh

USER	mongodb

EXPOSE	27017 28017

ENTRYPOINT ["entrypoint.sh"]
CMD	["mongod.sh"]
