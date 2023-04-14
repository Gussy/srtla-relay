# Builder
FROM debian:stable-slim as builder

# Dependancies
RUN set -xe; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y \
    build-essential ca-certificates cmake git libssl-dev libz-dev tcl

# Belabox patched SRT
RUN git clone https://github.com/Gussy/srt.git /tmp/srt
WORKDIR /tmp/srt
RUN ./configure --prefix=/usr/local
RUN make -j8
RUN make install
RUN ldconfig

# SRTLA
RUN git clone https://github.com/Gussy/srtla.git /tmp/srtla
WORKDIR /tmp/srtla
RUN make -j8

# SRT-live-server (SLS)
RUN git clone https://github.com/Gussy/srt-live-server.git /tmp/srt-live-server
WORKDIR /tmp/srt-live-server
RUN LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH make -j8 

# Final container
FROM debian:stable-slim

RUN set -xe; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y --no-install-recommends \
    ca-certificates supervisor htop

# Binaries and libraries
COPY --from=builder /usr/local/bin/srt-* /usr/local/bin/
COPY --from=builder /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=builder /tmp/srtla/srtla_rec /usr/local/bin/srtla_rec
COPY --from=builder /tmp/srt-live-server/bin/* /usr/local/bin/

# Files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY sls.conf /etc/sls/sls.conf
COPY logprefix /usr/local/bin/

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime
RUN ldconfig
RUN chmod 755 /usr/local/bin/logprefix

EXPOSE 5000/udp
EXPOSE 8181/tcp
EXPOSE 8282/udp

WORKDIR /

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]