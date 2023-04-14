#!/bin/bash

# Start the egress SRT transmitter
./srt-live-transmit -st:yes "srt://127.0.0.1:5002?mode=listener&lossmaxttl=40&latency=2000" "srt://0.0.0.0:5001?mode=listener" 1> ./srt-output.log 2> ./srt-error.log &

# Wait for srt-live-transmit to start up
sleep 1

# Start the ingress SRTLA receiver
./srtla_rec 5000 127.0.0.1 5002