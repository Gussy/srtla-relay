# SRT Builder (for srt-live-transmit)
FROM debian:buster-slim as srt_builder

SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get -y --no-install-recommends install \
    build-essential \
    tclsh \
    pkg-config \
    cmake \
    libssl-dev

WORKDIR /srt
ADD ./srt .
RUN ./configure && make

# SRTLA Builder
FROM debian:buster-slim as srtla_builder

SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get -y --no-install-recommends install \
    build-essential

WORKDIR /srtla
COPY ./srtla/*.c .
COPY ./srtla/*.h .
COPY ./srtla/Makefile .

RUN make

FROM debian:buster-slim
ARG APP=/app

RUN apt-get update \
    && apt-get install -y ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 5000/udp
EXPOSE 5001/udp

ENV TZ=Etc/UTC \
    APP_USER=appuser

RUN groupadd $APP_USER \
    && useradd -g $APP_USER $APP_USER \
    && mkdir -p ${APP}

COPY --from=srt_builder /srt/srt-live-transmit ${APP}/srt-live-transmit
COPY --from=srtla_builder /srtla/srtla_rec ${APP}/srtla_rec

COPY run.sh ${APP}
RUN chmod +x ${APP}/run.sh

RUN chown -R $APP_USER:$APP_USER ${APP}

USER $APP_USER

WORKDIR ${APP}

ENTRYPOINT ["/app/run.sh"]
