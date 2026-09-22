FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        lua5.3 \
        liblua5.3-dev \
        libpcre2-dev \
        libssl-dev \
        libpam0g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN git clone --depth 1 https://github.com/lefcha/imapfilter.git /tmp/imapfilter

WORKDIR /tmp/imapfilter
ENV CPPFLAGS="-I/usr/include/lua5.3"
RUN make LIBLUA=-llua5.3 -j"$(nproc)" \
    && make LIBLUA=-llua5.3 install

RUN mkdir -p /etc/imapfilter /var/lib/imapfilter \
    && chmod 755 /usr/local/bin/imapfilter

COPY entrypoint.sh /usr/local/bin/imapfilter-entrypoint.sh
RUN chmod +x /usr/local/bin/imapfilter-entrypoint.sh

WORKDIR /etc/imapfilter

ENTRYPOINT ["/usr/local/bin/imapfilter-entrypoint.sh"]
CMD ["loop"]
