# SRTLA Builder
FROM alpine:latest as srtla_builder

RUN apk update &&\
    apk upgrade &&\ 
    apk add --no-cache alpine-sdk

WORKDIR /srtla
COPY ./srtla/*.c .
COPY ./srtla/*.h .
COPY ./srtla/Makefile .

RUN make

# SLS Builder
FROM alpine:latest as sls_builder
# RUN apt-get update \
#     && apt-get upgrade \
#     && apt-get install -y tclsh pkg-config cmake libssl-dev build-essential git-core zlib1g-dev \
#     && rm -rf /var/lib/apt/lists/*

RUN apk update &&\
    apk upgrade &&\ 
    apk add --no-cache linux-headers alpine-sdk cmake tcl openssl-dev zlib-dev

WORKDIR /tmp
COPY ./sls /tmp/srt-live-server/
RUN git clone https://github.com/Haivision/srt.git
WORKDIR /tmp/srt
RUN git checkout v1.4.3 && ./configure && make -j8 && make install
WORKDIR /tmp/srt-live-server
RUN make -j8

# Final container
FROM alpine:latest

RUN apk update &&\
    apk upgrade &&\ 
    apk add --no-cache supervisor tzdata supervisor
# ENV TZ=Etc/UTC
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Supervisord
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# SRTLA
COPY --from=srtla_builder /srtla/srtla_rec /usr/local/bin/srtla_rec

# SLS
COPY --from=sls_builder /usr/local/bin/srt-* /usr/local/bin/
COPY --from=sls_builder /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=sls_builder /tmp/srt-live-server/bin/* /usr/local/bin/
COPY sls.conf /etc/sls/sls.conf

COPY logprefix /usr/local/bin/

EXPOSE 5000/udp
EXPOSE 8181/tcp
EXPOSE 8282/udp

WORKDIR /

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]