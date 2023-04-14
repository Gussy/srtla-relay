# SRTLA-Relay

## Building

```bash
docker build -t srt-relay .
```

## Running

```bash
docker run srt-relay
```

## Usage

Exposed Ports

| Port | Usage |
| ---- | ----- |
| 5000 | **Ingress** - Traffic from `srtla_send` should be directed here. |
| 5001 | **Egress** - OBS or Restreamer should pull the stream from here. |
