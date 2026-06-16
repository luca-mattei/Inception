FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

COPY tools/init-nginx.sh /usr/local/bin/init-nginx.sh
RUN chmod +x /usr/local/bin/init-nginx.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/init-nginx.sh"]
