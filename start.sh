#!/bin/bash

groupmod -o -g "${PUID:-1000}" ubuntu 2>/dev/null || true
usermod -o -u ${PUID:-1000} -g ${PGID:-1000} ubuntu 2>/dev/null || true
cd /opt/asphyxia-server

setup_server() {
mkdir -p /opt/asphyxia-server/Server &&\
cd /opt/asphyxia-server/Server &&\
wget -O Server.zip https://github.com/asphyxia-core/core/releases/download/v1.60b/asphyxia-core-linux-x64.zip &&\
unzip Server.zip &&\
rm Server.zip
touch set1
cd /opt/asphyxia-server

}

setup_record() {
mkdir -p /opt/asphyxia-server/Record &&\
cd /opt/asphyxia-server/Record &&\
wget -O Record.tar.gz https://github.com/bookqaq/010-record-api/releases/download/v1.1.0-2026042200/010-record-api-v1.1.0-2026042200-linux-amd64.tar.gz &&\
tar -xvzf Record.tar.gz &&\
rm Record.tar.gz &&\
timeout 5s ./010-record-api &&\
touch set2
cd /opt/asphyxia-server
}

cd /opt/asphyxia-server/Server
if [ ! -f "set1" ]; then
    echo "Setting up Asphyxia"
    setup_server
fi
cd /opt/asphyxia-server/Record
if [ ! -f "set2" ]; then
    echo "Setting up 010-record-api"
    setup_record
fi

echo "Fixing permissions"
cd /opt/asphyxia-server
chown -R "${PUID:-1000}:${PGID:-1000}" ./Server
chown -R "${PUID:-1000}:${PGID:-1000}" ./Record
exec gosu ubuntu bash -c '
    echo "Starting Asphyxia"
    cd /opt/asphyxia-server/Server
    ./asphyxia-core &
    pid1=$!

    echo "Starting 010-record-api"
    cd /opt/asphyxia-server/Record
    ./010-record-api &
    pid2=$!

    stop() {
        echo "Stopping"
        kill -TERM $pid1 $pid2 2>/dev/null
        wait $pid1 $pid2
        exit 0
    }
    trap stop SIGTERM SIGINT

    wait -n $pid1 $pid2
    exit_code=$?
    kill $pid1 $pid2 2>/dev/null
    exit $exit_code
'