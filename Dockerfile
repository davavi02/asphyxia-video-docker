FROM ubuntu

RUN apt-get update && apt-get install -y \
    unzip wget gosu\
    && rm -rf /var/lib/apt/lists/*

ENV PUID=1000
ENV PGID=1000

WORKDIR /opt/asphyxia-server

COPY start.sh .
EXPOSE 8083 5057 4399
RUN chmod +x start.sh
CMD ["./start.sh"]